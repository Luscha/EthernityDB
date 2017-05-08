pragma solidity ^0.4.11;
import "interfaces.sol";
import "database.sol";
import "document.sol";

contract Collection is CollectionAbstract {
  function Collection(string strName, Database _db) {
    name = strName;
    db = _db;
    count = 0;
  }

  function newDocument(bytes12 _id, byte[] data) returns (DocumentAbstract d) {
    if (documentByID[_id].id() != 0) throw;
    if (true == db.isPrivate() && tx.origin != db.owner()) throw;
    if (msg.sender != address(db)) throw;

    d = new Document(_id, data, uint64(data.length), this);
    documentByID[_id] = d;
    documentArray.push(d);
    count++;
  }

  function newEmbeedDocument(DocumentAbstract p, string key, byte[] data, uint64 len) returns (DocumentAbstract c) {
    c = new Document(0, data, len, this);
    p.setEmbeededDocument(key, c);
  }
}
