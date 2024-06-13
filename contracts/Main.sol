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

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "AdminRole: caller does not have the Admin role");
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    function mintToken(address _userAddress, uint256 _id, uint256 _amount) public {
        _mint(_userAddress, _id, _amount, "");
    }

    /**
    * @dev Mint tokens
    *
    * @param amount Amount of tokens to deposit
    */
    function curvedMint(uint256 _id, uint256 amount) public returns (uint256) {
        require(safeTransferFrom(msg.sender, address(this), 0, amount));
        poolBalances[_id] = poolBalances[_id].add(amount);
        super._curvedMint(_id, amount);
    }

    /**
    * @dev Burn tokens
    *
    * @param amount Amount of tokens to deposit
    */
    function curvedBurn(uint256 _id, uint256 amount) public returns (uint256) {
        require(safeTransferFrom(msg.sender, address(this), 0, amount));
        poolBalances[_id] = poolBalances[_id].add(amount);
        super._curvedBurn(_id, amount);
    }

    function createNewToken(uint32 _reserveRatio, uint256 _initialSupply, uint256 _initialPoolBalance)public returns (uint256 id){
        require(_reserveRatio > 0 && _initialSupply > 0 && _initialPoolBalance > 0, "Initial values must not be zero");
        totalTokens++;
        calculatePurchaseReturn(totalSupplies[totalTokens], poolBalances[totalTokens], reserveRatios[totalTokens], _initialPoolBalance);
        poolBalances[totalTokens] = _initialPoolBalance;
        totalSupplies[totalTokens] = _initialSupply;
        reserveRatios[totalTokens] = _reserveRatio;
    }

    function setBaseMetadataURI(string memory _baseUri) public onlyAdmin {
        _setBaseMetadataURI(_baseUri); 
    }


}

