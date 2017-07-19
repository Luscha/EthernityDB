pragma solidity ^0.4.11;

library Flag {
  function setBit(uint32 self, uint8 bit) returns (uint32) {
    return self | (0x00000000000000000000000000000001 << bit);
  }

  function removeBit(uint32 self, uint8 bit) returns (uint32) {
    return self & (~(0x00000000000000000000000000000001 << bit));
  }

  function toggleBit(uint32 self, uint8 bit) returns (uint32) {
    return self ^ (0x00000000000000000000000000000001 << bit);
  }

  function isBit(uint32 self, uint8 bit) returns (bool) {
    return self & (0x00000000000000000000000000000001 << bit) == (0x00000000000000000000000000000001 << bit);
  }
}
