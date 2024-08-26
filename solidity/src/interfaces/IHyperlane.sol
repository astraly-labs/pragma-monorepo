// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

struct Signature {
    bytes32 r;
    bytes32 s;
    uint8 v;
    uint8 validatorIndex;
}

struct HyMsg {
    uint8 version;
    uint32 timestamp;
    uint32 nonce;
    uint16 emitterChainId;
    bytes32 emitterAddress;
    bytes payload;
    Signature[] signatures;
    bytes32 hash;
}