pragma solidity ^0.4.11;

import "collection.sol";

contract CollectionFactory is CollectionFactoryAbstract {
  function createCollection(string name, DBAbstract db) returns (CollectionAbstract) {
    return new Collection(name, db);
  }
}
