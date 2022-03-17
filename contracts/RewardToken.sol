//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardToken is ERC20("rewardToken","rewardToken"), Ownable{

address public farmContractAddress;

function setFarmContractAddress(address _farmContractAddress) public onlyOwner{
    farmContractAddress = _farmContractAddress;
}
modifier onlyFarmContract {
    require(msg.sender == farmContractAddress);
    _;
}

function mint(address receiver, uint amount) public onlyFarmContract{
    _mint(receiver, amount);
}
}
