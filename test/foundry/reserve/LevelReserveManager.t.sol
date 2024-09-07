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
        levelReserveManager.approveSpender(
            address(lvlusdToken),
            address(stakedlvlUSD),
            100000000000
        );
    }

    function test_mint_collateral_lvlusd_differing_decimals() public {
        levelReserveManager.mintlvlUSD(address(USDCToken), 1000000);
        assertEq(
            lvlusdToken.balanceOf(address(levelReserveManager)),
            1000000000000000000,
            "Incorrect reserve lvlUSD balance."
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

    function test_deposit_to_staked_lvlusd() public {
        vm.startPrank(owner);
        stakedlvlUSD.grantRole(
            keccak256("REWARDER_ROLE"),
            address(levelReserveManager)
        );
        levelReserveManager.mintlvlUSD(address(USDCToken), 1000000);
        levelReserveManager.depositToStakedlvlUSD(1000000000);
        assertEq(
            lvlusdToken.balanceOf(address(stakedlvlUSD)),
            1000000000,
            "Incorrect StakedlvlUSD balance."
        );
    }

    function test_transfer_erc20() public {
        vm.startPrank(owner);
        levelReserveManager.addToAllowList(bob);
        stakedlvlUSD.grantRole(
            keccak256("REWARDER_ROLE"),
            address(levelReserveManager)
        );
        levelReserveManager.mintlvlUSD(address(USDCToken), 1000000);
        levelReserveManager.transferERC20(address(USDCToken), bob, 999);
        assertEq(USDCToken.balanceOf(bob), 999, "Incorrect USDCToken balance.");
    }

    function test_transfer_erc20_reverts() public {
        vm.startPrank(owner);
        stakedlvlUSD.grantRole(
            keccak256("REWARDER_ROLE"),
            address(levelReserveManager)
        );
        levelReserveManager.mintlvlUSD(address(USDCToken), 1000000);
        vm.expectRevert();
        levelReserveManager.transferERC20(address(USDCToken), bob, 999);
    }
}