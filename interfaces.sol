pragma solidity ^0.4.11;

contract DriverAbstract {
  mapping (address => mapping (bytes32 => DBAbstract)) public databasesByName;

  function registerDatabase(address owner, string strName, DBAbstract db);
  function getDatabase(address owner, string strName) constant returns (DBAbstract);

  function parseDocumentData(byte[] data, DBAbstract db, bytes32 c, bytes12 d);

  function getUniqueID(byte[] seed) constant returns (bytes12);
}

contract DBAbstract {
  struct Collection {
    mapping (bytes12 => DocumentAbstract) documentByID;
    bytes12[] documentIDArray;
    string name;
    uint64 count;
    bool init;
  }

  mapping (bytes32 => Collection) public collectionsByName;

  DriverAbstract internal driver;
  address public owner;
  string public name;
  bool public isPrivate;

  function changeDriver(DriverAbstract newDriver);
  function getDriver() constant returns (DriverAbstract);

  function newCollection(string strName);
  function getCollection(string strName) constant internal returns (Collection storage);

  function newDocument(string collection, bytes12 _id, byte[] data) internal returns (DocumentAbstract d);

  function addEmbeededDocumentNode(bytes32 c, bytes12 d, bytes32 nodeName);
  function setParentDocumentNode(bytes32 c, bytes12 d);

  function setKeyIndex(bytes32 c, bytes12 d, bytes32 key, uint64 index);
  function setKeyType(bytes32 c, bytes12 d, bytes32 key, uint8 _type);

  function queryInsert(string collection, byte[] data) returns (bytes12 id);
  //function queryFind(string collection, byte[] query) constant;
}

contract DocumentAbstract {
  byte[] internal data;
  bytes12 public id;

  function getData() constant returns (byte[]);
}
