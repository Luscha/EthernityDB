pragma solidity ^0.4.11;

library DocumentTree {
  struct TreeRoot {
    mapping (bytes32 => uint64)  keyIndex;
    mapping (bytes32 => TreeNode)  children;
    TreeNode currentNode;
    bool isCurrent;
  }

  struct TreeNode {
    mapping (bytes32 => uint64)  keyIndex;
    mapping (bytes32 => TreeNode)  children;
    mapping (bool => TreeNode)  parent;
    bool isInit;
  }

  function newRoot() internal returns (TreeRoot memory root) {
      root = TreeRoot({currentNode: TreeNode({isInit: false}), isCurrent: true});
  }

  function addChild(TreeRoot storage root, bytes32 nodeName) internal {
    if (root.isCurrent == true) {
        root.children[nodeName] = TreeNode({isInit: true});
        root.isCurrent = false;
        root.currentNode.children[nodeName] = root.children[nodeName];
    } else {
        root.currentNode.children[nodeName] = TreeNode({isInit: true});
        root.currentNode.children[nodeName].parent[true] = root.currentNode;
        root.currentNode = root.currentNode.children[nodeName];
    }
  }

  function upToParent(TreeRoot storage root) internal {
    if (root.isCurrent == true) {
        return;
    } else if (root.currentNode.parent[true].isInit = false) {
        root.isCurrent = true;
    } else {
        root.currentNode = root.currentNode.parent[true];
    }
  }

  function setKeyIndex(TreeRoot storage root, bytes32 k, uint64 i) internal {
    if (root.isCurrent == true) {
      root.keyIndex[k] = i;
    } else {
      root.currentNode.keyIndex[k] = i;
    }
  }

  function selectRoot(TreeRoot storage root) internal {
    root.isCurrent = true;
  }

  function selectKey(TreeRoot storage root, bytes32 k) internal returns (bool, uint64) {
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

  function selectChildren(TreeRoot storage root, bytes32 k) internal returns (bool) {
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
