pragma solidity ^0.4.11;
import {DocumentAbstract} from "interfaces.sol";

contract Document is DocumentAbstract {
  function Document(byte[] _data, bytes21 head) {
    for (uint32 i = 0; i < 21; i++) {
        data[i] = (head[i]);
    }
    for (i = 4; i < _data.length; i++) {
        data[i - 4 + 21] = _data[i];
    }

    length = uint32(_data.length) - 4 + 21;
  }
}
