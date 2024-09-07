// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

/* solhint-disable func-name-mixedcase  */
import "../minting/MintingBaseSetup.sol";

contract LevelReserveManagerTest is MintingBaseSetup {
    function setUp() public override {
        super.setUp();
        vm.startPrank(owner);
        levelReserveManager.approveSpender(
            address(USDCToken),
            address(LevelMintingContract),
            100000000000
        );
    }

    function test_deposit_to_level_minting() public {
        vm.startPrank(owner);
        levelReserveManager.depositToLevelMinting(address(USDCToken), 1000000);
        assertEq(
            USDCToken.balanceOf(address(LevelMintingContract)),
            1000000,
            "Incorrect LevelMintingContract balance."
        );
    }

    function test_transfer_erc20() public {
        vm.startPrank(owner);
        levelReserveManager.addToAllowList(bob);
        //levelReserveManager.mintlvlUSD(address(USDCToken), 1000000);
        levelReserveManager.transferERC20(address(USDCToken), bob, 999);
        assertEq(USDCToken.balanceOf(bob), 999, "Incorrect USDCToken balance.");
    }

    function test_transfer_erc20_reverts() public {
        vm.startPrank(owner);
        // levelReserveManager.mintlvlUSD(address(USDCToken), 1000000);
        vm.expectRevert();
        levelReserveManager.transferERC20(address(USDCToken), bob, 999);
    }
}
