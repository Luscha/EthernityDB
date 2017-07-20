pragma solidity ^0.4.11;

import "lib/stringUtils.sol";
import "lib/bytesUtils.sol";
import "queryengine.sol";
import "interfaces.sol";

contract Driver is DriverAbstract {
  using StringUtils for string;
  using BytesUtils for byte[];

  mapping (address => mapping (bytes32 => DBAbstract)) private databasesByName;

  bytes5 constant idKeyNameEncoded = 0x075F696400;
  bytes3 constant idKeyName = 0x5F6964;
  QueryEngine queryEngine;

  function Driver (QueryEngine qe) {
    queryEngine = qe;
  }

  function registerDatabase(address owner, string strName, DBAbstract db) {
    if (address(getDatabase(owner, strName)) != 0x0) throw;
    databasesByName[msg.sender][strName.toBytes32()] = db;
  }

  function getDatabase(address owner, string strName) constant returns (DBAbstract) {
    return databasesByName[owner][strName.toBytes32()];
  }

  function processInsertion(byte[] data, bool verbose, bool generateID) constant returns (bytes12 id, bytes21 head) {
    if (true == verbose && false == queryEngine.checkDocumentValidity(data, idKeyName, generateID)) throw;
    if (generateID) {
      (id, head) = getDocumentHead(data);
    }
    else {
      return (0, 0);
    }
  }

  function processQuery(byte[] query, DocumentAbstract doc) constant returns (bool) {
    byte[] memory data = new byte[](doc.length());
    for (uint32 i = 0; i < doc.length(); i++) {
      data[i] = doc.data(i);
    }
    return queryEngine.processQuery(query, data);
  }

  function getUniqueID(byte[] seed) internal constant returns (bytes12 id) {
    // 4 bit timestamp
    // 3 bit blockSha3
    // 2 bit hash(seed, msg.sender)
    // 3 bit random
    bytes32 blockSha3 = sha3(block.blockhash(block.number - 1), msg.sender);
    bytes32 seedSha3 = sha3(seed, msg.sender);
    bytes32 randomHash = sha3(blockSha3, seed);

    for (uint8 i = 0; i < 4; i++) {
      id |= bytes4(bytes4(uint32(block.timestamp))[3 - i]) >> (i * 8);
    }
    id |= bytes12(blockSha3) & 0x00000000FFFFFF0000000000;
    id |= bytes12(seedSha3) & 0x00000000000000FFFF000000;
    id |= bytes12(randomHash) & 0x000000000000000000FFFFFF;
  }

  function getDocumentHead(byte[] data) constant returns (bytes12 id, bytes21 head) {
    id = getUniqueID(data);
    bytes4 len = bytes4(int32(data.getLittleUint32(0)) + 17);

    for (uint8 i = 0; i < 4; i++) {
      head |= bytes4(bytes4(len)[3 - i]) >> (i * 8);
    }
    head |= bytes21(idKeyNameEncoded) >> (4 * 8);
    head |= bytes21(id) >> (9 * 8);
  }
}
