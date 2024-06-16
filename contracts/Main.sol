// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./BancorFormula.sol";
import "./Owned.sol";

contract Main is ERC1155, BancorFormula, Owned {


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

    event CurvedMint(address sender, uint256 amount, uint256 deposit, uint256 id);
    event CurvedBurn(address sender, uint256 amount, uint256 reimbursement, uint256 id);

    function mintToken(address _userAddress, uint256 _id, uint256 _amount) public {
        _mint(_userAddress, _id, _amount, "");
    }

    function createNewToken(uint32 _reserveRatio, uint256 _initialSupply, uint256 _initialPoolBalance)public returns (uint256 id){
        require(_reserveRatio > 0 && _initialSupply > 0 && _initialPoolBalance > 0, "Initial values must not be zero");
        poolBalances[totalTokens] = _initialPoolBalance;
        totalSupplies[totalTokens] = _initialSupply;
        reserveRatios[totalTokens] = _reserveRatio;
        calculatePurchaseReturn(totalSupplies[totalTokens], poolBalances[totalTokens], reserveRatios[totalTokens], _initialPoolBalance);
        totalTokens++;
    }

    // --- PUBLIC FUNCTIONS: ---

    function mint(uint256 _amount) public {
        _curvedMint(_amount);
    }

    function burn(uint256 _amount) public
        returns (uint256)
    {
        return _curvedBurn(_amount);
    }

    function setBaseMetadataURI(string memory _baseUri) public {
        _setBaseMetadataURI(_baseUri); 
    }

     function calculateCurvedMintReturn(uint256 amount, uint256 id) public view returns (uint256) {
    return calculatePurchaseReturn(totalSupplies[id], poolBalance(), reserveRatio, amount);
    }

    function calculateCurvedBurnReturn(uint256 amount, uint256 id) public view returns (uint256) {
        return calculateSaleReturn(totalSupplies[id], poolBalance(), reserveRatio, amount);
    }

    /**
    * @dev Mint tokens
    */
    function _curvedMint(uint256 deposit) internal returns (uint256) {
        return _curvedMintFor(msg.sender, deposit);
    }

    function _curvedMintFor(address user, uint256 deposit)
        validGasPrice
        validMint(deposit)
        internal
        returns (uint256)
    {
        uint256 amount = calculateCurvedMintReturn(deposit);
        _mint(user, amount);
        emit CurvedMint(user, amount, deposit);
        return amount;
    }

    /**
    * @dev Burn tokens
    * @param amount Amount of tokens to withdraw
    */
    function _curvedBurn(uint256 amount) internal returns (uint256) {
        return _curvedBurnFor(msg.sender, amount);
    }

    function _curvedBurnFor(address user, uint256 amount) validGasPrice validBurn(amount) internal returns (uint256) {
        uint256 reimbursement = calculateCurvedBurnReturn(amount);
        _burn(user, amount);
        emit CurvedBurn(user, amount, reimbursement);
        return reimbursement;
    }

    /**
        @dev Allows the owner to update the gas price limit
        @param _gasPrice The new gas price limit
    */
    function _setGasPrice(uint256 _gasPrice) internal {
        require(_gasPrice > 0);
        gasPrice = _gasPrice;
    }

    // verifies that the gas price is lower than the universal limit
    modifier validGasPrice() {
        assert(tx.gasprice <= gasPrice);
        _;
    }

    modifier validBurn(uint256 amount) {
        require(amount > 0 && balanceOf(msg.sender) >= amount);
        _;
    }

    modifier validMint(uint256 amount) {
        require(amount > 0);
        _;
    }
}

