pragma solidity ^0.4.11;

library BytesUtils {
    function getUint32(byte[] self, uint64 fromIndex) constant returns (uint32 ret) {
    for (uint8 i = 0; i < 4; i++) {
        ret |= uint32(self[fromIndex + i]) << (8 * (3 - i));
    }
  }

  function getUint64(byte[] self, uint64 fromIndex) constant returns (uint64 ret) {
    for (uint8 i = 0; i < 8; i++) {
        ret |= uint64(self[fromIndex + i]) << (8 * (7 - i));
    }
  }

  // Retreive Little Endian integers
  function getLittleUint32(byte[] self, uint64 fromIndex) constant returns (uint32 ret) {
    for (uint8 i = 0; i < 4; i++) {
        ret |= uint32(self[fromIndex + i]) << (8 * i);
    }
  }

  function getLittleUint64(byte[] self, uint64 fromIndex) constant returns (uint64 ret) {
    for (uint8 i = 0; i < 8; i++) {
        ret |= uint64(self[fromIndex + i]) << (8 * i);
    }
  }

  // Retreive String
  function getString(byte[] self, uint64 fromIndex) constant internal returns (string) {
    uint32 retLen = getLittleUint32(self, fromIndex);
    bytes memory b = new bytes(retLen);

    for (uint64 j = 0; j < retLen; j++) {
      b[j] = self[fromIndex + j + 4];
    }

    return string(b);
  }

  function getStringAsBytes32Array(byte[] self, uint64 fromIndex) constant returns (bytes32[] ret, uint64 retLen) {
    for (uint64 i = 0; self[i + fromIndex] != 0x0; i++) {
      retLen++;
    }
    // get also the null char
    retLen++;
    ret = new bytes32[](retLen / 32 + 1);

    for (uint64 j = 0; j < retLen; j++) {
      ret[j / 32] |= bytes32(self[j + fromIndex]) >> ((j % 32) * 8);
    }
  }

  function getStringAsBytes32Chopped(byte[] self, uint64 fromIndex) constant returns (bytes32 ret, uint64 retLen) {
    for (uint64 i = 0; self[i + fromIndex] != 0x0; i++) {
      retLen++;
    }
    // get also the null char
    retLen++;

    for (uint64 j = 0; j < retLen && j < 32; j++) {
      ret |= bytes32(self[j + fromIndex]) >> (j * 8);
    }
  }
}
