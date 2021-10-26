# GlobalID DID Method

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
  "authentication": [{
    "id": "did:ev:2uzPtwJmXbBqMmP9DkR7dE3FcLmgYejdJ42#keys-1",
    "type": "EthereumAddress",
    "controller": "did:ev:2uzPtwJmXbBqMmP9DkR7dE3FcLmgYejdJ42",
    "publicKeyAddress": "0xaeaefd50a2c5cda393e9a1eef2d6ba23f2c4fd6d"
  }]
}
```

## CRUD Operation Definitions

Each identity is represented by the address of a smart contract called "Proxy contract", available on an Ethereum network.

### Create (Register)

In order to create an `ev` DID, a Proxy contract must be deployed on Ethereum. The address of the deployed contract is used to compute the DID using the following algorithm:
1. The contract's address and the Ethereum network ID are put together and converted into an MNID.
2. The string "did:ev:" is prepended to the MNID.

### Read (Resolve)

To construct a valid DID document from an `ev` DID, the following steps are performed:

1. Extract the MNID as the method-specific part of the DID
2. Determine the Ethereum network identifier and address from the MNID.
3. Access relevant information about that DID: public profile, public keys authorized for authentication, etc.

### Update

Only an authorized device for a given DID may update information about that DID.

### Delete (Revoke) 

The delete operation is not currently supported. However, for must use cases it is sufficient to stop using a given DID, authenticating as that DID, or providing private or public information about it.

## Performance Considerations

In Ethereum, looking up a raw public key from a native 20-byte address is a complex and resource-intensive process, which is why this specification refers to public keys in their "address" hash form. This makes the DID method much simpler to implement, while at the same time not really limiting the spirit of the DID specification.
