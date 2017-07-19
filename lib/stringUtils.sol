pragma solidity ^0.4.11;

library StringUtils {
  function toBytes32(string self) constant returns (bytes32 ret) {
    bytes memory inputBytes = bytes(self);
    for (uint8 i = 0; i < inputBytes.length && i < 32; i++) {
      ret |= bytes32(inputBytes[i]) >> (i * 8);
    }
  }
}
