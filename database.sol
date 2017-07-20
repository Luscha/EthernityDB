pragma solidity ^0.4.11;
import "lib/stringUtils.sol";
import "lib/flag.sol";
import "interfaces.sol";
import "collection.sol";

contract Database is DBAbstract {
  using StringUtils for string;
  using Flag for uint32;

  enum dbFlags {PRIVATE, VERBOSE}

  mapping (uint64 => bytes8) private collectionsIDByIndex;
  mapping (bytes8 => CollectionAbstract) private collectionsByName;

  DriverAbstract internal driver;
  address public owner;
  string public name;

  uint64 private collectionCount;
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

  function documentToBytes(CollectionAbstract c, uint64 index) internal constant returns (bytes12 id, bytes memory data) {
    id = c.getDocumentIDbyIndex(index);
    data = new bytes(c.getDocumentLengthbyIndex(index));
    for (uint32 i = 0; i < c.getDocumentLengthbyIndex(index); i++) {
    data[i] = c.getDocumentByteAt(id, i);
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
    for (i = 0; i < collectionCount; i++) {
      CollectionAbstract c = collectionsByName[collectionsIDByIndex[i]];
      to.receiveMigratingCollection(c, collectionsIDByIndex[i]);
      c.changeDB(to);
    }
  }

  function receiveMigratingCollection(CollectionAbstract c, bytes8 name) {
    if (tx.origin != owner) throw;
    if (address(c) == 0x0) throw;
    collectionsByName[name] = c;
    collectionsIDByIndex[collectionCount++] = name;
  }

  ////////////////////////////////////////////
  /// Collection Related
  function newCollection(string strName) {
    if (address(getCollection(strName)) != 0x0) throw;
    if (true == isPrivate() && msg.sender != owner) throw;

    Collection c = new Collection(strName, this);
    collectionsByName[bytes8(strName.toBytes32())] = c;
    collectionsIDByIndex[collectionCount++] = bytes8(strName.toBytes32());
  }

  function getCollection(string strName) constant returns (CollectionAbstract) {
    return collectionsByName[bytes8(strName.toBytes32())];
  }

  ////////////////////////////////////////////
  /// Document Related
  function getDocument(string collection, uint64 index) constant returns (bytes12, bytes) {
    if (address(getCollection(collection)) == 0x0) throw;
    if (getCollection(collection).getDocumentCount() <= index) throw;
    return documentToBytes(getCollection(collection), index);
  }

  ////////////////////////////////////////////
  /// Query Related
  function queryInsert(string collection, byte[] data, bytes12 preID) {
    if (true == isPrivate() && msg.sender != owner) throw;
    if (address(getCollection(collection)) == 0x0) throw;

    bytes12 id;
    bytes21 head;
    (id, head) = driver.processInsertion(data, isVerbose(), preID == bytes12(0) && false == isPrivate());
    if (preID == bytes21(0) || false == isPrivate()) {
      getCollection(collection).insertDocument(id, head, data);
    }
    else {
      getCollection(collection).insertDocument(preID, bytes21(0), data);
    }
  }

  function queryFind(string collection, uint64 index, byte[] query) constant returns (bytes12, int64, bytes) {
    CollectionAbstract c = getCollection(collection);
    if (address(c) == 0x0) throw;
    bytes12 id;
    bytes memory data;
    for (index; index < c.getDocumentCount(); index++) {
      (id, data) = documentToBytes(c, index);
      if (true == driver.processQuery(query, data)) {
        (id, data) = documentToBytes(c, index);
        return (id, int64(index), data);
      }
    }
    return (bytes12(0), -1, new bytes(0));
  }
}
