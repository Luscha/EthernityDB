pragma solidity ^0.4.11;

library TreeFlat {
  struct TreeRoot {
    TreeNode[] nodes;
    uint32 current;
    uint32 last;
    uint8 maxDepth;
  }

  struct TreeNode {
    KeyIndexMap[] values;
    KeyIndexMap[] children;
    bytes8 name;
    uint32 lastValue;
    uint32 lastChild;
    uint32 parent;
    uint8 depth;
  }

  struct KeyIndexMap {
    bytes8 key;
    uint32 value;
  }

  struct TreeIterator {
    TreeRoot tree;
    uint32[] trace;
    uint32[] goal;
  }

  function newRoot() internal returns (TreeRoot memory root) {
      root = TreeRoot({
        nodes: new TreeNode[](16),
        current: 0,
        last: 0,
        maxDepth: 0});
    root.nodes[0] = newNode(0, 0, bytes8(0));
  }

  function newNode(uint32 p, uint8 d, bytes8 nodeName) internal returns (TreeNode memory node) {
      node = TreeNode({
        values: new KeyIndexMap[](16),
        children: new KeyIndexMap[](16),
        name: nodeName,
        lastValue: 0,
        lastChild: 0,
        parent: p,
        depth: d});
  }

  function resize(TreeRoot root) internal returns (TreeRoot) {
    if (root.last >= root.nodes.length -1) {
      uint8 newLen = uint8(root.nodes.length) + 16;
      TreeNode[] memory newNodes = new TreeNode[](newLen);
      for (uint8 i = 0; i < root.nodes.length; i++) {
          newNodes[i] = root.nodes[i];
      }
      root.nodes = newNodes;
    }
    return root;
  }

  function resize(TreeNode node) internal returns (TreeNode) {
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
    return node;
  }

  function addChild(TreeRoot root, bytes8 nodeName) internal returns (TreeRoot) {
    root = resize(root);
    root.last++;
    TreeNode memory current = root.nodes[root.current];
    current = resize(current);
    current.children[current.lastChild++] = KeyIndexMap(nodeName, root.last);
    TreeNode memory node = newNode(root.current, current.depth + 1, nodeName);
    root.nodes[root.current] = current;
    root.nodes[root.last] = node;
    root.current = root.last;
    if (root.maxDepth < node.depth) {
      root.maxDepth = node.depth;
    }
    return root;
  }

  function upToParent(TreeRoot root) internal returns (TreeRoot) {
    root.current = root.nodes[root.current].parent;
    return root;
  }

  function setKeyIndex(TreeRoot root, bytes8 k, uint32 i) internal returns (TreeRoot) {
    TreeNode memory current = root.nodes[root.current];
    current = resize(current);
    current.values[current.lastValue++] = KeyIndexMap(k, i);
    root.nodes[root.current] = current;
    return root;
  }

  function selectRoot(TreeRoot root) internal returns (TreeRoot) {
    root.current = 0;
    return root;
  }

  function getCurrentDepth(TreeRoot root) internal returns (uint32){
    return root.nodes[root.current].depth;
  }

  function selectKey(TreeRoot root, bytes8 k) internal returns (bool, uint32) {
    TreeNode memory current = root.nodes[root.current];
    for (uint32 i = 0; i < current.lastValue; i++) {
      if (current.values[i].key == k) {
        return (true, current.values[i].value);
      }
    }
    return (false, 0);
  }

  function selectChild(TreeRoot root, bytes8 k) internal returns (bool, TreeRoot) {
    TreeNode memory current = root.nodes[root.current];
    for (uint32 i = 0; i < current.lastChild; i++) {
      if (current.children[i].key == k) {
        root.current = current.children[i].value;
        return(true, root);
      }
    }
    return (false, root);
  }

  function begin(TreeRoot root) internal returns (TreeIterator memory it) {
    it = TreeIterator({
      tree: root,
      trace: new uint32[](root.last + 2),
      goal: new uint32[](root.last + 2)});

    it.tree = selectRoot(it.tree);
    it.tree = addChild(it.tree, 0);
    it.tree.nodes[it.tree.last].depth = 0xF;

    for (uint32 i = 0; i <= root.last; i++) {
      it.goal[i] = root.nodes[i].lastChild;
    }
    it.tree = selectRoot(it.tree);
  }

  function end(TreeIterator it) internal returns (TreeNode memory) {
    return it.tree.nodes[it.tree.last];
  }

  function next(TreeIterator it) internal returns (TreeIterator, TreeNode) {
    uint32 c = it.tree.current;
    if (c == 0 && it.trace[0] >= it.goal[0]) {
      return (it, end(it));
    }
    if (it.trace[c] >= it.goal[c]) {
      it.tree = upToParent(it.tree);
      return next(it);
    } else {
      TreeNode memory n = it.tree.nodes[c];
      (,it.tree) = selectChild(it.tree, n.children[it.trace[c]++].key);
      return (it, it.tree.nodes[it.tree.current]);
    }
  }
}
