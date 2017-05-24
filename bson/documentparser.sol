pragma solidity ^0.4.11;
import "lib/bytesUtils.sol";
import "lib/treeflat.sol";

library DocumentParser {
  using BytesUtils for byte[];
  using DocumentParser for byte[];
  using DocumentParser for bytes32;
  using TreeFlat for TreeFlat.TreeRoot;

  function nextKeyValue(byte[] memory d, uint32 i) constant internal returns (uint8 t, bytes8 n, uint32 l, uint32 s) {
    t = d.getKeyValueType(i);
    if (t == 0x0) {
      return;
    }

    bytes32 n32;
    uint64 l64;
    (n32, l64) = d.getStringAsBytes32Chopped(uint32(i + 1));
    n = getCombinedNameType8(n32, t);
    l = uint32(l64);
    // get the type byte too
    l += 1;
    s = l;

    l += d.getKeyValueLength(i + l, t);
    /*if (t == 0x02) {
      s += 4;
    } else*/ if (t == 0x03 || t == 0x04) {
      s += 4;
    }
  }

  function getKeyValueType(byte[] memory d, uint32 i) constant internal returns (uint8 t) {
    t = uint8(d[i]);
  }

  function getKeyValueLength(byte[] memory d, uint32 i, uint8 t) constant internal returns (uint32 l) {
    if (t == 0x01) {
      l = 8;
    } else if (t == 0x02) {
      l = uint32(int32(d.getLittleUint32(i + l))) + 4;
    } else if (t == 0x03 || t == 0x04) {
      l = uint32(int32(d.getLittleUint32(i + l)));
    } else if (t == 0x07) {
      l = 12;
    } else if (t == 0x08) {
      l = 1;
    } else if (t == 0x10) {
      l = 4;
    } else if (t == 0x11 || t == 0x12) {
      l = 8;
    }
  }

  function getDocumentTree(byte[] memory data) constant internal returns (TreeFlat.TreeRoot tree) {
    tree = TreeFlat.newRoot();
    if (data.length < 4) {
      return;
    }
    int8 documentIndex = -1;
    // For now we let only up to 32 nested document level
    uint32[] memory embeedDocumentStack = new uint32[](32);
    // Skip first 4 BYTE (int32 = Doc length)
    for (uint32 i = 4; i < data.length - 1; i++) {
        // Select parent nodeTree if available
        if (documentIndex >= 0 && embeedDocumentStack[uint8(documentIndex)] <= i) {
          tree = tree.upToParent();
          documentIndex--;
        }

        uint8 bType = 0;
        bytes8 b8Name = 0;
        uint32 nDataLen = 0;
        uint32 nDataStart = 0;
        (bType, b8Name, nDataLen, nDataStart) = data.nextKeyValue(i);

        if (bType == 0x0) {
          continue;
        }
        if (bType == 0x03 || bType == 0x04) {
          // For now we let only up to 32 nested document level
          if (documentIndex > 31) throw;
          tree = tree.addChild(b8Name);
          embeedDocumentStack[uint8(++documentIndex)] = i + nDataLen - 1;
          i += nDataStart - 1;
        } else {
          tree = tree.setKeyIndex(b8Name, uint32(i + nDataStart));
          i += nDataLen - 1;
        }
    }
  }

  function getObjectID(byte[] memory d, uint32 i) constant internal returns (bytes12 oid){
    for (uint32 j = i; j < i + 12; j++) {
      oid |= bytes12(d[j]) >> (8 * j);
    }
  }

  // This function combines the key name with his type so that later is possible to search for a
  // particular key with a given type in a single lookup
  function getCombinedNameType(bytes32 n, uint8 t) constant internal returns (bytes32 comb){
    comb = sha3(n);
    comb = comb >> 8 | bytes32(t) << (8 * 31);
  }

  function getTypeName(bytes32 comb) constant internal returns (byte t, bytes31 k){
    t = comb[0];
    k = bytes31(comb << 8);
  }

  // Like above but it returns only a 8 byte key
  function getCombinedNameType8(bytes32 n, uint8 t) constant internal returns (bytes8 comb){
    comb = bytes8(sha3(n));
    comb = (comb >> 8) | (bytes8(t) << (8 * 7));
  }

  function getTypeName8(bytes8 comb) constant internal returns (byte t, bytes7 k){
    t = comb[0];
    k = bytes7(comb << 8);
  }
}
