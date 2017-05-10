pragma solidity ^0.4.11;
import "../lib/bytesUtils.sol";

library DocumentParser {
  using BytesUtils for byte[];
  using DocumentParser for byte[];

  function nextKeyValue(byte[] memory d, uint64 i) constant internal returns (uint8 t, bytes32 n, uint64 l, uint64 s) {
    t = d.getKeyValueType(i);
    if (t == 0x0) {
      return;
    }

    (n, l) = d.getStringAsBytes32Chopped(i + 1);
    n = getCombinedNameType(n, t);
    // get the type byte too
    l += 1;
    s = l;

    l += d.getKeyValueLength(i + l, t);
    if (t == 0x02) {
      s += 4;
    } else if (t == 0x03 || t == 0x04) {
      s += 4;
    }
  }

  function getKeyValueType(byte[] memory d, uint64 i) constant internal returns (uint8 t) {
    t = uint8(d[i]);
  }

  function getKeyValueLength(byte[] memory d, uint64 i, uint8 t) constant internal returns (uint64 l) {
    if (t == 0x01) {
      l = 8;
    } else if (t == 0x02) {
      l = uint64(int32(d.getLittleUint32Mem(i + l))) + 4;
    } else if (t == 0x03 || t == 0x04) {
      l = uint64(int32(d.getLittleUint32Mem(i + l)));
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

  // This function combines the key name with his type so that later is possible to search for a 
  // particular key with a given type in a single lookup
  function getCombinedNameType(bytes32 n, uint8 t) constant private returns (bytes32 comb){
    comb = sha3(n, t);
    comb = comb >> 8 | bytes32(t) << 26;
  }
}
