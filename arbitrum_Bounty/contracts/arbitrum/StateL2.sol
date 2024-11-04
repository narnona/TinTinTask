// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.11;

import "@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol";
import "@arbitrum/nitro-contracts/src/libraries/AddressAliasHelper.sol";
import "../State.sol";

contract StateL2 is State {
    ArbSys constant arbsys = ArbSys(address(100));
    address public l1Target;

    event L2ToL1TxCreated(uint256 indexed withdrawalId);

    constructor(string memory _state, address _l1Target) State(_state) {
        l1Target = _l1Target;
    }

    function updateL1Target(address _l1Target) public {
        l1Target = _l1Target;
    }

    function setStateInL1(string memory _state) public returns (uint256) {
        bytes memory data = abi.encodeWithSelector(State.setState.selector, _state);

        uint256 withdrawalId = arbsys.sendTxToL1(l1Target, data);

        emit L2ToL1TxCreated(withdrawalId);
        return withdrawalId;
    }

    /// @notice only l1Target can update state
    function setState(string memory _state) public override {
        // To check that message came from L1, we check that the sender is the L1 contract's L2 alias.
        require(
            msg.sender == AddressAliasHelper.applyL1ToL2Alias(l1Target),
            "State only updateable by L1"
        );
        State.setState(_state);
    }
}
