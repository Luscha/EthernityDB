pragma solidity ^0.4.11;

library DocumentKeyTreeFlat {
  struct DocumentKeyRoot {
    DocumentKeyNode[] nodes;
    uint32 current;
    uint32 last;
  }

  struct DocumentKeyNode {
    KeyIndexMap[] values;
    KeyIndexMap[] children;
    uint32 lastValue;
    uint32 lastChild;
    uint32 parent;
  }

  struct KeyIndexMap {
    bytes8 key;
    uint32 value;
  }

  function newRoot() internal returns (DocumentKeyRoot memory root) {
      root = DocumentKeyRoot({
        nodes: new DocumentKeyNode[](32),
        current: 0,
        last: 0});
  }

  function resize(DocumentKeyRoot root) internal {
    if (root.last >= root.nodes.length -1) {
      uint8 newLen = uint8(root.nodes.length) + 16;
      DocumentKeyNode[] memory newNodes = new DocumentKeyNode[](newLen);
      for (uint8 i = 0; i < root.nodes.length; i++) {
          newNodes[i] = root.nodes[i];
      }
      root.nodes = newNodes;
    }
  }

  function resize(DocumentKeyNode node) internal {
    uint8 newLen = 0;
    uint8 i = 0;
    if (node.lastValue >= node.values.length -1) {
      newLen = uint8(node.values.length) + 16;
      KeyIndexMap[] memory newValues = new KeyIndexMap[](newLen);
      for (i = 0; i < node.values.length; i++) {
          newValues[i] = node.values[i];
      }
      node.values = newValues;
    }
    if (node.lastChild >= node.children.length -1) {
      newLen = uint8(node.children.length) + 16;
      KeyIndexMap[] memory newChildren = new KeyIndexMap[](newLen);
      for (i = 0; i < node.children.length; i++) {
          newChildren[i] = node.values[i];
      }
      node.children = newChildren;
    }
  }

  function addChild(DocumentKeyRoot root, bytes8 nodeName) internal {
    resize(root);
    DocumentKeyNode memory node = root.nodes[++root.last];
    DocumentKeyNode memory current = root.nodes[root.current];
    resize(current);
    current.children[current.lastChild++] = KeyIndexMap(nodeName, root.last);
    node.parent = root.current;
    root.current = root.last;
  }

  function upToParent(DocumentKeyRoot root) internal {
    root.current = root.nodes[root.current].parent;
  }

  function setKeyIndex(DocumentKeyRoot root, bytes8 k, uint32 i) internal {
    DocumentKeyNode memory current = root.nodes[root.current];
    resize(current);
    current.values[current.lastValue++] = KeyIndexMap(k, i);
  }

  function selectRoot(DocumentKeyRoot root) internal {
    root.current = 0;
  }

  function selectKey(DocumentKeyRoot root, bytes8 k) internal returns (bool, uint32) {
    DocumentKeyNode memory current = root.nodes[root.current];
    for (uint32 i = 0; i < current.lastValue; i++) {
      if (current.values[i].key == k) {
        return (true, current.values[i].value);
      }
    }
    return (false, 0);
  }

  function selectChild(DocumentKeyRoot root, bytes8 k) internal returns (bool) {
    DocumentKeyNode memory current = root.nodes[root.current];
    for (uint32 i = 0; i < current.lastChild; i++) {
      if (current.children[i].key == k) {
        root.current = current.children[i].value;
        return true;
      }
    }
    return false;
  }
}
