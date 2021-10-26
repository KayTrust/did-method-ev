pragma solidity ^0.5.16;

contract MultiOwned {
  event OwnerAdded(address indexed newOwner);
  event OwnerRemoved(address indexed formerOwner);
  mapping (address => bool) public owners;
  modifier onlyOwner() {
    require(isOwner(msg.sender));
    _;
  }

  constructor(address firstOwner) public {
    owners[firstOwner] = true;
    emit OwnerAdded(firstOwner);
  }

  function isOwner(address addr) public view returns(bool) {
    return owners[addr];
  }

  function addOwner(address newOwner) public onlyOwner {
    owners[newOwner] = true;
    emit OwnerAdded(newOwner);
  }

  function renounce() public onlyOwner {
    owners[msg.sender] = false;
    emit OwnerRemoved(msg.sender);
  }
  
}