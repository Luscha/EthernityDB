pragma solidity ^0.4.11;

contract DriverAbstract {
  mapping (address => mapping (bytes32 => DBAbstract)) public databasesByName;

  function registerDatabase(address owner, string strName, DBAbstract db);
  function getDatabase(address owner, string strName) constant returns (DBAbstract);

  function processInsertion(byte[] query) constant returns (bytes12, bytes21);
  function processQuery(byte[] query, DocumentAbstract doc) constant returns (bool);
}

contract DBAbstract {
  struct Collection {
    bytes12[] documentIDArray;
    string name;
    uint64 count;
    bool init;
  }

  mapping (bytes8 => Collection) public collectionsByName;
  mapping (bytes12 => DocumentAbstract) public documentByID;

  DriverAbstract internal driver;
  address public owner;
  string public name;
  bool public isPrivate;

  function changeDriver(DriverAbstract newDriver);
  function getDriver() constant returns (DriverAbstract);

  function newCollection(string strName);
  function getCollectionMetadata(string strName) constant returns (bytes32, uint64);

  function getDocument(string collection, uint64 index) constant returns (bytes12);

  function queryInsert(string collection, byte[] data) returns (DocumentAbstract);
  function queryFind(string collection, uint64 index, byte[] query) constant returns (bytes12, uint64);
}

contract DocumentAbstract {
  byte[] public data;
  uint32 public length;
  function getData() constant returns (byte[]);
}
