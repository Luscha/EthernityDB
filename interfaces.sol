pragma solidity ^0.4.11;

interface DriverAbstract {
  function registerDatabase(address owner, string strName, DBAbstract db);
  function getDatabase(address owner, string strName) constant returns (DBAbstract);

  function processInsertion(byte[] query, bool verbose, bool generateID) constant returns (bytes12, bytes21);
  function processQuery(byte[] query, bytes doc) constant returns (bool);
}

interface DBAbstract {
  function changeDriver(DriverAbstract newDriver);
  function getDriver() constant returns (DriverAbstract);

  function getName() constant returns (string);
  function getOwner() constant returns (address);

  function migrateDatabase(DBAbstract to);
  function receiveMigratingCollection(CollectionAbstract c, bytes8 name);

  function newCollection(string strName);
  function getCollection(string strName) constant returns (CollectionAbstract);

  function getDocument(string collection, uint64 index) constant returns (bytes12, bytes);

  function queryInsert(string collection, byte[] data, bytes12 preID) returns (bytes12);
  function queryFind(string collection, uint64 index, byte[] query) constant returns (bytes12, int64, bytes);
}

interface CollectionAbstract {
  function changeDB(DBAbstract db);
  function getDocumentCount() constant returns (uint64);
  function getName() constant returns (string);

  function getDocumentByteAt(bytes12 id, uint64 i) constant returns (byte);
  function getDocumentIDbyIndex(uint64 i) constant returns (bytes12);
  function getDocumentLengthbyIndex(uint64 i) constant returns (uint32);

  function insertDocument(bytes12 id, byte[] data);
}
