# Enso Shortcuts Safe Contracts

Small contract to allow [Safes](https://safe.global/) to run Enso Shortcuts.

## Install

Requires [Foundry](https://getfoundry.sh/).

```bash
$ forge install
$ forge build
```

## Tests

```bash
$ forge test
```

## Deployment

Copy `.env.example` to `.env`, fill out required values.

```bash
$ forge script Deployer --broadcast --fork-url <network>
```
