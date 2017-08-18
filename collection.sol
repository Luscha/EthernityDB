pragma solidity ^0.4.11;
import "interfaces.sol";

contract Collection is CollectionAbstract {
  mapping (bytes12 => bytes32[256]) private documentByID;

  DBAbstract private db;
  bytes12[] private documentIDs;
  uint32[] private documentLengths;
  uint64 private count;
  string private name;

  string public version = "master-1.0.0";

  function Collection(string _name, DBAbstract _db) {
    db = _db;
    name = _name;
    count = 0;
  }

  function changeDB(DBAbstract _db) {
    require(msg.sender == address(db));
    db = _db;
  }

  function getDocumentCount() constant returns (uint64) {
    return count;
  }

  function getName() constant returns (string) {
    return name;
  }

  function getDocumentByteAt(bytes12 id, uint64 i) constant returns (byte) {
    uint64 bi = i / 32;
    uint64 off = i % 32;
    return byte(documentByID[id][bi][off]);
  }

  function getDocumentIDbyIndex(uint64 i) constant returns (bytes12) {
    return documentIDs[i];
  }

  function getDocumentLengthbyIndex(uint64 i) constant returns (uint32) {
    return documentLengths[i];
  }

  function insertDocument(bytes12 id, byte[] data) {
    require(msg.sender == address(db));
    require(documentByID[id][0] == 0x0);
    uint256 i = 0;
    bytes32[] memory data32;

    if (data.length % 32 == 0) {
        data32 = new bytes32[](data.length / 32);
    } else {
        data32 = new bytes32[](data.length / 32 + 1);
    }

    for (i = 0; i < data.length; i++) {
        data32[i / 32] |= bytes32(data[i]) >> ((i % 32) * 8);
    }

    for (i = 0; i < data32.length; i++) {
        documentByID[id][i] = data32[i];
    }

    documentLengths.push(uint32(data.length));
    documentIDs.push(id);
    count++;
  }
}
