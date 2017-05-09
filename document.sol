pragma solidity ^0.4.11;
import {DocumentAbstract} from "interfaces.sol";

contract Document is DocumentAbstract {
  // For the future it might be better to use an array of bytes32
  // that maps the structure of the data using the single bits
  // Es:
  // bytes32 keyMap = 00001100000011000000110000011
  //  Where the 1s are the bytes where the key are
  function Document(bytes12 _id, byte[] _data) {
    id = _id;

    for (uint64 i = 0; i < _data.length; i++) {
      data.push(_data[i]);
    }
  }

  function getData() constant returns (byte[]) {
    return data;
  }
}
