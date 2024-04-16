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

contract lvUSDDenylistTest is Test, IlvUSDDefinitions, LevelMintingUtils {
    lvUSD internal _lvusdToken;

    uint256 internal _ownerPrivateKey;
    uint256 internal _newOwnerPrivateKey;
    uint256 internal _minterPrivateKey;
    uint256 internal _newMinterPrivateKey;

    address internal _owner;
    address internal _newOwner;
    address internal _minter;
    address internal _newMinter;
    address internal _denylister;

    address internal _denylisted;

    function setUp() public virtual override {
        _ownerPrivateKey = 0xA11CE;
        _newOwnerPrivateKey = 0xA14CE;
        _minterPrivateKey = 0xB44DE;
        _newMinterPrivateKey = 0xB45DE;

        _owner = vm.addr(_ownerPrivateKey);
        _newOwner = vm.addr(_newOwnerPrivateKey);
        _minter = vm.addr(_minterPrivateKey);
        _newMinter = vm.addr(_newMinterPrivateKey);
        _denylister = _owner;

        _denylisted = vm.addr(0xC0FFEE);

        vm.label(_minter, "minter");
        vm.label(_owner, "owner");
        vm.label(_newMinter, "_newMinter");
        vm.label(_newOwner, "newOwner");

        _lvusdToken = new lvUSD(_owner);
        vm.prank(_owner);
        _lvusdToken.setMinter(_minter);
    }

    function testDenylisterCannotBeRenounced() public {
        vm.startPrank(_owner);
        vm.expectRevert(OperationNotAllowedErr);
        _lvusdToken.renounceRole(denylisterRole, _owner);
        vm.stopPrank();
        assertEq(_lvusdToken.owner(), _owner);
        assertNotEq(_lvusdToken.owner(), address(0));
    }

    function testOnlyDenylisterCanDenylist() public {
        assertEq(_lvusdToken.denylisted(_denylisted), false);

        vm.prank(_denylister);
        _lvusdToken.addToDenylist(_denylisted);

        assertEq(_lvusdToken.denylisted(_denylisted), true);

        vm.prank(_denylisted);
        vm.expectRevert(_getInvalidRoleError(denylisterRole, _denylisted));
        _lvusdToken.addToDenylist(_minter);
    }

    function testOnlyDenylisterCanRemoveFromDenylist() public {
        assertEq(_lvusdToken.denylisted(_denylisted), false);

        vm.prank(_denylister);
        _lvusdToken.addToDenylist(_denylisted);
        assertEq(_lvusdToken.denylisted(_denylisted), true);

        vm.prank(_denylisted);
        vm.expectRevert(_getInvalidRoleError(denylisterRole, _denylisted));
        _lvusdToken.removeFromDenylist(_minter);

        vm.prank(_denylister);
        _lvusdToken.removeFromDenylist(_denylisted);
        assertEq(_lvusdToken.denylisted(_denylisted), false);
    }

    function cannotAddOwnerToDenylist() public {
        vm.prank(_denylister);
        vm.expectRevert(IsOwnerErr);
        _lvusdToken.addToDenylist(_owner);
    }

    function testDenylistPreventMinting() public {
        assertEq(_lvusdToken.denylisted(_denylisted), false);

        vm.prank(_denylister);
        _lvusdToken.addToDenylist(_denylisted);

        vm.prank(_minter);
        vm.expectRevert(DenylistedErr);
        _lvusdToken.mint(_denylisted, 100);
    }

    function testDenylistPreventsTransfersFrom() public {
        vm.prank(_minter);
        _lvusdToken.mint(_denylisted, 100);

        assertEq(_lvusdToken.balanceOf(_denylisted), 100);

        vm.prank(_denylister);
        _lvusdToken.addToDenylist(_denylisted);

        vm.prank(_denylisted);
        vm.expectRevert(DenylistedErr);
        _lvusdToken.transfer(_owner, 100);
    }

    function testDenylistPreventsTransfersTo() public {
        vm.prank(_minter);
        _lvusdToken.mint(_minter, 100);

        assertEq(_lvusdToken.balanceOf(_minter), 100);

        vm.prank(_denylister);
        _lvusdToken.addToDenylist(_denylisted);

        vm.prank(_minter);
        vm.expectRevert(DenylistedErr);
        _lvusdToken.transfer(_denylisted, 100);
    }
}
