pragma solidity ^0.4.11;

library Flag {
  function setBit(uint32 self, uint8 bit) returns (uint32) {
    return self | (uint32(1) << bit);
  }

  function removeBit(uint32 self, uint8 bit) returns (uint32) {
    return self & ((uint32(1) << bit) ^ uint32(-1));
  }

  function toggleBit(uint32 self, uint8 bit) returns (uint32) {
    return self ^ (uint32(1) << bit);
  }

  function isBit(uint32 self, uint8 bit) returns (bool) {
    return self & (uint32(1) << bit) == (uint32(1) << bit);
  }
}
