// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.11;

contract State {
    string state;

    constructor(string memory _state) {
        state = _state;
    }

    function getState() public view returns (string memory) {
        return state;
    }

    function setState(string memory _state) public virtual {
        state = _state;
    }
}
