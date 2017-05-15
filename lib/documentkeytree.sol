pragma solidity ^0.4.11;

library DocumentKeyTree {
  struct DocumentKeyRoot {
    mapping (bytes32 => uint64)  keyIndex;
    mapping (bytes32 => DocumentKeyNode)  children;
    DocumentKeyNode currentNode;
    bool isCurrent;
  }

  struct DocumentKeyNode {
    mapping (bytes32 => uint64)  keyIndex;
    mapping (bytes32 => DocumentKeyNode)  children;
    mapping (bool => DocumentKeyNode)  parent;
    bool isInit;
  }

  function newRoot() internal returns (DocumentKeyRoot memory root) {
      root = DocumentKeyRoot({currentNode: DocumentKeyNode({isInit: false}), isCurrent: true});
  }

  function addChild(DocumentKeyRoot storage root, bytes32 nodeName) internal {
    if (root.isCurrent == true) {
        root.children[nodeName] = DocumentKeyNode({isInit: true});
        root.isCurrent = false;
        root.currentNode.children[nodeName] = root.children[nodeName];
    } else {
        root.currentNode.children[nodeName] = DocumentKeyNode({isInit: true});
        root.currentNode.children[nodeName].parent[true] = root.currentNode;
        root.currentNode = root.currentNode.children[nodeName];
    }
  }

  function upToParent(DocumentKeyRoot storage root) internal {
    if (root.isCurrent == true) {
        return;
    } else if (root.currentNode.parent[true].isInit = false) {
        root.isCurrent = true;
    } else {
        root.currentNode = root.currentNode.parent[true];
    }
  }

  function setKeyIndex(DocumentKeyRoot storage root, bytes32 k, uint64 i) internal {
    if (root.isCurrent == true) {
      root.keyIndex[k] = i;
    } else {
      root.currentNode.keyIndex[k] = i;
    }
  }

  function selectRoot(DocumentKeyRoot storage root) internal {
    root.isCurrent = true;
  }

  function selectKey(DocumentKeyRoot storage root, bytes32 k) internal returns (bool, uint64) {
    if (root.isCurrent == true) {
        if (root.keyIndex[k] == 0) {
          return (false, 0);
        } else {
          return (true, root.keyIndex[k]);
        }
    } else {
      if (root.currentNode.keyIndex[k] == 0) {
        return (false, 0);
      } else {
        return (true, root.currentNode.keyIndex[k]);
      }
    }
  }

  function selectChildren(DocumentKeyRoot storage root, bytes32 k) internal returns (bool) {
    if (root.isCurrent == true) {
        if (root.children[k].isInit == false) {
          return false;
        } else {
          root.currentNode = root.children[k];
          return true;
        }
    } else {
      if (root.currentNode.children[k].isInit == false) {
        return false;
      } else {
        root.currentNode = root.currentNode.children[k];
        return true;
      }
    }
  }
}
