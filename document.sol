pragma solidity ^0.4.11;
import {DocumentAbstract} from "interfaces.sol";

contract Document is DocumentAbstract {
  // For the future it might be better to use an array of bytes32
  // that maps the structure of the data using the single bits
  // Es:
  // bytes32 keyMap = 00001100000011000000110000011
  //  Where the 1s are the bytes where the key are
  function Document(byte[] _data, bytes21 head) {
    for (uint64 i = 0; i < 21; i++) {
        data.push(head[i]);
    }
    for (i = 0; i < _data.length - 4; i++) {
        data.push(_data[i + 4]);
    }
  }

  function getData() constant returns (byte[]) {
    return data;
  }
}
