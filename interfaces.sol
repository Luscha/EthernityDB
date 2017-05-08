pragma solidity ^0.4.11;

contract DriverAbstract {
  mapping (address => mapping (bytes32 => DBAbstract)) public databasesByName;

  function newDatabase(string strName, bool bPrivate) returns (DBAbstract);
  function getDatabase(address owner, string strName) constant returns (DBAbstract);

  function parseDocumentData(byte[] data, DocumentKeyTreeAbstract docTree, DocumentAbstract doc);

  function getUniqueID(byte[] seed) constant returns (bytes12);
}

contract DBAbstract {
  mapping (bytes32 => CollectionAbstract) public collectionsByName;

  DriverAbstract internal driver;
  address public owner;
  string public name;
  bool public isPrivate;

  function newCollection(string strName) returns (CollectionAbstract);
  function getCollection(string strName) constant returns (CollectionAbstract);

  function queryInsert(string collection, byte[] data) returns (bytes12 id);
  function queryFind(string collection, byte[] query) constant;
}

contract CollectionAbstract {
  mapping (bytes12 => DocumentAbstract) public documentByID;
  DocumentAbstract[] public documentArray;

  DBAbstract internal db;
  string public name;
  uint64 public count;

  function newDocument(bytes12 _id, byte[] data) returns (DocumentAbstract);
}

contract DocumentAbstract {
  DocumentKeyTreeAbstract internal keyTree;

  CollectionAbstract internal collection;
  byte[] public data;
  uint256 public dataLen;
  bytes12 public id;

  function getKeyTree() returns (DocumentKeyTreeAbstract);
  function addTreeNode(string nodeName, DocumentKeyTreeAbstract tree) returns (DocumentKeyTreeAbstract);
}

contract DocumentKeyTreeAbstract {
  mapping (string => uint64)  internal keyIndex;
  mapping (string => uint8)   internal keyType;
  mapping (string => DocumentKeyTreeAbstract)  internal embeedDocument;

  function setKeyIndex(string key, uint64 index);
  function setKeyType(string key, uint8 _type);

  function getKeyIndex(string key) constant returns (uint64);
  function getKeyType(string key) constant returns (uint8);

  function setEmbeededDocumentTree(string key, DocumentKeyTreeAbstract doc);
  function getEmbeededDocumentTree(string key) returns (DocumentKeyTreeAbstract);
}
