pragma solidity ^0.4.11;

library DocumentKeyTree {
  struct DocumentKeyRoot {
    mapping (bytes32 => uint64)  keyIndex;
    mapping (bytes32 => uint8)   keyType;
    mapping (bytes32 => DocumentKeyNode)  children;
    DocumentKeyNode currentNode;
    bool isCurrent;
  }

  struct DocumentKeyNode {
    mapping (bytes32 => uint64)  keyIndex;
    mapping (bytes32 => uint8)   keyType;
    mapping (bytes32 => DocumentKeyNode)  children;
    mapping (bool => DocumentKeyNode)  parent;
    bool isInit;
  }

  function newRoot() internal returns (DocumentKeyRoot root) {
      root = DocumentKeyRoot({currentNode: DocumentKeyNode({isInit: false}), isCurrent: true});
  }

  function addChild(DocumentKeyRoot storage root, bytes32 nodeName) internal returns (DocumentKeyNode storage newNode) {
    if (root.isCurrent == true) {
        newNode = root.children[nodeName];
        root.isCurrent = false;
    } else {
        newNode = root.currentNode.children[nodeName];
        newNode.parent[true] = root.currentNode;
    }

    newNode.isInit = true;
    root.currentNode = newNode;
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
    root.currentNode.keyIndex[k] = i;
  }

  function setKeyType(DocumentKeyRoot storage root, bytes32 k, uint8 t) internal {
    root.currentNode.keyIndex[k] = t;
  }
}
