// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC1155BondingCurveEth} from "../../contracts/ERC1155BondingCurveEth.sol";
import {ERC1155BondingCurveERC20} from "../../contracts/ERC1155BondingCurve.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Minimal cheatcode interface so the test needs no forge-std dependency.
interface Vm {
    function prank(address) external;
    function expectRevert(bytes calldata) external;
    function deal(address, uint256) external;
}

// Run with:
//   forge test --contracts contracts --remappings @openzeppelin/=node_modules/@openzeppelin/
contract AccessControlTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    address constant ATTACKER = address(0xBAD);
    address payable constant SINK = payable(address(0x5151));

    ERC1155BondingCurveEth eth;
    ERC1155BondingCurveERC20 base;

    // The base contract's constructor mints to the deployer, so accept ERC1155 transfers.
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function setUp() public {
        eth = new ERC1155BondingCurveEth();
        base = new ERC1155BondingCurveERC20();
        vm.deal(address(eth), 1 ether);
    }

    function test_deployerIsOwner() public view {
        require(eth.owner() == address(this), "eth owner");
        require(base.owner() == address(this), "base owner");
    }

    function test_strangerCannotDrainEther() public {
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, ATTACKER));
        eth.sendEther(payable(ATTACKER), 1 ether);
        require(address(eth).balance == 1 ether, "balance moved");
    }

    function test_ownerCanSendEther() public {
        eth.sendEther(SINK, 0.4 ether);
        require(SINK.balance == 0.4 ether, "sink not paid");
        require(address(eth).balance == 0.6 ether, "wrong remainder");
    }

    function test_strangerCannotSetMaxGasPrice() public {
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, ATTACKER));
        eth.setMaxGasPrice(0);

        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, ATTACKER));
        base.setMaxGasPrice(0);
    }

    function test_ownerCanSetMaxGasPrice() public {
        eth.setMaxGasPrice(42 gwei);
        base.setMaxGasPrice(7 gwei);
        require(eth.maxGasPrice() == 42 gwei && base.maxGasPrice() == 7 gwei, "not set");
    }
}
