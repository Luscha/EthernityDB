pragma solidity ^0.4.11;

import "bson/documentparser.sol";
import "lib/treeflat.sol";

contract QueryEngine {
  using DocumentParser for byte[];
  using BytesUtils for byte[];
  using TreeFlat for TreeFlat.TreeRoot;
  using TreeFlat for TreeFlat.TreeIterator;

  byte constant or = 0x7c;
  byte constant eq = 0x25;

  function processQuery(byte[] query, byte[] data) constant returns (bool) {
    TreeFlat.TreeRoot memory treeDoc = data.getDocumentTree();
    TreeFlat.TreeRoot memory treeQuery = query.getDocumentTree();
    treeDoc.selectRoot();
    TreeFlat.TreeIterator memory it = treeQuery.begin();
    TreeFlat.TreeNode memory n = it.tree.nodes[0];

    byte op = eq;

    for (;; (n = it.next())) {
      if (n.deep != 0) {
        if (treeDoc.getCurrentDeep() >= treeQuery.getCurrentDeep()) {
          for (uint32 j = treeDoc.getCurrentDeep(); j >= treeQuery.getCurrentDeep(); j--) {
            treeDoc.upToParent();
          }
          if (false == treeDoc.selectChild(n.name)) {
            return false;
          }
        } else {
          if (false == treeDoc.selectChild(n.name)) {
            return false;
          }
        }
      }
      for (uint32 x = 0; x < n.lastValue; x++) {
        if (false == checkValues(n.values[x], treeDoc, data, query, op))
          return;
      }
      if (false == it.hasNext()) {
        break;
      }
    }
    return true;
  }

  function checkDocumentValidity(byte[] data, bytes3 idName) constant returns (bool) {
    // If the length is less or equal 5 the document is empty.
    if (data.length <= 5) {
      return false;
    }
    bytes7 idName7 = bytes7(sha3(bytes32(idName)));
    TreeFlat.TreeRoot memory treeDocument = data.getDocumentTree();
    // For now we let only up to 8 nested document level
    if (treeDocument.maxDeep > 8) {
      return false;
    }

    TreeFlat.TreeIterator memory it = treeDocument.begin();
    TreeFlat.TreeNode memory n = it.tree.nodes[0];

    for (;; (n = it.next())) {
      for (uint32 x = 0; x < n.lastValue; x++) {
        bytes7 name7;
        byte bType;
        (bType, name7) = DocumentParser.getTypeName8(n.values[x].key);
        // check type validity
        if (bType == 0x01 ||  bType > 0x12 || (bType >= 0x05  && bType <= 0x07) ||
            bType == 0x09  || (bType >= 0x0B  && bType <= 0x0F))
            return false;
        // chack idName
        if (n.deep == 0 && idName7 == name7)
          return false;
      }
      if (false == it.hasNext()) {
        break;
      }
    }
    return true;
  }

  function checkValues(TreeFlat.KeyIndexMap qki, TreeFlat.TreeRoot td, byte[] d, byte[] q, byte op) private constant returns (bool) {
    bool r;
    uint32 di;
    (r, di) = td.selectKey(qki.key);
    if (r != true) {
      return false;
    }
    uint32 qi = qki.value;
    byte t;
    (t,) = DocumentParser.getTypeName8(qki.key);
    return compareValues(t, di, d, qi, q, op);
  }

  function compareValues(byte t, uint32 di, byte[] d, uint32 qi, byte[] q, byte op) private constant returns (bool) {
    if (t == 0x02) { // UTF-8 string
      return compareStrings(di, d, qi, q, op);
    } else if (t == 0x07) { // ObjectId
      return compareObjectID(di, d, qi, q, op);
    } else if (t == 0x08) { // Boolean
      if (op == eq) { // dummy check, for now we use only equality
        return d[di] == q[qi];
      }
    } else if (t == 0x0A) { // Null value
        return true;
    } else if (t == 0x10) { // 32-bit integer
      return compareint32(di, d, qi, q, op);
    } else if (t == 0x11) { // Timestamp
      return compareuint64(di, d, qi, q, op);
    } else if (t == 0x12) { // 64-bit integer
      return compareint64(di, d, qi, q, op);
    }
  }

  function compareStrings(uint32 di, byte[] d, uint32 qi, byte[] q, byte op) constant internal returns (bool) {
    string memory ds = d.getString(di);
    string memory qs = q.getString(qi);
    if (op == eq) { // dummy check, for now we use only equality
      return sha3(ds) == sha3(qs);
    }
  }

  function compareObjectID(uint32 di, byte[] d, uint32 qi, byte[] q, byte op) constant internal returns (bool) {
    bytes12 doid = d.getObjectID(di);
    bytes12 qoid = q.getObjectID(qi);
    if (op == eq) { // dummy check, for now we use only equality
      return doid == qoid;
    }
  }

  function compareint32(uint32 di, byte[] d, uint32 qi, byte[] q, byte op) constant internal returns (bool) {
    int32 dint32 = int32(d.getLittleUint32(di));
    int32 qint32 = int32(q.getLittleUint32(qi));
    if (op == eq) { // dummy check, for now we use only equality
      return dint32 == qint32;
    }
  }

  function compareint64(uint32 di, byte[] d, uint32 qi, byte[] q, byte op) constant internal returns (bool) {
    int64 dint64 = int64(d.getLittleUint64(di));
    int64 qint64 = int64(q.getLittleUint64(qi));
    if (op == eq) { // dummy check, for now we use only equality
      return dint64 == qint64;
    }
  }

  function compareuint64(uint32 di, byte[] d, uint32 qi, byte[] q, byte op) constant internal returns (bool) {
    uint64 duint64 = d.getLittleUint64(di);
    uint64 quint64 = q.getLittleUint64(qi);
    if (op == eq) { // dummy check, for now we use only equality
      return duint64 == quint64;
    }
  }
}
