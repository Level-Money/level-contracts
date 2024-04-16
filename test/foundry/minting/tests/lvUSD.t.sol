// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

/* 
    solhint-disable private-vars-leading-underscore
    solhint-disable contract-name-camelcase
*/

import {stdStorage, StdStorage, Test} from "forge-std/Test.sol";
import {SigUtils} from "../../../utils/SigUtils.sol";
import {Vm} from "forge-std/Vm.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../../../../src/lvUSD.sol";
import "../LevelMinting.utils.sol";

contract lvUSDTest is Test, IlvUSDDefinitions, LevelMintingUtils {
    lvUSD internal _lvusdToken;

    uint256 internal _ownerPrivateKey;
    uint256 internal _newOwnerPrivateKey;
    uint256 internal _minterPrivateKey;
    uint256 internal _newMinterPrivateKey;

    address internal _owner;
    address internal _newOwner;
    address internal _minter;
    address internal _newMinter;

    function setUp() public virtual override {
        _ownerPrivateKey = 0xA11CE;
        _newOwnerPrivateKey = 0xA14CE;
        _minterPrivateKey = 0xB44DE;
        _newMinterPrivateKey = 0xB45DE;

        _owner = vm.addr(_ownerPrivateKey);
        _newOwner = vm.addr(_newOwnerPrivateKey);
        _minter = vm.addr(_minterPrivateKey);
        _newMinter = vm.addr(_newMinterPrivateKey);

        vm.label(_minter, "minter");
        vm.label(_owner, "owner");
        vm.label(_newMinter, "_newMinter");
        vm.label(_newOwner, "newOwner");

        _lvusdToken = new lvUSD(_owner);
        vm.prank(_owner);
        _lvusdToken.setMinter(_minter);
    }

    function testCorrectInitialConfig() public {
        assertEq(_lvusdToken.owner(), _owner);
        assertEq(_lvusdToken.minter(), _minter);
    }

    function testCantInitWithNoOwner() public {
        vm.expectRevert(ZeroAddressExceptionErr);
        new lvUSD(address(0));
    }

    function testOwnershipCannotBeRenounced() public {
        vm.startPrank(_owner);
        vm.expectRevert(OperationNotAllowedErr);
        _lvusdToken.renounceRole(adminRole, _owner);
        vm.stopPrank();
        assertEq(_lvusdToken.owner(), _owner);
        assertNotEq(_lvusdToken.owner(), address(0));
    }

    function testOwnershipTransferRequiresTwoSteps() public {
        vm.prank(_owner);
        _lvusdToken.transferAdmin(_newOwner);
        assertEq(_lvusdToken.owner(), _owner);
        assertNotEq(_lvusdToken.owner(), _newOwner);
    }

    function testCantransferAdmin() public {
        vm.prank(_owner);
        _lvusdToken.transferAdmin(_newOwner);
        vm.prank(_newOwner);
        _lvusdToken.acceptAdmin();
        assertEq(_lvusdToken.owner(), _newOwner);
        assertNotEq(_lvusdToken.owner(), _owner);
    }

    function testCanCancelOwnershipChange() public {
        vm.startPrank(_owner);
        _lvusdToken.transferAdmin(_newOwner);
        _lvusdToken.transferAdmin(address(0));
        vm.stopPrank();

        vm.prank(_newOwner);
        vm.expectRevert();
        _lvusdToken.acceptAdmin();
        assertEq(_lvusdToken.owner(), _owner);
        assertNotEq(_lvusdToken.owner(), _newOwner);
    }

    function testNewOwnerCanPerformOwnerActions() public {
        vm.prank(_owner);
        _lvusdToken.transferAdmin(_newOwner);
        vm.startPrank(_newOwner);
        _lvusdToken.acceptAdmin();
        _lvusdToken.setMinter(_newMinter);
        vm.stopPrank();
        assertEq(_lvusdToken.minter(), _newMinter);
        assertNotEq(_lvusdToken.minter(), _minter);
    }

    function testOnlyOwnerCanSetMinter() public {
        vm.startPrank(_newOwner);
        vm.expectRevert(_getInvalidRoleError(adminRole, _newOwner));
        _lvusdToken.setMinter(_newMinter);
        vm.stopPrank();

        assertEq(_lvusdToken.minter(), _minter);
    }

    function testOwnerCantMint() public {
        vm.prank(_owner);
        vm.expectRevert(OnlyMinterErr);
        _lvusdToken.mint(_newMinter, 100);
    }

    function testMinterCanMint() public {
        assertEq(_lvusdToken.balanceOf(_newMinter), 0);
        vm.prank(_minter);
        _lvusdToken.mint(_newMinter, 100);
        assertEq(_lvusdToken.balanceOf(_newMinter), 100);
    }

    function testMinterCantMintToZeroAddress() public {
        vm.prank(_minter);
        vm.expectRevert("ERC20: mint to the zero address");
        _lvusdToken.mint(address(0), 100);
    }

    function testNewMinterCanMint() public {
        assertEq(_lvusdToken.balanceOf(_newMinter), 0);
        vm.prank(_owner);
        _lvusdToken.setMinter(_newMinter);
        vm.prank(_newMinter);
        _lvusdToken.mint(_newMinter, 100);
        assertEq(_lvusdToken.balanceOf(_newMinter), 100);
    }

    function testOldMinterCantMint() public {
        assertEq(_lvusdToken.balanceOf(_newMinter), 0);
        vm.prank(_owner);
        _lvusdToken.setMinter(_newMinter);
        vm.prank(_minter);
        vm.expectRevert(OnlyMinterErr);
        _lvusdToken.mint(_newMinter, 100);
        assertEq(_lvusdToken.balanceOf(_newMinter), 0);
    }

    function testOldOwnerCanttransferAdmin() public {
        vm.prank(_owner);
        _lvusdToken.transferAdmin(_newOwner);
        vm.prank(_newOwner);
        _lvusdToken.acceptAdmin();
        assertNotEq(_lvusdToken.owner(), _owner);
        assertEq(_lvusdToken.owner(), _newOwner);

        vm.startPrank(_owner);
        vm.expectRevert(_getInvalidRoleError(adminRole, _owner));
        _lvusdToken.transferAdmin(_newMinter);
        vm.stopPrank();

        assertEq(_lvusdToken.owner(), _newOwner);
    }

    function testOldOwnerCantSetMinter() public {
        vm.prank(_owner);
        _lvusdToken.transferAdmin(_newOwner);
        vm.prank(_newOwner);
        _lvusdToken.acceptAdmin();
        assertNotEq(_lvusdToken.owner(), _owner);
        assertEq(_lvusdToken.owner(), _newOwner);

        vm.startPrank(_owner);
        vm.expectRevert(_getInvalidRoleError(adminRole, _owner));
        _lvusdToken.setMinter(_newMinter);
        vm.stopPrank();

        assertEq(_lvusdToken.minter(), _minter);
    }
}
