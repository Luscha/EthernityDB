pragma solidity ^0.4.11;

contract DriverAbstract {
  mapping (address => mapping (bytes32 => DBAbstract)) public databasesByName;

  function newDatabase(string strName, bool bPrivate) returns (DBAbstract);
  function getDatabase(address owner, string strName) constant returns (DBAbstract);

  function parseDocumentData(byte[] data, DocumentAbstract doc, CollectionAbstract col);

  function getUniqueID() constant returns (uint256 id);
  function stringToBytes32(string input) constant returns (bytes32);
  function bytes32ArrayToString(bytes32[] data) constant returns (string);
}

contract DBAbstract {
  mapping (bytes32 => CollectionAbstract) public collectionsByName;

  DriverAbstract internal driver;
  address public owner;
  string public name;
  bool public isPrivate;

  function newCollection(string strName) returns (CollectionAbstract);
  function getCollection(string strName) constant returns (CollectionAbstract);

  function queryInsert(string collection, byte[] data) returns (uint256 id);
  function queryFind(string collection, byte[] query) constant;
}

contract CollectionAbstract {
  mapping (uint256 => DocumentAbstract) public documentByID;
  DocumentAbstract[] public documentArray;

  DBAbstract internal db;
  string public name;
  uint64 public count;

  function newDocument(uint256 _id, byte[] data) returns (DocumentAbstract);
  function newEmbeedDocument(DocumentAbstract doc, string key, byte[] data, uint64 len) returns (DocumentAbstract);
}

contract DocumentAbstract {
  mapping (string => uint64)  internal keyIndex;
  mapping (string => uint8)   internal keyType;
  mapping (string => DocumentAbstract)  internal embeedDocument;

  CollectionAbstract internal collection;
  byte[] public data;
  uint256 public dataLen;
  uint256 public id;

  function setKeyIndex(string key, uint64 index);
  function setKeyType(string key, uint8 _type);

  function getKeyIndex(string key) constant returns (uint64);
  function getKeyType(string key) constant returns (uint8);

  function setEmbeededDocument(string key, DocumentAbstract doc);
  function getEmbeededDocument(string key) returns (DocumentAbstract);
}
