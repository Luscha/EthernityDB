pragma solidity ^0.4.11;

library BytesUtils {
  function getUint32(byte[] storage self, uint64 fromIndex) constant returns (uint32 ret) {
    for (uint8 i = 0; i < 4; i++) {
        ret |= uint32(self[fromIndex + i]) << (8 * (3 - i));
    }
  }

  function getUint64(byte[] storage self, uint64 fromIndex) constant returns (uint64 ret) {
    for (uint8 i = 0; i < 8; i++) {
        ret |= uint64(self[fromIndex + i]) << (8 * (7 - i));
    }
  }

  function getUint32Mem(byte[] memory self, uint64 fromIndex) constant returns (uint32 ret) {
    for (uint8 i = 0; i < 4; i++) {
        ret |= uint32(self[fromIndex + i]) << (8 * (3 - i));
    }
  }

  function getUint64Mem(byte[] memory self, uint64 fromIndex) constant returns (uint64 ret) {
    for (uint8 i = 0; i < 8; i++) {
        ret |= uint64(self[fromIndex + i]) << (8 * (7 - i));
    }
  }

  function getLittleUint32(byte[] storage self, uint64 fromIndex) constant returns (uint32 ret) {
    for (uint8 i = 0; i < 4; i++) {
        ret |= uint32(self[fromIndex + i]) << (8 * i);
    }
  }

  function getLittleUint64(byte[] storage self, uint64 fromIndex) constant returns (uint64 ret) {
    for (uint8 i = 0; i < 8; i++) {
        ret |= uint64(self[fromIndex + i]) << (8 * i);
    }
  }

  function getLittleUint32Mem(byte[] memory self, uint64 fromIndex) constant returns (uint32 ret) {
    for (uint8 i = 0; i < 4; i++) {
        ret |= uint32(self[fromIndex + i]) << (8 * i);
    }
  }

  function getLittleUint64Mem(byte[] memory self, uint64 fromIndex) constant returns (uint64 ret) {
    for (uint8 i = 0; i < 8; i++) {
        ret |= uint64(self[fromIndex + i]) << (8 * i);
    }
  }
}
