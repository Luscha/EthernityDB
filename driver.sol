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
import "queryengine.sol";
import "interfaces.sol";

contract Driver is DriverAbstract {
  using StringUtils for string;
  using BytesUtils for byte[];

  bytes5 constant idKeyName = 0x075F696400;
  QueryEngine queryEngine;

  function Driver (QueryEngine qe) {
    queryEngine = qe;
  }

  function registerDatabase(address owner, string strName, DBAbstract db) {
    if (address(getDatabase(owner, strName)) != 0x0) throw;
    databasesByName[msg.sender][strName.toBytes32()] = db;
  }

  function getDatabase(address owner, string strName) constant returns (DBAbstract) {
    return databasesByName[owner][strName.toBytes32()];
  }

  function processInsertion(byte[] data) constant returns (bytes12 id, bytes21 head) {
    if (false == queryEngine.checkDocumentValidity(data, idKeyName)) throw;
    (id, head) = getDocumentHead(data);
  }

  function processQuery(byte[] query, DocumentAbstract doc) constant returns (bool) {
    byte[] memory data = new byte[](doc.length());
    for (uint32 i = 0; i < doc.length(); i++) {
      data[i] = doc.data(i);
    }
    return queryEngine.processQuery(query, data);
  }

  function checkDocumentValidity(byte[] data) internal constant returns (bool) {
    // If the length is less or equal 5 the document is empty.
    if (data.length <= 5) {
      return false;
    }

    /*TreeFlat.TreeRoot memory treeRoot = data.getDocumentTree();
    // For now we let only up to 8 nested document level
    if (treeRoot.maxDeep > 8) {
      return false;
    }*/

    /*
      // check type validity
      if (bType > 0x12 || (bType >= 0x05  && bType <= 0x07) ||
          bType == 0x09  || (bType >= 0x0B  && bType <= 0x0F))
          return false;
    }*/
    return true;
  }

  function getUniqueID(byte[] seed) internal constant returns (bytes12 id) {
    // 4 bit timestamp
    // 3 bit blockSha3
    // 2 bit hash(seed, msg.sender)
    // 3 bit random
    bytes32 blockSha3 = sha3(block.blockhash(block.number - 1), msg.sender);
    bytes32 seedSha3 = sha3(seed, msg.sender);
    bytes32 randomHash = sha3(blockSha3, seed);

    for (uint8 i = 0; i < 4; i++) {
      id |= bytes4(bytes4(uint32(block.timestamp))[3 - i]) >> (i * 8);
    }
    id |= bytes12(blockSha3) & 0x00000000FFFFFF0000000000;
    id |= bytes12(seedSha3) & 0x00000000000000FFFF000000;
    id |= bytes12(randomHash) & 0x000000000000000000FFFFFF;
  }

  function getDocumentHead(byte[] data) constant returns (bytes12 id, bytes21 head) {
    id = getUniqueID(data);
    bytes4 len = bytes4(int32(data.getLittleUint32(0)) + 17);

    for (uint8 i = 0; i < 4; i++) {
      head |= bytes4(bytes4(len)[3 - i]) >> (i * 8);
    }
    head |= bytes21(idKeyName) >> (4 * 8);
    head |= bytes21(id) >> (9 * 8);
  }
}
