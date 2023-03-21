// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";

contract Main {
    ERC1155 public erc1155;


    function createNewToken(uint256 amount, uint256 id) public {

    }
    

    function mint(uint256 amount) public {
        // empty function for now
        address user = address(msg.sender);



    }

    function burn(uint256 amount) public {
        // empty function for now
        address user = address(msg.sender);
    }


}
