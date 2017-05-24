pragma solidity ^0.4.11;
import "lib/stringUtils.sol";
import "interfaces.sol";
import "document.sol";

contract Database is DBAbstract {
  using StringUtils for string;

  modifier OnlyDriver {
      if (msg.sender != address(driver)) throw;
        _;
  }

  function Database(string strName, bool bPrivate, DriverAbstract _driver) {
    owner = msg.sender;
    name = strName;
    isPrivate = bPrivate;
    driver = _driver;
    driver.registerDatabase(owner, strName, this);
  }

  ////////////////////////////////////////////
  /// Driver Related
  function changeDriver(DriverAbstract newDriver) {
    if (msg.sender != owner) throw;
    driver = newDriver;
    driver.registerDatabase(owner, name, this);
  }

  function getDriver() constant returns (DriverAbstract) {
    return driver;
  }

  ////////////////////////////////////////////
  /// Collection Related
  function newCollection(string strName) {
    if (getCollection(strName).init != false) throw;
    if (true == isPrivate && msg.sender != owner) throw;

    collectionsByName[bytes8(strName.toBytes32())].init = true;
    collectionsByName[bytes8(strName.toBytes32())].name = strName;
  }

  function getCollection(string strName) constant internal returns (Collection storage) {
    return collectionsByName[bytes8(strName.toBytes32())];
  }

  function getCollectionMetadata(string strName) constant returns (bytes32 name, uint64 count) {
    if (getCollection(strName).init == false) throw;
    name = strName.toBytes32();
    count = getCollection(strName).count;
  }

  ////////////////////////////////////////////
  /// Document Related
  function getDocument(string collection, uint64 index) constant returns (bytes12 id) {
    if (getCollection(collection).init == false) throw;
    if (getCollection(collection).count <= index) throw;
    id = getCollection(collection).documentIDArray[index];
  }

  ////////////////////////////////////////////
  /// Query Related
  function queryInsert(string collection, byte[] data) returns (DocumentAbstract d) {
    if (true == isPrivate && msg.sender != owner) throw;
    if (getCollection(collection).init == false) throw;

    bytes12 id;
    bytes21 head;
    (id, head) = driver.processInsertion(data);
    if (address(documentByID[id]) != 0x0) throw;

    d = new Document(data, head);
    getCollection(collection).documentIDArray.push(id);
    getCollection(collection).count++;
    documentByID[id] = d;
  }

  function queryFind(string collection, uint64 index, byte[] query) constant returns (bytes12, uint64) {
    Collection c = getCollection(collection);
    if (c.init == false) throw;
    for (index; index < c.count; index++) {
      DocumentAbstract doc = documentByID[c.documentIDArray[index]];
      if (true == driver.processQuery(query, doc)) {
        return (c.documentIDArray[index], index);
      }
    }
    return (bytes12(0), 0);
  }
}
