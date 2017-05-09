pragma solidity ^0.4.11;

contract DriverAbstract {
  mapping (address => mapping (bytes32 => DBAbstract)) public databasesByName;

  function registerDatabase(address owner, string strName, DBAbstract db);
  function getDatabase(address owner, string strName) constant returns (DBAbstract);

  function parseDocumentData(byte[] data, DocumentAbstract doc);

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
  struct DocumentKeyNode {
    uint8 nodeID;
    mapping (bytes32 => uint64)  keyIndex;
    mapping (bytes32 => uint8)   keyType;
    mapping (bytes32 => DocumentKeyNode)  embeedDocument;
  }

  mapping (uint8 => DocumentKeyNode)  parentDocumentKeyNode;
  mapping (uint8 => DocumentKeyNode)  documentKeyNodeByID;

  CollectionAbstract internal collection;
  DocumentKeyNode internal rootNode;
  DocumentKeyNode internal currentNode;

  byte[] internal data;
  bytes12 public id;
  uint8 internal currentKeyNode;

  function getData() constant returns (byte[]);

  function addEmbeededDocumentNode(bytes32 nodeName);
  function setParentDocumentNode();

  function setKeyIndex(bytes32 key, uint64 index);
  function setKeyType(bytes32 key, uint8 _type);

  //function getKeyIndex(bytes32 key) constant returns (uint64);
  //function getKeyType(bytes32 key) constant returns (uint8);
  //function getEmbeededDocumentNode(bytes32 key) returns (DocumentKeyTreeAbstract);
}
