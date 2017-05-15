pragma solidity ^0.4.11;

/*
//////////////////////////////////////////////////////////////////////////////
////////////// Insertion Query Example
//////////////////////////////////////////////////////////////////////////////
Bson converter (external) converts a Json in a Bson
  -> from { item: "journal", qty: 25, size: { h: 14, w: 21, uom: "cm" }, rate: 2.3 }
  -> to Binary Bson Data bData
    -> Check that the Bson contains only "allowed data types" (see grammar)
  -> database.queryInsert(collectionName, bData)
  -> Insertion in a new entry with parsing for useful information

//////////////////////////////////////////////////////////////////////////////
////////////// Select Query Example
//////////////////////////////////////////////////////////////////////////////
Allowed operation: = (later <, <=, >, >=, !=)
Follow MongoDB query grammar passing a single Json to the contract that contains
all the clauses.
The only operation on the embeed document and array is the equality, that returns every
document which contains the embeed document provided (not strictly equal):
  -> select({ size: { h: 14 } })
    -> returns the document used in the insert example

  -> select * where qty = 25 or size.h = 15
    -> select("\n6F": [ { qty: 25 }, { size: { h: 25 } } ])

  -> select * where qty = 25 or size.h >= 15
    -> select("\n6F": [ { qty: 25 }, { size: { h: { "\n6D": 25 } } ])
*/
import "lib/stringUtils.sol";
import "lib/bytesUtils.sol";
import "lib/documentkeytreeflat.sol";
import "bsonparser/documentparser.sol";
import "interfaces.sol";

contract Driver is DriverAbstract {
  using StringUtils for string;
  using DocumentParser for byte[];
  using BytesUtils for byte[];
  using DocumentKeyTreeFlat for DocumentKeyTreeFlat.DocumentKeyRoot;

  bytes5 constant idKeyName = 0x075F696400;

  function registerDatabase(address owner, string strName, DBAbstract db) {
    if (address(getDatabase(owner, strName)) != 0x0) throw;
    databasesByName[msg.sender][strName.toBytes32()] = db;
  }

  function getDatabase(address owner, string strName) constant returns (DBAbstract) {
    return databasesByName[owner][strName.toBytes32()];
  }

  function parseDocumentData(DocumentAbstract doc, DocumentKeyTreeFlat.DocumentKeyRoot memory tree) internal {
    byte[] memory data = new byte[](doc.length());
    for (uint32 i = 0; i < doc.length(); i++) {
      data[i] = doc.data(i);
    }
    int8 documentIndex = -1;
    // For now we let only up to 8 nested document level
    uint32[] memory embeedDocumentStack = new uint32[](8);
    // Skip first 4 BYTE (int32 = Doc length)
    for (i = 4; i < data.length - 1; i++) {
        // Select parent nodeTree if available
        if (documentIndex >= 0 && embeedDocumentStack[uint8(documentIndex)] <= i) {
          tree.upToParent();
          documentIndex--;
        }

        uint8 bType = 0;
        bytes8 b32Name = 0;
        uint32 nDataLen = 0;
        uint32 nDataStart = 0;
        (bType, b32Name, nDataLen, nDataStart) = data.nextKeyValue(i);

        if (bType == 0x0) {
          continue;
        }

        tree.setKeyIndex(b32Name, uint32(i + nDataStart));

        if (bType == 0x03 || bType == 0x04) {
          if (documentIndex > 7) throw;
          tree.addChild(b32Name);
          embeedDocumentStack[uint8(++documentIndex)] = i + nDataLen - 1;
          i += nDataStart - 1;
        } else {
          i += nDataLen - 1;
        }
    }
  }

  function processInsertion(byte[] data) returns (bytes12 id, bytes21 head) {
    if (false == checkDocumentValidity(data)) throw;
    (id, head) = getDocumentHead(data);
  }

  function processQuery(byte[] query, DocumentAbstract doc) returns (bool ret) {
    DocumentKeyTreeFlat.DocumentKeyRoot memory keyTreeRoot = DocumentKeyTreeFlat.newRoot();
    parseDocumentData(doc, keyTreeRoot);
  }

  function checkDocumentValidity(byte[] data) internal constant returns (bool) {
    int8 documentIndex = -1;
    // For now we let only up to 8 nested document level
    uint32[] memory embeedDocumentStack = new uint32[](8);
    for (uint32 i = 4; i < data.length - 1; i++) {
      if (documentIndex >= 0 && embeedDocumentStack[uint8(documentIndex)] <= i) {
        documentIndex--;
      }

      uint8 bType = 0;
      bytes8 b32Name = 0;
      uint32 nDataLen = 0;
      uint32 nDataStart = 0;
      (bType, b32Name, nDataLen, nDataStart) = data.nextKeyValue(i);

      if (bType == 0x0) {
        continue;
      }

      // check type validity
      if (bType > 0x12 || (bType >= 0x05  && bType <= 0x07) ||
          bType == 0x09  || (bType >= 0x0B  && bType <= 0x0F))
          return false;

      if (bType == 0x03 || bType == 0x04) {
        if (documentIndex > 7) {
          return false;
        }
        embeedDocumentStack[uint8(++documentIndex)] = i + nDataLen - 1;
        i += nDataStart - 1;
      } else {
        i += nDataLen - 1;
      }
    }
    return true;
  }

  function getUniqueID(byte[] seed) internal constant returns (bytes12 id) {
    // 4 bit blockSha3
    // 3 bit hash(seed, msg.sender)
    // 2 bit timestamp
    // 3 bit random
    bytes32 blockSha3 = sha3(block.blockhash(block.number - 1), msg.sender);
    bytes32 seedSha3 = sha3(seed, msg.sender);
    bytes32 timeSha3 = sha3(block.timestamp, msg.sender);
    bytes32 randomHash = sha3(sha3(blockSha3, timeSha3), seed);

    for (uint8 j = 0; j < 12; j++) {
      if (j < 4) {
        id |= bytes12(blockSha3[j]) >> (j * 8);
      } else if (j < 7) {
        id |= bytes12(seedSha3[j]) >> (j * 8);
      } else if (j < 9) {
        id |= bytes12(timeSha3[j]) >> (j * 8);
      } else {
        uint8 index = uint8(uint256(randomHash) % 32);
        id |= bytes12(randomHash[index]) >> (j * 8);
        randomHash = sha3(randomHash, seedSha3);
      }
    }
  }

  function getDocumentHead(byte[] data) internal constant returns (bytes12 id, bytes21 head){
    id = getUniqueID(data);
    bytes4 len = bytes4(int32(data.getLittleUint32(0)) + 17);
    for (uint8 i; i < 21; i++) {
      if (i < 4) {
        head |= bytes21(len[3 - i]) >> (i * 8);
      } else if (i < 9) {
        head |= bytes21(idKeyName[i - 4]) >> (i * 8);
      } else {
        head |= bytes21(id[i - 9]) >> (i * 8);
      }
    }
  }
}
