// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./BancorFormula.sol";

contract ERC1155BondingCurve is BancorFormula, ERC1155{

    uint256 public totalTokens = 0;

    uint256 public maxGasPrice = 1 * 10**18;

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

    event CurvedMint(address sender, uint256 amount, uint256 deposit, uint256 id);

    event CurvedBurn(address sender, uint256 amount, uint256 reimbursement, uint256 id);

    function createNewToken(uint32 _reserveRatio, uint256 _initialSupply, uint256 _initialPoolBalance)public returns (uint256 id){
        require(_reserveRatio > 0 && _initialSupply > 0 && _initialPoolBalance > 0, "Initial values must not be zero");
        poolBalances[totalTokens] = _initialPoolBalance;
        totalSupplies[totalTokens] = _initialSupply;
        reserveRatios[totalTokens] = _reserveRatio;
        calculatePurchaseReturn(totalSupplies[totalTokens], poolBalances[totalTokens], reserveRatios[totalTokens], _initialPoolBalance);
        totalTokens++;
    }

    // --- PUBLIC FUNCTIONS: ---

    function mint(uint256 _amount, uint256 id) public {
        _curvedMint(_amount, id);
    }

    function burn(uint256 _amount, uint256 id) public {
        _curvedBurn(_amount, id);
    }

    function calculateCurvedMintReturn(uint256 amount, uint256 id) public view returns (uint256) {
        return calculatePurchaseReturn(totalSupplies[id], poolBalances[id], reserveRatios[id], amount);
    }

    function calculateCurvedBurnReturn(uint256 amount, uint256 id) public view returns (uint256) {
        return calculateSaleReturn(totalSupplies[id], poolBalances[id], reserveRatios[id], amount);
    }

    /**
    * @dev Mint tokens
    */
    function _curvedMint(uint256 deposit, uint256 id) internal returns (uint256) {
        return _curvedMintFor(msg.sender, deposit, id);
    }

    function _curvedMintFor(address user, uint256 deposit, uint256 id)
        validGasPrice
        validMint(deposit)
        internal
        returns (uint256)
    {
        uint256 amount = calculateCurvedMintReturn(deposit, id);
        _mint(user, id, amount, "");
        emit CurvedMint(user, amount, deposit, id);
        return amount;
    }

    /**
    * @dev Burn tokens
    * @param amount Amount of tokens to withdraw
    */
    function _curvedBurn(uint256 amount, uint256 id) internal returns (uint256) {
        return _curvedBurnFor(msg.sender, amount, id);
    }

    function _curvedBurnFor(address user, uint256 amount, uint256 id) validGasPrice validBurn(amount, id) internal returns (uint256) {
        uint256 reimbursement = calculateCurvedBurnReturn(amount, id);
        _burn(user, id, amount);
        emit CurvedBurn(user, amount, reimbursement, id);
        return reimbursement;
    }

    /**
        @dev Allows the owner to update the gas price limit
        @param newPrice The new gas price limit
    */
    function setMaxGasPrice(uint256 newPrice) public {
        maxGasPrice = newPrice;
    }

    // verifies that the gas price is lower than the universal limit
    modifier validGasPrice() {
        require(tx.gasprice <= maxGasPrice, "Gas price must be <= maximum gas price to prevent front running attacks.");
        _;
    }

    modifier validBurn(uint256 amount, uint256 id) {
        require(amount > 0 && balanceOf(msg.sender, id) >= amount);
        _;
    }

    modifier validMint(uint256 amount) {
        require(amount > 0);
        _;
    }    

    function sendEther(address payable recipient, uint256 amount) public payable nonReentrant {
        require(address(this).balance >= amount, "Insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");
    }

    
}

