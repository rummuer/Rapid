//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RapidToken is ERC20("RapidToken", "RapidToken"), Ownable {

    function mint(address receiver, uint amount) public onlyOwner{
        _mint(receiver, amount);
    }
}