pragma solidity ^0.4.11;

import "bson/documentparser.sol";
import "lib/treeflat.sol";

contract QueryEngine {

  using DocumentParser for byte[];
  using TreeFlat for TreeFlat.TreeRoot;
  using TreeFlat for TreeFlat.TreeIterator;

  function processQuery(byte[] query, byte[] data) returns (bool) {
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
}
