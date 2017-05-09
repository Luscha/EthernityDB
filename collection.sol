pragma solidity ^0.4.11;
import "interfaces.sol";
import "document.sol";

contract Collection is CollectionAbstract {
  function Collection(string strName, DBAbstract _db) {
    name = strName;
    db = _db;
    count = 0;
  }

  function newDocument(bytes12 _id, byte[] data) returns (DocumentAbstract d) {
    if (address(documentByID[_id]) != 0x0) throw;
    if (true == db.isPrivate() && tx.origin != db.owner()) throw;
    if (msg.sender != address(db)) throw;

    d = new Document(_id, data, uint64(data.length), this);
    documentByID[_id] = d;
    documentArray.push(d);
    count++;
  }
}
