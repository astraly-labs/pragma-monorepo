// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IMessageRecipient} from "@hyperlane-xyz/core/interfaces/IMessageRecipient.sol";
import {IInterchainSecurityModule, ISpecifiesInterchainSecurityModule} from "@hyperlane-xyz/core/interfaces/IInterchainSecurityModule.sol";

contract HyperlaneRecipient is
    Ownable,
    IMessageRecipient,
    ISpecifiesInterchainSecurityModule
{
    // @notice merkle verification module
    IInterchainSecurityModule public interchainSecurityModule;
    // @notice pragma_core contract address
    IPragma public pragma_core;
    // @notice mapping from data id to sender
    mapping(bytes => bytes32) public dataIdToSender;
    // @notice last data received
    bytes public lastData;

    event ReceivedMessage(
        uint32 indexed origin,
        bytes32 indexed sender,
        uint256 indexed value,
        string message
    );

    constructor(address initialOwner) Ownable(initialOwner) {}

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _data
    ) external payable virtual override {
        emit ReceivedMessage(_origin, _sender, msg.value, string(_data));

        dataId = keccak256(abi.encodePacked(_origin, _sender, _data));

        dataIdToSender[dataId] = _sender;
        lastData = _data;

        // Updates data in Pragma core contract
        pragma_core.updateData(dataId, _data);
    }

    function setInterchainSecurityModule(address _ism) external onlyOwner {
        interchainSecurityModule = IInterchainSecurityModule(_ism);
    }
}
