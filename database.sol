pragma solidity ^0.4.11;
import "lib/stringUtils.sol";
import "lib/flag.sol";
import "interfaces.sol";
import "document.sol";

contract Database is DBAbstract {
  using StringUtils for string;
  using Flag for uint32;

  enum dbFlags {PRIVATE, VERBOSE}

  uint32 private flag;

  modifier OnlyDriver {
      if (msg.sender != address(driver)) throw;
        _;
  }

  function Database(string strName, bool bPrivate, bool bVerbose, DriverAbstract _driver) {
    owner = msg.sender;
    name = strName;

    if (bPrivate)
      flag.setBit(uint8(dbFlags.PRIVATE));
    if (bVerbose)
      flag.setBit(uint8(dbFlags.VERBOSE));

    driver = _driver;
    driver.registerDatabase(owner, strName, this);
  }

  function setVerbose(bool _flag) {
    if (msg.sender != owner) throw;
    if (true == _flag)
      flag.setBit(uint8(dbFlags.VERBOSE));
    else
      flag.removeBit(uint8(dbFlags.VERBOSE));
  }

  function setPrivate(bool _flag) {
    if (msg.sender != owner) throw;
    if (true == _flag)
      flag.setBit(uint8(dbFlags.PRIVATE));
    else
      flag.removeBit(uint8(dbFlags.PRIVATE));
  }

  function isVerbose() constant returns (bool) {
    return flag.isBit(uint8(dbFlags.VERBOSE));
  }

  function isPrivate() constant returns (bool) {
    return flag.isBit(uint8(dbFlags.PRIVATE));
  }
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
  /// Database Related
  function migrateDatabase(DBAbstract to) {
    if (tx.origin != owner) throw;
    uint64 i = 0;
    uint64 j = 0;
    for (i = 0; i < collectionCount; i++) {
      Collection c = collectionsByName[collectionsIDByIndex[i]];
      to.receiveMigratingCollection(c.name);
      for (j = 0; j < c.count; j++) {
        to.receiveMigratingDocument(c.name, c.documentIDArray[j], documentByID[c.documentIDArray[j]]);
      }
    }
  }

  function receiveMigratingCollection(string name) {
    if (tx.origin != owner) throw;
    newCollection(name);
  }

  function receiveMigratingDocument(string collection, bytes12 id, DocumentAbstract doc) {
    if (tx.origin != owner) throw;
    insertDocument(collection, id, doc);
  }

  ////////////////////////////////////////////
  /// Collection Related
  function newCollection(string strName) {
    if (getCollection(strName).init != false) throw;
    if (true == isPrivate() && msg.sender != owner) throw;

    collectionsByName[bytes8(strName.toBytes32())].init = true;
    collectionsByName[bytes8(strName.toBytes32())].name = strName;
    collectionsIDByIndex[collectionCount++] = bytes8(strName.toBytes32());
  }

  function getCollection(string strName) constant internal returns (Collection storage) {
    return collectionsByName[bytes8(strName.toBytes32())];
  }

  function getCollectionMetadata(string strName) constant returns (bytes8 name, uint64 count) {
    if (getCollection(strName).init == false) throw;
    name = bytes8(strName.toBytes32());
    count = getCollection(strName).count;
  }

  function insertDocument(string collection, bytes12 id, DocumentAbstract doc) private {
    getCollection(collection).documentIDArray.push(id);
    getCollection(collection).count++;
    documentByID[id] = doc;
  }

  ////////////////////////////////////////////
  /// Document Related
  function getDocument(string collection, uint64 index) constant returns (bytes12, bytes) {
    if (getCollection(collection).init == false) throw;
    if (getCollection(collection).count <= index) throw;
    bytes12 id = getCollection(collection).documentIDArray[index];
    DocumentAbstract doc = documentByID[id];
    bytes memory data = new bytes(doc.length());
    for (uint32 i = 0; i < doc.length(); i++) {
      data[i] = doc.data(i);
    }
    return (id, data);
  }

  ////////////////////////////////////////////
  /// Query Related
    if (getCollection(collection).init == false) throw;
  function queryInsert(string collection, byte[] data, bytes12 preID) {
    if (true == isPrivate() && msg.sender != owner) throw;

    bytes12 id;
    bytes21 head;
    if (address(documentByID[id]) != 0x0) throw;

    d = new Document(data, head);
    insertDocument(collection, id, d);
    (id, head) = driver.processInsertion(data, isVerbose(), preID == bytes12(0));
    if (preID == bytes21(0)) {
      getCollection(collection).insertDocument(id, head, data);
    }
    else {
      getCollection(collection).insertDocument(preID, bytes21(0), data);
    }
  }

  function queryFind(string collection, uint64 index, byte[] query) constant returns (bytes12, int64, bytes) {
    Collection c = getCollection(collection);
    DocumentAbstract doc;
    if (c.init == false) throw;
    for (index; index < c.count; index++) {
      doc = documentByID[c.documentIDArray[index]];
      if (true == driver.processQuery(query, doc)) {
        bytes memory data = new bytes(doc.length());
        for (uint32 i = 0; i < doc.length(); i++) {
          data[i] = doc.data(i);
        }
        return (c.documentIDArray[index], int64(index), data);
      }
    }
    return (bytes12(0), -1, new bytes(0));
  }
}
