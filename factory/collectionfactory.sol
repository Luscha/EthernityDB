pragma solidity ^0.4.11;

import "collection.sol";

contract CollectionFactory is CollectionFactoryAbstract {
<<<<<<< HEAD
  string private version = "master-1.0.0";

  function getVersion() constant returns (string) {
    return version;
  }
=======
  string public version = "master-1.0.0";
>>>>>>> 2a6bf53467ac80a950efa8abfee2ced4b6abdaf0

  function createCollection(string name, DBAbstract db) returns (CollectionAbstract) {
    return new Collection(name, db);
  }
}
