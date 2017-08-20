pragma solidity ^0.4.11;

import "database.sol";

contract DatabaseFactory is DatabaseFactoryAbstract {
  string private version = "master-1.0.0";

  event databaseCreated(address owner, string name);

  function getVersion() constant returns (string) {
    return version;
  }

  function createDatabase(string name, bool[] flags, DriverAbstract driver, CollectionFactoryAbstract cf) returns (DBAbstract) {
    databaseCreated(tx.origin, name);
    return new Database(name, flags, driver, cf);
  }
}
