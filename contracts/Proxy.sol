pragma solidity ^0.5.16;
import "./MultiOwned.sol";

contract Proxy is MultiOwned {
    
  event Forwarded (address indexed destination, uint value, bytes data);
  event Received (address indexed sender, uint value);

  constructor(address firstOwner) MultiOwned(firstOwner) public {}

  function () external payable { emit Received(msg.sender, msg.value); }

  function forward(address destination, uint value, bytes memory data) public onlyOwner {
    (bool success, bytes memory returnData) = destination.call.value(value)(data);
    require(success, string(returnData));
    emit Forwarded(destination, value, data);
  }
}
