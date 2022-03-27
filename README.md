# EV DID Method

## Abstract

This document describes the "EV" DID method. It conforms to the requirements specified in the [DID draft specification](https://w3c-ccg.github.io/did-spec/) currently published by the W3C Credentials Community Group.

## Status of this Document
This specification is an unofficial draft. It is provided as a reference for people and organisations who wish to implement software meant to interact with EV DID method.

## Introduction

The DID specification seeks to facilitate internet-wide, self-sovereign identity. On that basis, identifiers must be both assigned, resolved and used in a decentralised way.

Every EV DID lives on a specific Ethereum blockchain and translates naturally to and from an Ethereum address on that blockchain, representing the entity in front of DApps. Additionally, any system that has access to a node in the same blockchain as a DID may perform (read, write, auth...) operations on that DID and use it off-chain if needed.

The purpose of DIDs, and URIs in general, is interoperability. For that reason, EV DIDs are compatible with existing standards such as Verifiable Credentials, and try to not impose that other actors in a given interaction use the same blockchain, the same DID method, or even a DID as their identifier.

## Terminology
- DID: A distributed identifier
- Entity: Any person, organization, thing, vehicle, house, etc. that may be uniquely identified.

## DIDs

### DID format

The DID specification defines the following format for DIDs:

```
did:<scheme>:<scheme-specific-identifier>
```

### DID Method Name
The scheme that shall identify this DID method is: `ev`.

### Method-Specific Identifier
The method-specific identifier is composed of an optional Ethereum network identifier with a `:` separator, followed by an MNID.

```
  ev-did = "did:ev:" mnid
  mnid  = 40*HEXDIG
```

The `mnid` is a string that is compliant with the [Multi-Network ID format](https://github.com/uport-project/mnid). It refers to the Multi-Network identifier of the identity's Proxy contract. An MNID is an encoding of an (address, networkID) pair, so it's possible to compute a DID from an address and networkID pair, and vice versa. Assuming networkIDs are unique and well known, a DID thus allows to discover the specific Proxy contract behind a given DID, and reciprocally.

### Example

Example `ev` DID:

 * `did:ev:2uzPtwJmXbBqMmP9DkR7dE3FcLmgYejdJ42`

## DID Document

### Example

```json
{
  "@context": "https://w3id.org/did/v1",
  "id": "did:ev:2uzPtwJmXbBqMmP9DkR7dE3FcLmgYejdJ42",
  "controller": "did:ev:2uzPtwJmXbBqMmP9DkR7dE3FcLmgYejdJ42",
  "authentication": [{
    "id": "did:ev:2uzPtwJmXbBqMmP9DkR7dE3FcLmgYejdJ42#keys-1",
    "type": "EcdsaSecp256k1RecoveryMethod2020",
    "blockchainAccountId": "eip155:1:0xaeaefd50a2c5cda393e9a1eef2d6ba23f2c4fd6d"
  }]
}
```

## CRUD Operation Definitions

Each identity is represented by the address of a smart contract called "Proxy contract", available on an Ethereum network.

### Create (Register)

In order to create an `ev` DID, a Proxy contract must be deployed on Ethereum. The address of the deployed contract is used to compute the DID using the following algorithm:
1. The contract's address and the Ethereum network ID are put together and converted into an MNID.
2. The string "did:ev:" is prepended to the MNID.

It is common practice to deploy a Proxy contract directly from an IdentityManager instance rather than from an Ethereum account.

### Read (Resolve)

To construct a valid DID document from an `ev` DID, the following steps are performed:

#### 1. Determine the Ethereum network and the address

Extract the MNID as the method-specific part of the DID, then decode the MNID to extract the Ethereum chain ID and the address.

#### 2. Determine the key repository

The keys for an "EV" DID are kept in a smart contract called "Identity Manager", acting as a key repository. The DID resolver must be configured with known Identity Manager addresses that depend on the available Ethereum networks. It is perfectly possible for a DID resolver to be configured with an ordered list of several acceptable Identity Manager instances for a same network.

Below is a table with well-known Identity Manager addresses, but a resolver may decide to use different instances depending on their needs.

| Network              | Chain ID | Identity Manager instance address
|----------------------|----------|----------------------------------
| LACChain pre-mainnet | `0x123`  | `0x...`

Algorithm to determine the IdentityManager instance:
  1. Look up the 1st configured IdentityManager instance for the chainID that corresponds to the DID
  2. Check whether that address is defined as owner on the DID's Proxy contract
  3. Repeat steps 1-2 with the next matching IdentityManager instance until an owner is found.

To increase performance, the resolver should cache the result of that operation if the key repository is not very likely to change.

#### 3. Build a list of keys

IdentityManager contracts have a concept of "capabilities". Capabilities of a key on a DID are the operations that the key is allowed to perform for the DID. Below is a table that maps well-known capabilities to the corresponding Verification Method type in the DID Document. This list is non-exhaustive – a resolver may choose to define capabilities not on this list with specific semantics.

| IM Capability | Verification Method type
|---------------|-------------------------
| `auth`        | `authentication`
| `fw`          | `assertionMethod`
| `encrypt`     | `keyAgreement`

For each known Verification Method type from the table above, the resolver must perform the following steps:
  1. Scan for `CapabilitySet` events with the name of the corresponding capability.
  2. Temporarily store the list of keys that were given the capability.
  3. For each key in the list, perform a `hasCap()` query to check the key still has the capability, as it might have been removed.
  4. Generate a section in the DID Document for the Verification Method type, containing all the keys with the corresponding capability.

Then, apply the same method for the capabilities `devicemanager` and `admin`. Any found addresses must be set as values of the `controller` attribute at the root of the DID Document.

**Note about performance.** The resolver may cache the list of known keys up to a certain block, and scan events only from the last known block.

### Update

As per the DID Core specification, only a controller of the DID may update the DID Document.

Updates to the DID Document are made through calls to the IdentityManager contract.

#### Adding a verification method

Adding a new key as verification method to a DID is performed by calling the `setCap()` method for that key, with the capability that corresponds to the desired method (see table above).

#### Removing a verification method

Removing a verification method is like adding one, with a zero value for the `startDate` parameter.

#### Adding a controller

Adding a new key as verification method to a DID is performed by calling the `setCap()` method for that key, with a capability of `devicemanager`.

#### Removing a controller

Removing a controller from a DID is performed by calling the `setCap()` method for that key, with a capability of `devicemanager` and a zero value for the `startDate` parameter.

### Delete (Revoke) 

The delete operation is not currently supported. However, for must use cases it is sufficient to stop using a given DID, authenticating as that DID, or providing private or public information about it.