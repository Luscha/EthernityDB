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
  //function processQuery(byte[] query, byte[] data) constant returns (bool) {
    TreeFlat.TreeRoot memory treeDoc = data.getDocumentTree();
    treeDoc = treeDoc.selectRoot();
    TreeFlat.TreeIterator memory it = query.getDocumentTree().begin();
    TreeFlat.TreeNode memory n = it.tree.nodes[0];

    uint32 i = 0;
    byte op = eq;

    uint32 orDepth = 0;
    bool success = true;

    for (; n.depth != it.end().depth; ((it, n) = it.next())) {
      // ///////////////////////////
      // //// OR CLAUSE AMANGEMENT
      if (orDepth != 0 && success == true &&
        (orDepth & 0x0F000000) == 0x0F000000 && (orDepth & 0x000FFFFF) == n.depth) { // OR satisfied, reset orDepth
        orDepth = 0;
      }

      if (orDepth != 0) {
        if ((success == true && (orDepth & 0x0F000000) == 0x0F000000 && n.depth > (orDepth & 0x000FFFFF)) || // condition satisfied, cotinue till root of the OR
          (success == false && n.depth > (orDepth & 0x000FFFFF) + 1)) {// condition failed, cotinue till root of the OR
            continue;
        }

        if (success == false && (orDepth & 0x000FFFFF) == n.depth) {
          return false;
        } // OR failed, return false

        if (success == true && (orDepth & 0x000FFFFF) + 1 == n.depth) {
          if ((orDepth & 0x00F00000) == 0x00F00000) { // if oDepth & 15728640 it means we are at least in the second condition
            orDepth |= 0x0F000000;
            continue;
          } else {
            orDepth |= 0x00F00000;
          }
        }

        if (success == false && (orDepth & 0x000FFFFF) + 1 == n.depth) { // after the failed clause, restore the orDepth
          success = true;
        }
      }

      if (n.name == DocumentParser.getCombinedNameType8(or, 0x04)) {
        orDepth = n.depth;
        continue;
      }
      // //// OR CLAUSE AMANGEMENT
      // ///////////////////////////
      if (n.depth != 0) {
        if (orDepth == 0) {
          for (i = treeDoc.getCurrentDepth(); i >= n.depth; i--) {
            treeDoc = treeDoc.upToParent();
          }
          (success, treeDoc) = treeDoc.selectChild(n.name);
          if (false == success) {
            return false;
          }
        } else {
          for (i = treeDoc.getCurrentDepth(); i > n.depth - 2; i--) {
            treeDoc = treeDoc.upToParent();
          }
          if (n.depth > (orDepth & 0x000FFFFF) + 1) {
            (success, treeDoc) = treeDoc.selectChild(n.name);
            if (false == success) {
              continue;
            }
          }
        }
      }

      for (i = 0; i < n.lastValue && true == success; i++) {
        success = checkValues(n.values[i], treeDoc, data, query, op);
        if (false == success && orDepth == 0) {
          return false;
        }
      }
    }
    return success;
  }

  function checkDocumentValidity(byte[] data, bytes3 idName, bool generateID) constant returns (bool) {
    // If the length is less or equal 5 the document is empty.
    if (data.length <= 5) {
      return false;
    }
    bytes7 idName7 = bytes7(sha3(bytes32(idName)));
    TreeFlat.TreeRoot memory treeDocument = data.getDocumentTree();
    // For now we let only up to 8 nested document level
    if (treeDocument.maxDepth > 8) {
      return false;
    }

    TreeFlat.TreeIterator memory it = treeDocument.begin();
    TreeFlat.TreeNode memory n = it.tree.nodes[0];

    uint32 x = 0;
    bytes7 name7;
    byte bType;

    for (; n.depth != it.end().depth; ((it, n) = it.next())) {
      for (x = 0; x < n.lastValue; x++) {
        (bType, name7) = DocumentParser.getTypeName8(n.values[x].key);
        // check type validity
        if (bType == 0x01 ||  bType > 0x12 || (bType >= 0x05  && bType <= 0x07) ||
            bType == 0x09  || (bType >= 0x0B  && bType <= 0x0F))
            return false;
        // chack idName
        if (generateID == false && n.depth == 0 && idName7 == name7)
          return false;
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
    return false;
  }

  function compareStrings(uint32 di, byte[] d, uint32 qi, byte[] q, byte op) constant internal returns (bool) {
    string memory ds = d.getString(di);
    string memory qs = q.getString(qi);
    if (op == eq) { // dummy check, for now we use only equality
      return sha3(ds) == sha3(qs);
    }
    return false;
  }

  function compareObjectID(uint32 di, byte[] d, uint32 qi, byte[] q, byte op) constant internal returns (bool) {
    bytes12 doid = d.getObjectID(di);
    bytes12 qoid = q.getObjectID(qi);
    if (op == eq) { // dummy check, for now we use only equality
      return doid == qoid;
    }
    return false;
  }

  function compareint32(uint32 di, byte[] d, uint32 qi, byte[] q, byte op) constant internal returns (bool) {
    int32 dint32 = int32(d.getLittleUint32(di));
    int32 qint32 = int32(q.getLittleUint32(qi));
    if (op == eq) { // dummy check, for now we use only equality
      return dint32 == qint32;
    }
    return false;
  }

  function compareint64(uint32 di, byte[] d, uint32 qi, byte[] q, byte op) constant internal returns (bool) {
    int64 dint64 = int64(d.getLittleUint64(di));
    int64 qint64 = int64(q.getLittleUint64(qi));
    if (op == eq) { // dummy check, for now we use only equality
      return dint64 == qint64;
    }
    return false;
  }

  function compareuint64(uint32 di, byte[] d, uint32 qi, byte[] q, byte op) constant internal returns (bool) {
    uint64 duint64 = d.getLittleUint64(di);
    uint64 quint64 = q.getLittleUint64(qi);
    if (op == eq) { // dummy check, for now we use only equality
      return duint64 == quint64;
    }
    return false;
  }
}
