// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./BancorFormula.sol";
import "./SafeMath.sol";

contract Main is ERC1155, BancorFormula {

    uint256 public totalTokens = 0;

     /*
    reserve ratio, represented in ppm, 1-1000000
    1/3 corresponds to y= multiple * x^2
    1/2 corresponds to y= multiple * x
    2/3 corresponds to y= multiple * x^1/2
    multiple will depends on contract initialization,
    specificallytotalAmount and poolBalance parameters
    we might want to add an 'initialize' function that will allow
    the owner to send ether to the contract and mint a given amount of tokens
    */
    mapping (uint256 => uint32) public reserveRatios;
  
    mapping (uint256 => uint256) public poolBalances;
  
    mapping (uint256 => uint256) public currentPrice;

    mapping (uint256 => uint256) public totalSupplies;

    function mintToken(address _userAddress, uint256 _id, uint256 _amount) public {
        _mint(_userAddress, _id, _amount, "");
    }

    function burnToken(address _userAddress, uint256 _id, uint256 _amount) public {
        _burn(_id, _amount, "");
    }

    function createNewToken(uint32 _reserveRatio, uint256 _initialSupply, uint256 _initialPoolBalance)public returns (uint256 id){
        require(_reserveRatio > 0 && _initialSupply > 0 && _initialPoolBalance > 0, "Initial values must not be zero");
        totalTokens = totalTokens.add(1);
        calculatePurchaseReturn(totalSupplies[totalTokens], poolBalances[totalTokens], reserveRatios[totalTokens], _initialPoolBalance);
        poolBalances[totalTokens] = _initialPoolBalance;
        totalSupplies[totalTokens] = _initialSupply;
        reserveRatios[totalTokens] = _reserveRatio;
    }
}

