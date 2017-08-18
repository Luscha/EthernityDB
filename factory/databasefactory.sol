pragma solidity ^0.4.11;

import "database.sol";

contract DatabaseFactory is DatabaseFactoryAbstract {
  string public version = "master-1.0.0";

  function createDatabase(string name, bool[] flags, DriverAbstract driver, CollectionFactoryAbstract cf) returns (DBAbstract) {
    return new Database(name, flags, driver, cf);
  }
}
