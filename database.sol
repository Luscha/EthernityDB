pragma solidity ^0.4.11;
import "interfaces.sol";
import "collection.sol";

contract Database is DBAbstract {
  function Database(string strName, bool bPrivate, DriverAbstract _driver) {
    owner = tx.origin;
    name = strName;
    isPrivate = bPrivate;
    driver = _driver;
  }

  function newCollection(string strName) returns (CollectionAbstract c) {
    if (address(getCollection(strName)) != 0x0) throw;
    if (true == isPrivate && tx.origin != owner) throw;

    c = new Collection(strName, this);
    collectionsByName[driver.stringToBytes32(strName)] = c;
  }

  function getCollection(string strName) constant returns (CollectionAbstract) {
    return collectionsByName[driver.stringToBytes32(strName)];
  }

  function queryInsert(string collection, byte[] data) returns (bytes12 id) {
    if (address(getCollection(collection)) == 0x0) throw;

    CollectionAbstract c = collectionsByName[driver.stringToBytes32(collection)];
    id = driver.getUniqueID(data);
    DocumentAbstract d = c.newDocument(id, data);
    driver.parseDocumentData(data, d, c);
  }

  function queryFind(string collection, byte[] query) constant {
    if (address(getCollection(collection)) == 0x0) throw;
  }
}
