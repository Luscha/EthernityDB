pragma solidity ^0.4.11;

import "collection.sol";

contract CollectionFactory is CollectionFactoryAbstract {
  string private version = "master-1.0.0";

  function getVersion() constant returns (string) {
    return version;
  }

  function createCollection(string name, DBAbstract db) returns (CollectionAbstract) {
    return new Collection(name, db);
  }
}
