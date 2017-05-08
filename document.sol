pragma solidity ^0.4.11;
import "interfaces.sol";

contract Document is DocumentAbstract {
  function Document(bytes12 _id, byte[] _data, uint64 len, CollectionAbstract _c) {
    id = _id;
    dataLen = len;
    collection = _c;

    for (uint64 i = 0; i < len; i++) {
      data.push(_data[i]);
    }
  }

  function setKeyIndex(string key, uint64 index) {
    keyIndex[key] = index;
  }

  function setKeyType(string key, uint8 _type) {
    keyType[key] = _type;
  }

  function getKeyIndex(string key) constant returns (uint64) {
    return keyIndex[key];
  }

  function getKeyType(string key) constant returns (uint8) {
    return keyType[key];
  }

  function setEmbeededDocument(string key, DocumentAbstract doc) {
    embeedDocument[key] = doc;
  }

  function getEmbeededDocument(string key) returns (DocumentAbstract) {
    return embeedDocument[key];
  }
}
