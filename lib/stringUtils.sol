pragma solidity ^0.4.11;

library StringUtils {
  function toBytes32(string self) constant returns (bytes32 ret) {
    bytes memory inputBytes = bytes(self);
    for (uint8 i = 0; i < inputBytes.length && i < 32; i++) {
      ret |= bytes32(inputBytes[i]) >> (i * 8);
    }
  }

  function toBytes32Array(string self) constant returns (bytes32[] ret) {
    bytes memory inputBytes = bytes(self);
    ret = new bytes32[]((inputBytes.length / 32) + 1);
    for (uint64 i = 0; i < inputBytes.length; i++) {
      ret[i / 32] |= bytes32(inputBytes[i]) >> ((i % 32) * 8);
    }
  }
}
