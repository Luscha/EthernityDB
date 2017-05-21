pragma solidity ^0.4.11;

import "bson/documentparser.sol";
import "lib/treeflat.sol";

contract QueryEngine {

  using DocumentParser for byte[];
  using DocumentParser for bytes32;
  using TreeFlat for TreeFlat.TreeRoot;
  using TreeFlat for TreeFlat.TreeIterator;

  function processQuery(byte[] query, byte[] data) constant returns (bool) {
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

  function checkDocumentValidity(byte[] data, bytes5 idName) constant returns (bool) {
    // If the length is less or equal 5 the document is empty.
    if (data.length <= 5) {
      return false;
    }
    bytes32 idName32 = bytes32(idName);
    TreeFlat.TreeRoot memory treeDocument = data.getDocumentTree();
    // For now we let only up to 8 nested document level
    if (treeDocument.maxDeep > 8) {
      return false;
    }

    TreeFlat.TreeIterator memory it = treeDocument.begin();
    TreeFlat.TreeNode memory n = it.tree.nodes[0];

    for (;; (n = it.next())) {
      for (uint32 x = 0; x < n.lastValue; x++) {
        uint8 bType = uint8(n.values[x].key[0]);
        // check type validity
        if (bType > 0x12 || (bType >= 0x05  && bType <= 0x07) ||
            bType == 0x09  || (bType >= 0x0B  && bType <= 0x0F))
            return false;
        // chack idName
        if (n.deep == 0 && idName32.getCombinedNameType8(bType) == n.values[x].key)
          return false;
      }
      if (false == it.hasNext()) {
        break;
      }
    }

    return true;
  }
}
