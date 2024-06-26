// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./BancorFormula.sol";
import "./Owned.sol";

contract Main is ERC1155, BancorFormula, Owned {


    uint256 public totalTokens = 0;

    uint256 public maxGasPrice = 1 * 10**18;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

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

    function mint(uint256 _amount, uint256 id) public {
        _curvedMint(_amount, id);
    }

    function burn(uint256 _amount, uint256 id) public
        returns (uint256)
    {
        return _curvedBurn(_amount, id);
    }

    function setBaseMetadataURI(string memory _baseUri) public {
        _setURI(_baseUri); 
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the ERC].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the values in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
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
    function setMaxGasPrice(uint256 newPrice) public onlyOwner {
        maxGasPrice = newPrice;
    }

    // verifies that the gas price is lower than the universal limit
    modifier validGasPrice() {
        require(tx.gasprice <= maxGasPrice, "Gas price must be <= maximum gas price to prevent front running attacks.");
        _;
    }

    modifier validBurn(uint256 amount, uint256 id) {
        require(amount > 0 && balanceOf[msg.sender][id] >= amount);
        _;
    }

    modifier validMint(uint256 amount) {
        require(amount > 0);
        _;
    }    

    
}

