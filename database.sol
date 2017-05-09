pragma solidity ^0.4.11;
import "lib/stringUtils.sol";
import "interfaces.sol";
import "document.sol";

contract Database is DBAbstract {
  using StringUtils for string;

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

    collectionsByName[strName.toBytes32()].init = true;
    collectionsByName[strName.toBytes32()].name = strName;
  }

  function getCollection(string strName) constant internal returns (Collection storage) {
    return collectionsByName[strName.toBytes32()];
  }

  ////////////////////////////////////////////
  /// Document Related
  function newDocument(string collection, bytes12 _id, byte[] data) internal returns (DocumentAbstract d) {
    Collection c = getCollection(collection);
    if (c.init == false) throw;
    if (address(c.documentByID[_id]) != 0x0) throw;
    if (true == isPrivate && msg.sender != owner) throw;

    d = new Document(_id, data);
    c.documentByID[_id] = d;
    c.documentIDArray.push(_id);
    c.count++;
  }

  ////////////////////////////////////////////
  /// Query Related
  function queryInsert(string collection, byte[] data) returns (bytes12 id) {
    if (getCollection(collection).init == false) throw;

    id = driver.getUniqueID(data);
    DocumentAbstract d = newDocument(collection, id, data);
    driver.parseDocumentData(data, d);
  }

  /*function queryFind(string collection, byte[] query) constant {
    if (address(getCollection(collection)) == 0x0) throw;
  }*/
}
