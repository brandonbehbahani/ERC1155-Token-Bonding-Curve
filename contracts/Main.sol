// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";

contract Main is ERC1155 {

    uint256 public reserveRatio;
    uint256 public totalSupply;
    uint256 public reserveBalance;
    uint256 public tokenPrice;

    mapping (address => uint256) reserveRatio;

    function buyToken(uint256 ethAmount, uint256 reserveRatio, uint256 tokenSupply, uint256 reserveBalance) public returns (uint256) {
        uint256 tokenAmount = calculatePurchaseReturn(ethAmount, reserveBalance, reserveRatio, tokenSupply);
        require(tokenAmount > 0);
        // transfer ETH to the contract
        require(msg.value == ethAmount);
        // transfer tokens to the buyer
        require(token.transfer(msg.sender, tokenAmount));
        return tokenAmount;
    }

    function calculatePurchaseReturn(uint256 ethAmount, uint256 reserveBalance, uint32 reserveRatio, uint256 tokenSupply) public pure returns (uint256) {
        uint256 baseN = reserveBalance.add(ethAmount);
        uint256 temp = baseN.mul(2).mul(reserveBalance).mul(reserveRatio);
        uint256 baseD = tokenSupply.mul(reserveRatio).add(reserveBalance.mul(2));
        uint256 tokenAmount = temp.div(baseD);
        return tokenAmount;
    }




    mapping(address => uint256) public balances;

    event Buy(address indexed buyer, uint256 amount, uint256 paid);
    event Sell(address indexed seller, uint256 amount, uint256 received);

    constructor(uint256 _reserveRatio) {
        require(_reserveRatio > 0 && _reserveRatio <= 100, "Invalid reserve ratio");
        reserveRatio = _reserveRatio;
    }

    function buy() public payable {
        require(msg.value > 0, "No ether sent");
        uint256 tokens = calculatePurchaseReturn(msg.value);
        require(tokens > 0, "Insufficient tokens to buy");
        balances[msg.sender] += tokens;
        totalSupply += tokens;
        reserveBalance += msg.value;
        tokenPrice = calculateTokenPrice();
        emit Buy(msg.sender, tokens, msg.value);
    }

    function sell(uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than zero");
        require(_amount <= balances[msg.sender], "Insufficient balance to sell");
        uint256 etherAmount = calculateSaleReturn(_amount);
        require(etherAmount > 0, "Insufficient ether to sell");
        balances[msg.sender] -= _amount;
        totalSupply -= _amount;
        reserveBalance -= etherAmount;
        tokenPrice = calculateTokenPrice();
        payable(msg.sender).transfer(etherAmount);
        emit Sell(msg.sender, _amount, etherAmount);
    }

    function calculatePurchaseReturn(uint256 _etherAmount) public view returns (uint256) {
        return calculateTokenReturn(_etherAmount, reserveBalance, totalSupply, reserveRatio);
    }

    function calculateSaleReturn(uint256 _tokenAmount) public view returns (uint256) {
        return calculateEtherReturn(_tokenAmount, reserveBalance, totalSupply, reserveRatio);
    }

    function calculateTokenPrice() internal view returns (uint256) {
        return reserveBalance * 100 / totalSupply;
    }

    function calculateTokenReturn(uint256 _inputAmount, uint256 _inputReserve, uint256 _outputSupply, uint256 _reserveRatio) internal pure returns (uint256) {
        uint256 baseN = _inputReserve + _inputAmount;
        uint256 temp = baseN * _outputSupply;
        uint256 baseD = temp / (_inputReserve * 100 + _inputAmount * _reserveRatio);
        return baseD - _outputSupply;
    }

    function calculateEtherReturn(uint256 _inputAmount, uint256 _inputReserve, uint256 _outputSupply, uint256 _reserveRatio) internal pure returns (uint256) {
        uint256 baseN = _outputSupply + _inputAmount;
        uint256 temp = baseN * _inputReserve * 100;
        uint256 baseD = (_outputSupply + _inputAmount) * _reserveRatio;
        return temp / baseD - _inputReserve;
    }
}

