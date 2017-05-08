pragma solidity ^0.4.11;
import "lib/stringUtils.sol";
import "interfaces.sol";
import "collection.sol";

contract Database is DBAbstract {
  using StringUtils for string;

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
    collectionsByName[strName.toBytes32()] = c;
  }

  function getCollection(string strName) constant returns (CollectionAbstract) {
    return collectionsByName[strName.toBytes32()];
  }

  function queryInsert(string collection, byte[] data) returns (bytes12 id) {
    if (address(getCollection(collection)) == 0x0) throw;

    CollectionAbstract c = collectionsByName[collection.toBytes32()];
    id = driver.getUniqueID(data);
    DocumentAbstract d = c.newDocument(id, data);
    driver.parseDocumentData(data, d.getKeyTree(), d);
  }

  function queryFind(string collection, byte[] query) constant {
    if (address(getCollection(collection)) == 0x0) throw;
  }
}
