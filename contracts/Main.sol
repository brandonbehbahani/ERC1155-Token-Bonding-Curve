// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./BancorFormula.sol";

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

    mapping (uint256 => bool) public isBonded;

    function mintToken(address _userAddress, uint256 _id, uint256 _amount) public {
        uint256 amount = calculateCurvedMintReturn(_id, deposit);
        _mint(user, _id, amount, '');
        emit CurvedMint(user, amount, deposit);
        
        currentPrice[_id] = amount.div(deposit);
        
        return amount;
    }

    function burnToken(address _userAddress, uint256 _id, uint256 _amount) public {
        uint256 reimbursement = calculateCurvedBurnReturn(_id, amount);
        _burn(user, _id, amount);
        emit CurvedBurn(user, amount, reimbursement);
    
        currentPrice[_id] = amount.div(reimbursement);
    
        return reimbursement;
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

