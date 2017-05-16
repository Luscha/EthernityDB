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
import "lib/treeflat.sol";
import "bson/documentparser.sol";
import "interfaces.sol";

contract Driver is DriverAbstract {
  using StringUtils for string;
  using DocumentParser for byte[];
  using BytesUtils for byte[];
  using TreeFlat for TreeFlat.TreeRoot;
  using TreeFlat for TreeFlat.TreeIterator;

  bytes5 constant idKeyName = 0x075F696400;

  function registerDatabase(address owner, string strName, DBAbstract db) {
    if (address(getDatabase(owner, strName)) != 0x0) throw;
    databasesByName[msg.sender][strName.toBytes32()] = db;
  }

  function getDatabase(address owner, string strName) constant returns (DBAbstract) {
    return databasesByName[owner][strName.toBytes32()];
  }

  function processInsertion(byte[] data) returns (bytes12 id, bytes21 head) {
    if (false == checkDocumentValidity(data)) throw;
    (id, head) = getDocumentHead(data);
  }

  function processQuery(byte[] query, DocumentAbstract doc) returns (bool) {
    byte[] memory data = new byte[](doc.length());
    for (uint32 i = 0; i < doc.length(); i++) {
      data[i] = doc.data(i);
    }
    TreeFlat.TreeRoot memory treeDoc = data.getDocumentTree();
    TreeFlat.TreeRoot memory treeQuery = query.getDocumentTree();
    treeDoc.selectRoot();
    TreeFlat.TreeIterator memory it = treeQuery.begin();
    TreeFlat.TreeNode memory n = it.tree.nodes[0];
    bool r = false;
    for (;; (n = it.next())) {
      if (n.deep != 0) {
        if (treeDoc.getCurrentDeep() >= treeQuery.getCurrentDeep()) {
          for (uint32 j = treeDoc.getCurrentDeep(); j >= treeQuery.getCurrentDeep(); j--) {
            treeDoc.upToParent();
          }
          if (false == treeDoc.selectChild(n.name)) {
            return false;
          }
        } else {
          if (false == treeDoc.selectChild(n.name)) {
            return false;
          }
        }
      }
      for (uint32 x = 0; x < n.lastValue; x++) {
        (r,) = treeDoc.selectKey(n.values[x].key);
        if (r != true) {
          return false;
        }
      }
      if (false == it.hasNext()) {
        break;
      }
    }
    return true;
  }

  function checkDocumentValidity(byte[] data) internal constant returns (bool) {
    // If the length is less or equal 5 the document is empty.
    if (data.length <= 5) {
      return false;
    }

    TreeFlat.TreeRoot memory treeRoot = data.getDocumentTree();
    // For now we let only up to 8 nested document level
    if (treeRoot.maxDeep > 8) {
      return false;
    }

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
    bytes32 timeSha3 = sha3(block.timestamp, msg.sender);
    bytes32 randomHash = sha3(sha3(blockSha3, timeSha3), seed);

    for (uint8 j = 0; j < 12; j++) {
      if (j < 4) {
        id |= bytes12(timeSha3[j]) >> (j * 8);
      } else if (j < 7) {
        id |= bytes12(blockSha3[j]) >> (j * 8);
      } else if (j < 9) {
        id |= bytes12(seedSha3[j]) >> (j * 8);
      } else {
        uint8 index = uint8(uint256(randomHash) % 32);
        id |= bytes12(randomHash[index]) >> (j * 8);
        randomHash = sha3(randomHash, seedSha3);
      }
    }
  }

  function getDocumentHead(byte[] data) internal constant returns (bytes12 id, bytes21 head) {
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
