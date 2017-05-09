pragma solidity ^0.4.11;
import "../lib/bytesUtils.sol";

library DocumentParser {
  using BytesUtils for byte[];

  function nextKeyValue(byte[] memory d, uint64 i) constant returns (uint8 t, bytes32 n, uint64 l, uint64 s) {
    t = uint8(d[i]);
    if (t == 0x0) {
      return;
    }

    (n, l) = d.getStringAsBytes32Chopped(i + 1);
    // get the type byte too
    l += 1;
    s = l;

    if (t == 0x01) {
      l += 8;
    } else if (t == 0x02) {
      l += uint64(int32(d.getLittleUint32Mem(i + l))) + 4;
      s += 4;
    } else if (t == 0x03 || t == 0x04) {
      l += uint64(int32(d.getLittleUint32Mem(i + l)));
      s += 4;
    } else if (t == 0x07) {
      l += 12;
    } else if (t == 0x08) {
      l += 1;
    } else if (t == 0x10) {
      l += 4;
    } else if (t == 0x11 || t == 0x12) {
      l += 8;
    }
  }
}
