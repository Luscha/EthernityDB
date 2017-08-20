pragma solidity ^0.4.11;

import "lib/stringUtils.sol";
import "lib/flag.sol";
import "interfaces.sol";

contract Database is DBAbstract {
  using StringUtils for string;
  using Flag for uint32;

  enum dbFlags {PRIVATE, VERBOSE, ALLOWPREID}

  mapping (uint64 => bytes8) private collectionsIDByIndex;
  mapping (bytes8 => CollectionAbstract) private collectionsByName;

  DriverAbstract private driver;
  CollectionFactoryAbstract private collectionFactory;

  address private owner;
  string private name;

  uint64 private collectionCount;
  uint32 private flag;

<<<<<<< HEAD
  string private version = "master-1.0.0";
=======
  string public version = "master-1.0.0";
>>>>>>> 2a6bf53467ac80a950efa8abfee2ced4b6abdaf0

  modifier OnlyDriver {
      require(msg.sender == address(driver));
        _;
  }

  function Database(string strName, bool[] flags, DriverAbstract d, CollectionFactoryAbstract cf) {
    owner = msg.sender;
    name = strName;

    if (flags[0] == true) {
      flag = flag.setBit(uint8(dbFlags.VERBOSE));
    }
    if (flags[1] == true) {
      flag = flag.setBit(uint8(dbFlags.PRIVATE));
    }
    if (flags[2] == true) {
      flag = flag.setBit(uint8(dbFlags.ALLOWPREID));
    }

    driver = d;
    collectionFactory = cf;
    driver.registerDatabase(owner, strName, this);
  }

  function getVersion() constant returns (string) {
    return version;
  }

  function setVerbose(bool _flag) {
    require(msg.sender == owner);
    if (true == _flag) {
      flag = flag.setBit(uint8(dbFlags.VERBOSE));
    } else {
      flag = flag.removeBit(uint8(dbFlags.VERBOSE));
    }
  }

  function setPrivate(bool _flag) {
    require(msg.sender == owner);
    if (true == _flag) {
      flag = flag.setBit(uint8(dbFlags.PRIVATE));
    } else {
      flag = flag.removeBit(uint8(dbFlags.PRIVATE));
    }
  }

  function setPreIDs(bool _flag) {
    require(msg.sender == owner);
    if (true == _flag) {
      flag = flag.setBit(uint8(dbFlags.ALLOWPREID));
    } else {
      flag = flag.removeBit(uint8(dbFlags.ALLOWPREID));
    }
  }

  function isVerbose() constant returns (bool) {
    return flag.isBit(uint8(dbFlags.VERBOSE));
  }

  function isPrivate() constant returns (bool) {
    return flag.isBit(uint8(dbFlags.PRIVATE));
  }

  function allowsPreIDs() constant returns (bool) {
    return flag.isBit(uint8(dbFlags.ALLOWPREID));
  }

  function getName() constant returns (string) {
    return name;
  }

  function getOwner() constant returns (address) {
    return owner;
  }

  function documentToBytes(CollectionAbstract c, uint64 index) internal constant returns (bytes12 id, bytes memory data) {
    id = c.getDocumentIDbyIndex(index);
    data = new bytes(c.getDocumentLengthbyIndex(index));
    for (uint32 i = 0; i < c.getDocumentLengthbyIndex(index); i++) {
      data[i] = c.getDocumentByteAt(id, i);
    }
  }

  function mergeHeadToData(bytes21 head, byte[] data) internal constant returns (byte[] memory merged) {
    merged = new byte[](data.length - 4 + 21);
    uint256 i = 0;
    for (; i < 21; i++) {
        merged[i] = head[i];
    }
    for (i = 4; i < data.length; i++) {
        merged[i - 4 + 21] = data[i];
    }
  }

  ////////////////////////////////////////////
  /// Driver Related
  function changeDriver(DriverAbstract newDriver) {
    require(msg.sender == owner);
    driver = newDriver;
    driver.registerDatabase(owner, name, this);
  }

  function getDriver() constant returns (DriverAbstract) {
    return driver;
  }

  ////////////////////////////////////////////
  /// Collection Fatory Related
  function changeCollectionFactory(CollectionFactoryAbstract newFC) {
    require(msg.sender == owner);
    collectionFactory = newFC;
  }

  function getCollectionFactory() constant returns (CollectionFactoryAbstract) {
    return collectionFactory;
  }

  ////////////////////////////////////////////
  /// Database Related
  function migrateDatabase(DBAbstract to) {
    require(tx.origin == owner);
    uint64 i = 0;
    for (i = 0; i < collectionCount; i++) {
      CollectionAbstract c = collectionsByName[collectionsIDByIndex[i]];
      to.receiveMigratingCollection(c, collectionsIDByIndex[i]);
      c.changeDB(to);
    }
  }

  function receiveMigratingCollection(CollectionAbstract c, bytes8 name) {
    require(tx.origin == owner);
    require(address(c) != 0x0);
    collectionsByName[name] = c;
    collectionsIDByIndex[collectionCount++] = name;
  }

  ////////////////////////////////////////////
  /// Collection Related
  function newCollection(string strName) returns (CollectionAbstract) {
    require(false == isPrivate() || msg.sender == owner);
    require(address(getCollection(strName)) == 0x0);

    CollectionAbstract c = collectionFactory.createCollection(strName, this);
    collectionsByName[bytes8(strName.toBytes32())] = c;
    collectionsIDByIndex[collectionCount++] = bytes8(strName.toBytes32());
    return c;
  }

  function getCollection(string strName) constant returns (CollectionAbstract) {
    return collectionsByName[bytes8(strName.toBytes32())];
  }

  ////////////////////////////////////////////
  /// Document Related
  function getDocument(string collection, uint64 index) constant returns (bytes12, bytes) {
    require(address(getCollection(collection)) != 0x0);
    require(getCollection(collection).getDocumentCount() > index);
    return documentToBytes(getCollection(collection), index);
  }

  ////////////////////////////////////////////
  /// Query Related
  function queryInsert(string collection, byte[] data, bytes12 preID)  returns (bytes12){
    require(false == isPrivate() || msg.sender == owner);
    require(address(getCollection(collection)) != 0x0);

    bytes12 id;
    bytes21 head;
    (id, head) = driver.processInsertion(data, isVerbose(), preID == bytes12(0) || !allowsPreIDs());
    if (preID == bytes21(0) || !allowsPreIDs()) {
      byte[] memory merged = mergeHeadToData(head, data);
      getCollection(collection).insertDocument(id, merged);
      return id;
    }

    getCollection(collection).insertDocument(preID, data);
    return preID;
  }

  function queryFind(string collection, uint64 index, byte[] query) constant returns (bytes12, int64, bytes) {
    CollectionAbstract c = getCollection(collection);
    require(address(c) != 0x0);
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
