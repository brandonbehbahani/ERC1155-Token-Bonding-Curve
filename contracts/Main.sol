// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./BancorFormula.sol";

contract Main is ERC1155 {

    uint256 public totalTokens = 0;
    struct Token {
        bool isToken; 
        uint256 reserveRatio;
        uint256 totalSupply;
        uint256 reserveBalance;
        uint256 tokenPrice;
    }

    mapping (uint256 => Token) allTokens;

    function createToken(address _userAddress, uint256 _id, uint256 _amount) public payable {
        _mint(_userAddress, _id, _amount, "");
        address(this).transfer(_amount);
        totalTokens++;
        Token storage token;
        token.isToken = true;
        token.

    }

    function mintToken(address _userAddress, uint256 _id, uint256 _amount) public {
        _mint(_userAddress, _id, _amount, "");
        address(this).transfer(_amount);
    }

    function burnToken(address _userAddress, uint256 _id, uint256 _amount) public {
        _burn(_userAddress, _id, _amount, "");
        msg.sender.transfer(_amount);
    }
}

