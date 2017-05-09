pragma solidity ^0.4.11;

contract DriverAbstract {
  mapping (address => mapping (bytes32 => DBAbstract)) public databasesByName;

  function registerDatabase(address owner, string strName, DBAbstract db);
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

  function changeDriver(DriverAbstract newDriver);
  function getDriver() constant returns (DriverAbstract);

  function newCollection(string strName) returns (CollectionAbstract);
  function getCollection(string strName) constant returns (CollectionAbstract);

  function queryInsert(string collection, byte[] data) returns (bytes12 id);
  function queryFind(string collection, byte[] query) constant;
}

contract CollectionAbstract {
  mapping (bytes12 => DocumentAbstract) public documentByID;
  bytes12[] public documentIDArray;

  DBAbstract internal db;
  string public name;
  uint64 public count;

  function getDB() constant returns (DBAbstract);
  function newDocument(bytes12 _id, byte[] data) returns (DocumentAbstract);
}

contract DocumentAbstract {
  DocumentKeyTreeAbstract internal keyTree;

  CollectionAbstract internal collection;
  byte[] internal data;
  bytes12 public id;

  function getData() constant returns (byte[]);

  function getKeyTree() constant returns (DocumentKeyTreeAbstract);
  function addTreeNode(bytes32 nodeName, DocumentKeyTreeAbstract tree) returns (DocumentKeyTreeAbstract);
}

contract DocumentKeyTreeAbstract {
  mapping (bytes32 => uint64)  internal keyIndex;
  mapping (bytes32 => uint8)   internal keyType;
  mapping (bytes32 => DocumentKeyTreeAbstract)  internal embeedDocument;
  DocumentKeyTreeAbstract internal parentDocument;

  function setParentocumentTree(DocumentKeyTreeAbstract parent);
  function getParentocumentTree() constant returns (DocumentKeyTreeAbstract);

  function setKeyIndex(bytes32 key, uint64 index);
  function setKeyType(bytes32 key, uint8 _type);

  function getKeyIndex(bytes32 key) constant returns (uint64);
  function getKeyType(bytes32 key) constant returns (uint8);

  function setEmbeededDocumentTree(bytes32 key, DocumentKeyTreeAbstract doc);
  function getEmbeededDocumentTree(bytes32 key) returns (DocumentKeyTreeAbstract);
}
