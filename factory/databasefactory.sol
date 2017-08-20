pragma solidity ^0.4.11;

import "database.sol";

contract DatabaseFactory is DatabaseFactoryAbstract {
<<<<<<< HEAD
  string private version = "master-1.0.0";

  function getVersion() constant returns (string) {
    return version;
  }
=======
  string public version = "master-1.0.0";
>>>>>>> 2a6bf53467ac80a950efa8abfee2ced4b6abdaf0

  function createDatabase(string name, bool[] flags, DriverAbstract driver, CollectionFactoryAbstract cf) returns (DBAbstract) {
    return new Database(name, flags, driver, cf);
  }
}
