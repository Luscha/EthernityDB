pragma solidity ^0.4.11;
import {DocumentAbstract, CollectionAbstract} from "interfaces.sol";

contract Document is DocumentAbstract {
  // For the future it might be better to use an array of bytes32
  // that maps the structure of the data using the single bits
  // Es:
  // bytes32 keyMap = 00001100000011000000110000011
  //  Where the 1s are the bytes where the key are
  function Document(bytes12 _id, byte[] _data, CollectionAbstract _c) {
    id = _id;
    collection = _c;
    currentNode = rootNode;

    for (uint64 i = 0; i < _data.length; i++) {
      data.push(_data[i]);
    }
  }

  function getData() constant returns (byte[]) {
    return data;
  }

  function addEmbeededDocumentNode(bytes32 nodeName) {
    if (msg.sender != address(collection.getDB().getDriver())) throw;
    DocumentKeyNode newNode = documentKeyNodeByID[currentKeyNode++];
    newNode.nodeID = currentKeyNode;
    currentNode.embeedDocument[nodeName] = newNode;
    parentDocumentKeyNode[currentKeyNode] = currentNode;
    currentNode = newNode;
  }

  function setParentDocumentNode() {
    if (msg.sender != address(collection.getDB().getDriver())) throw;
    currentNode = parentDocumentKeyNode[currentNode.nodeID];
  }

  function setKeyIndex(bytes32 key, uint64 index) {
    if (msg.sender != address(collection.getDB().getDriver())) throw;
    currentNode.keyIndex[key] = index;
  }

  function setKeyType(bytes32 key, uint8 _type) {
    if (msg.sender != address(collection.getDB().getDriver())) throw;
    currentNode.keyType[key] = _type;
  }
}
