# Pragma Contracts - Deployments

This folder contains the deployment scripts for all Pragma Contracts.

# Requirements

You'll need either [NPM](https://www.npmjs.com/) or [Bun](https://bun.sh/).

## Install dependencies:

```bash
bun install
# or
npm install
```

# Available deployments

## Pragma Oracle

For example, to deploy it on a Madara Devnet:

```bash
bun run deployer oracle --config ./config/config.example.yaml --chain madara_devnet
# or
npm run deployer oracle -- --config ./config/config.example.yaml --chain madara_devnet
```

## Pragma Dispatcher

For example, to deploy it on a Madara Devnet:

```bash
bun run deployer dispatcher --config ./config/config.example.yaml --chain madara_devnet
# or
npm run deployer dispatcher -- --config ./config/config.example.yaml --chain madara_devnet
```

## Pragma Solidity contracts

For example, to deploy it locally on a forked network:

```bash
bun run deployer pragma --config ./config/config.example.yaml --chain hardhat
# or
npm run deployer pragma -- --config ./config/config.example.yaml --chain hardhat
```

The etherscan verification should be automatic after a deployment.

If you'd like to verify a pre-deployed contract, you can also run:

```bash
bun run verifier pragma --config ./config/config.example.yaml --chain sepolia
```

It will look up the `deployments` folder for any deployments on `sepolia`. If any, it will
attempt a verification for the `Hyperlane` & `Pragma` contracts.

# Available chains

## Starknet

- starknet,
- starknet
