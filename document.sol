pragma solidity ^0.4.11;
import "interfaces.sol";
import "lib/stringUtils.sol";

contract Document is DocumentAbstract {
  using StringUtils for string;

  function Document(bytes12 _id, byte[] _data, uint64 len, CollectionAbstract _c) {
    id = _id;
    dataLen = len;
    collection = _c;
    keyTree = new DocumentTree();

    for (uint64 i = 0; i < len; i++) {
      data.push(_data[i]);
    }
  }

  function getKeyTree() constant returns (DocumentKeyTreeAbstract) {
    return keyTree;
  }

  function addTreeNode(bytes32 nodeName, DocumentKeyTreeAbstract tree) returns (DocumentKeyTreeAbstract) {
    DocumentTree newNode = new DocumentTree();
    tree.setEmbeededDocumentTree(nodeName, newNode);
    return newNode;
  }
}

contract DocumentTree is DocumentKeyTreeAbstract {
  using StringUtils for string;

  function setKeyIndex(bytes32 key, uint64 index) {
    keyIndex[key] = index;
  }

  function setKeyType(bytes32 key, uint8 _type) {
    keyType[key] = _type;
  }

  function getKeyIndex(string key) constant returns (uint64) {
    return keyIndex[key.toBytes32()];
  }

  function getKeyType(string key) constant returns (uint8) {
    return keyType[key.toBytes32()];
  }

  function setEmbeededDocumentTree(bytes32 key, DocumentKeyTreeAbstract doc) {
    embeedDocument[key] = doc;
  }

  function getEmbeededDocumentTree(string key) returns (DocumentKeyTreeAbstract) {
    return embeedDocument[key.toBytes32()];
  }
}
