// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

/* solhint-disable func-name-mixedcase  */

import "../LevelMinting.utils.sol";
import {console2} from "forge-std/console2.sol";
import {AggregatorV3Interface} from "../../../../src/interfaces/AggregatorV3Interface.sol";

// Add this mock oracle contract
contract MockOracle is AggregatorV3Interface {
    int256 private _price;
    uint8 private _decimals;

    constructor(int256 initialPrice, uint8 initialDecimals) {
        _price = initialPrice;
        _decimals = initialDecimals;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function description() external pure returns (string memory) {
        return "Mock Oracle";
    }

    function version() external pure returns (uint256) {
        return 1;
    }

    function getRoundData(
        uint80
    ) external view returns (uint80, int256, uint256, uint256, uint80) {
        return (0, _price, 0, 0, 0);
    }

    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (0, _price, 0, 0, 0);
    }

    // Function to update the price (for testing purposes)
    function updatePrice(int256 newPrice) external {
        _price = newPrice;
    }
}

contract LevelMintingCoreTest is LevelMintingUtils {
    MockOracle public mockOracle;

    function setUp() public override {
        super.setUp();
        // Deploy mock oracle
        mockOracle = new MockOracle(1e8, 8); // 1:1 price ratio with 8 decimals

        // Add oracle for stETH
        vm.prank(owner);
        LevelMintingContract.addOracle(
            address(stETHToken),
            address(mockOracle)
        );
    }

    function test__mint() public {
        executeMint();
    }

    function test_redeem() public {
        executeRedeem();
        assertEq(
            stETHToken.balanceOf(address(LevelMintingContract)),
            0,
            "Mismatch in stETH balance"
        );
        assertEq(
            stETHToken.balanceOf(beneficiary),
            _stETHToDeposit,
            "Mismatch in stETH balance"
        );
        assertEq(
            lvlusdToken.balanceOf(beneficiary),
            0,
            "Mismatch in lvlUSD balance"
        );
    }

    function test_initiate_and_complete_redeem() public {
        vm.prank(owner);
        LevelMintingContract.setMaxRedeemPerBlock(type(uint256).max);
        ILevelMinting.Order memory redeemOrder = redeem_setup(
            50 wei,
            50 wei,
            1,
            false
        );
        vm.prank(owner);
        LevelMintingContract.grantRole(redeemerRole, beneficiary);
        vm.stopPrank();

        (
            ILevelMinting.Order memory mintOrder,
            ILevelMinting.Route memory route
        ) = mint_setup(500 wei, 500 wei, 107, false);
        ILevelMinting.Order memory order = ILevelMinting.Order({
            order_type: ILevelMinting.OrderType.MINT,
            nonce: 102,
            benefactor: beneficiary,
            beneficiary: beneficiary,
            collateral_asset: address(stETHToken),
            lvlusd_amount: 5000 wei,
            collateral_amount: 50 wei
        });
        stETHToken.mint(50000 wei, beneficiary);
        LevelMintingContract.mint(order, route);

        vm.startPrank(beneficiary);
        LevelMintingContract.initiateRedeem(redeemOrder);
        vm.warp(8 days);
        uint bal = stETHToken.balanceOf(beneficiary);
        LevelMintingContract.completeRedeem(redeemOrder.collateral_asset);
        uint new_val = stETHToken.balanceOf(beneficiary);
        assertEq(new_val - bal, 50 wei);
        vm.stopPrank();
    }

    function test_initiate_and_complete_redeem_min_collateral_not_met_revert()
        public
    {
        vm.prank(owner);
        LevelMintingContract.setMaxRedeemPerBlock(type(uint256).max);
        ILevelMinting.Order memory redeemOrder = redeem_setup(
            50 wei,
            51 wei,
            1,
            false
        );
        vm.prank(owner);
        LevelMintingContract.grantRole(redeemerRole, beneficiary);
        vm.stopPrank();
        (
            ILevelMinting.Order memory mintOrder,
            ILevelMinting.Route memory route
        ) = mint_setup(500 wei, 500 wei, 107, false);
        ILevelMinting.Order memory order = ILevelMinting.Order({
            order_type: ILevelMinting.OrderType.MINT,
            nonce: 102,
            benefactor: beneficiary,
            beneficiary: beneficiary,
            collateral_asset: address(stETHToken),
            lvlusd_amount: 5000 wei,
            collateral_amount: 50 wei
        });
        stETHToken.mint(50000 wei, beneficiary);
        LevelMintingContract.mint(order, route);

        vm.startPrank(beneficiary);
        LevelMintingContract.initiateRedeem(redeemOrder);
        vm.warp(8 days);
        uint bal = stETHToken.balanceOf(beneficiary);
        vm.expectRevert(MinimumCollateralAmountNotMet);
        LevelMintingContract.completeRedeem(redeemOrder.collateral_asset);
        vm.stopPrank();
    }

    function test_initiate_and_complete_redeem_insufficient_cooldown_revert()
        public
    {
        vm.prank(owner);
        LevelMintingContract.setMaxRedeemPerBlock(type(uint256).max);
        ILevelMinting.Order memory redeemOrder = redeem_setup(
            50 wei,
            50 wei,
            1,
            false
        );
        (
            ILevelMinting.Order memory mintOrder,
            ILevelMinting.Route memory route
        ) = mint_setup(50 wei, 50 wei, 107, false);
        ILevelMinting.Order memory order = ILevelMinting.Order({
            order_type: ILevelMinting.OrderType.MINT,
            nonce: 102,
            benefactor: beneficiary,
            beneficiary: beneficiary,
            collateral_asset: address(stETHToken),
            lvlusd_amount: 50 wei,
            collateral_amount: 50 wei
        });
        stETHToken.mint(50 wei, beneficiary);
        LevelMintingContract.mint(order, route);

        vm.prank(owner);
        LevelMintingContract.grantRole(redeemerRole, beneficiary);
        vm.stopPrank();
        vm.startPrank(beneficiary);
        LevelMintingContract.initiateRedeem(redeemOrder);
        vm.warp(6 days); // not enough time as passed!
        vm.expectRevert(InvalidCooldown);
        LevelMintingContract.completeRedeem(redeemOrder.collateral_asset);
        vm.stopPrank();
    }

    function test_redeem_invalidNonce_revert() public {
        // Unset the max redeem per block limit
        vm.prank(owner);
        LevelMintingContract.setMaxRedeemPerBlock(type(uint256).max);

        ILevelMinting.Order memory redeemOrder = redeem_setup(
            _lvlusdToMint,
            _stETHToDeposit,
            1,
            false
        );

        vm.startPrank(redeemer);
        LevelMintingContract.redeem(redeemOrder);

        vm.expectRevert(InvalidNonce);
        LevelMintingContract.redeem(redeemOrder);
    }

    function test_nativeEth_withdraw() public {
        vm.deal(address(LevelMintingContract), _stETHToDeposit);

        ILevelMinting.Order memory order = ILevelMinting.Order({
            order_type: ILevelMinting.OrderType.MINT,
            nonce: 8,
            benefactor: benefactor,
            beneficiary: benefactor,
            collateral_asset: address(stETHToken),
            collateral_amount: _stETHToDeposit,
            lvlusd_amount: _lvlusdToMint
        });

        address[] memory targets = new address[](1);
        targets[0] = address(LevelMintingContract);

        uint256[] memory ratios = new uint256[](1);
        ratios[0] = 10_000;

        ILevelMinting.Route memory route = ILevelMinting.Route({
            addresses: targets,
            ratios: ratios
        });

        // taker
        vm.startPrank(benefactor);
        stETHToken.approve(address(LevelMintingContract), _stETHToDeposit);

        vm.stopPrank();

        assertEq(lvlusdToken.balanceOf(benefactor), 0);

        vm.recordLogs();
        vm.prank(minter);
        LevelMintingContract.mint(order, route);
        vm.getRecordedLogs();

        assertEq(lvlusdToken.balanceOf(benefactor), _lvlusdToMint);

        //redeem
        ILevelMinting.Order memory redeemOrder = ILevelMinting.Order({
            order_type: ILevelMinting.OrderType.REDEEM,
            nonce: 800,
            benefactor: benefactor,
            beneficiary: benefactor,
            collateral_asset: address(stETHToken),
            lvlusd_amount: _lvlusdToMint,
            collateral_amount: _stETHToDeposit
        });

        // taker
        vm.startPrank(benefactor);
        lvlusdToken.approve(address(LevelMintingContract), _lvlusdToMint);

        vm.stopPrank();

        vm.startPrank(redeemer);
        LevelMintingContract.redeem(redeemOrder);

        assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit);
        assertEq(lvlusdToken.balanceOf(benefactor), 0);

        vm.stopPrank();
    }

    function test_fuzz_mint_noSlippage(uint256 expectedAmount) public {
        vm.assume(expectedAmount > 0 && expectedAmount < _maxMintPerBlock);
        (
            ILevelMinting.Order memory order,
            ILevelMinting.Route memory route
        ) = mint_setup(expectedAmount, _stETHToDeposit, 1, false);

        vm.recordLogs();
        vm.prank(minter);
        LevelMintingContract.mint(order, route);
        vm.getRecordedLogs();
        assertEq(stETHToken.balanceOf(benefactor), 0);
        assertEq(
            stETHToken.balanceOf(address(LevelMintingContract)),
            _stETHToDeposit
        );
        assertEq(lvlusdToken.balanceOf(beneficiary), expectedAmount);
    }

    function test_multipleValid_reserveRatios_addresses() public {
        uint256 _smallUsdeToMint = 1.75 * 10 ** 23;
        ILevelMinting.Order memory order = ILevelMinting.Order({
            order_type: ILevelMinting.OrderType.MINT,
            nonce: 14,
            benefactor: benefactor,
            beneficiary: beneficiary,
            collateral_asset: address(stETHToken),
            collateral_amount: _stETHToDeposit,
            lvlusd_amount: _smallUsdeToMint
        });

        address[] memory targets = new address[](3);
        targets[0] = address(LevelMintingContract);
        targets[1] = reserve1;
        targets[2] = reserve2;

        uint256[] memory ratios = new uint256[](3);
        ratios[0] = 3_000;
        ratios[1] = 4_000;
        ratios[2] = 3_000;

        ILevelMinting.Route memory route = ILevelMinting.Route({
            addresses: targets,
            ratios: ratios
        });

        // taker
        vm.startPrank(benefactor);
        stETHToken.approve(address(LevelMintingContract), _stETHToDeposit);

        vm.stopPrank();

        assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit);

        vm.prank(minter);
        vm.expectRevert(InvalidRoute);
        LevelMintingContract.mint(order, route);

        vm.prank(owner);
        LevelMintingContract.addReserveAddress(reserve2);

        vm.prank(minter);
        LevelMintingContract.mint(order, route);

        assertEq(stETHToken.balanceOf(benefactor), 0);
        assertEq(lvlusdToken.balanceOf(beneficiary), _smallUsdeToMint);

        assertEq(
            stETHToken.balanceOf(address(reserve1)),
            (_stETHToDeposit * 4) / 10
        );
        assertEq(
            stETHToken.balanceOf(address(reserve2)),
            (_stETHToDeposit * 3) / 10
        );
        assertEq(
            stETHToken.balanceOf(address(LevelMintingContract)),
            (_stETHToDeposit * 3) / 10
        );

        // remove reserve and expect reversion
        vm.prank(owner);
        LevelMintingContract.removeReserveAddress(reserve2);

        vm.prank(minter);
        vm.expectRevert(InvalidRoute);
        LevelMintingContract.mint(order, route);
    }

    function test_fuzz_multipleInvalid_reserveRatios_revert(
        uint256 ratio1
    ) public {
        ratio1 = bound(ratio1, 0, UINT256_MAX - 7_000);
        vm.assume(ratio1 != 3_000);

        ILevelMinting.Order memory mintOrder = ILevelMinting.Order({
            order_type: ILevelMinting.OrderType.MINT,
            nonce: 15,
            benefactor: benefactor,
            beneficiary: beneficiary,
            collateral_asset: address(stETHToken),
            collateral_amount: _stETHToDeposit,
            lvlusd_amount: _lvlusdToMint
        });

        address[] memory targets = new address[](2);
        targets[0] = address(LevelMintingContract);
        targets[1] = owner;

        uint256[] memory ratios = new uint256[](2);
        ratios[0] = ratio1;
        ratios[1] = 7_000;

        ILevelMinting.Route memory route = ILevelMinting.Route({
            addresses: targets,
            ratios: ratios
        });

        vm.startPrank(benefactor);
        stETHToken.approve(address(LevelMintingContract), _stETHToDeposit);

        vm.stopPrank();

        assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit);

        vm.expectRevert(InvalidRoute);
        vm.prank(minter);
        LevelMintingContract.mint(mintOrder, route);

        assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit);
        assertEq(lvlusdToken.balanceOf(beneficiary), 0);

        assertEq(stETHToken.balanceOf(address(LevelMintingContract)), 0);
        assertEq(stETHToken.balanceOf(owner), 0);
    }

    function test_fuzz_singleInvalid_reserveRatio_revert(
        uint256 ratio1
    ) public {
        vm.assume(ratio1 != 10_000);

        ILevelMinting.Order memory order = ILevelMinting.Order({
            order_type: ILevelMinting.OrderType.MINT,
            nonce: 16,
            benefactor: benefactor,
            beneficiary: beneficiary,
            collateral_asset: address(stETHToken),
            collateral_amount: _stETHToDeposit,
            lvlusd_amount: _lvlusdToMint
        });

        address[] memory targets = new address[](1);
        targets[0] = address(LevelMintingContract);

        uint256[] memory ratios = new uint256[](1);
        ratios[0] = ratio1;

        ILevelMinting.Route memory route = ILevelMinting.Route({
            addresses: targets,
            ratios: ratios
        });

        // taker
        vm.startPrank(benefactor);
        stETHToken.approve(address(LevelMintingContract), _stETHToDeposit);

        vm.stopPrank();

        assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit);

        vm.expectRevert(InvalidRoute);
        vm.prank(minter);
        LevelMintingContract.mint(order, route);

        assertEq(stETHToken.balanceOf(benefactor), _stETHToDeposit);
        assertEq(lvlusdToken.balanceOf(beneficiary), 0);

        assertEq(stETHToken.balanceOf(address(LevelMintingContract)), 0);
    }

    function test_unsupported_assets_ERC20_revert() public {
        vm.startPrank(owner);
        LevelMintingContract.removeSupportedAsset(address(stETHToken));
        stETHToken.mint(_stETHToDeposit, benefactor);
        vm.stopPrank();

        ILevelMinting.Order memory order = ILevelMinting.Order({
            order_type: ILevelMinting.OrderType.MINT,
            nonce: 18,
            benefactor: benefactor,
            beneficiary: beneficiary,
            collateral_asset: address(stETHToken),
            collateral_amount: _stETHToDeposit,
            lvlusd_amount: _lvlusdToMint
        });

        address[] memory targets = new address[](1);
        targets[0] = address(LevelMintingContract);

        uint256[] memory ratios = new uint256[](1);
        ratios[0] = 10_000;

        ILevelMinting.Route memory route = ILevelMinting.Route({
            addresses: targets,
            ratios: ratios
        });

        // taker
        vm.startPrank(benefactor);
        stETHToken.approve(address(LevelMintingContract), _stETHToDeposit);

        vm.stopPrank();

        vm.recordLogs();
        vm.expectRevert(UnsupportedAsset);
        vm.prank(minter);
        LevelMintingContract.mint(order, route);
        vm.getRecordedLogs();
    }

    function test_unsupported_assets_ETH_revert() public {
        vm.startPrank(owner);
        vm.deal(benefactor, _stETHToDeposit);
        vm.stopPrank();

        ILevelMinting.Order memory order = ILevelMinting.Order({
            order_type: ILevelMinting.OrderType.MINT,
            nonce: 19,
            benefactor: benefactor,
            beneficiary: beneficiary,
            collateral_asset: address(token),
            collateral_amount: _stETHToDeposit,
            lvlusd_amount: _lvlusdToMint
        });

        address[] memory targets = new address[](1);
        targets[0] = address(LevelMintingContract);

        uint256[] memory ratios = new uint256[](1);
        ratios[0] = 10_000;

        ILevelMinting.Route memory route = ILevelMinting.Route({
            addresses: targets,
            ratios: ratios
        });

        // taker
        vm.startPrank(benefactor);
        stETHToken.approve(address(LevelMintingContract), _stETHToDeposit);

        vm.stopPrank();

        vm.recordLogs();
        vm.expectRevert(UnsupportedAsset);
        vm.prank(minter);
        LevelMintingContract.mint(order, route);
        vm.getRecordedLogs();
    }

    function test_add_and_remove_supported_asset() public {
        address asset = address(20);
        vm.expectEmit(true, false, false, false);
        emit AssetAdded(asset);
        vm.startPrank(owner);
        LevelMintingContract.addSupportedAsset(asset);
        assertTrue(LevelMintingContract.isSupportedAsset(asset));

        vm.expectEmit(true, false, false, false);
        emit AssetRemoved(asset);
        LevelMintingContract.removeSupportedAsset(asset);
        assertFalse(LevelMintingContract.isSupportedAsset(asset));
    }

    function test_cannot_add_asset_already_supported_revert() public {
        address asset = address(20);
        vm.expectEmit(true, false, false, false);
        emit AssetAdded(asset);
        vm.startPrank(owner);
        LevelMintingContract.addSupportedAsset(asset);
        assertTrue(LevelMintingContract.isSupportedAsset(asset));

        vm.expectRevert(InvalidAssetAddress);
        LevelMintingContract.addSupportedAsset(asset);
    }

    function test_cannot_removeAsset_not_supported_revert() public {
        address asset = address(20);
        assertFalse(LevelMintingContract.isSupportedAsset(asset));

        vm.prank(owner);
        vm.expectRevert(InvalidAssetAddress);
        LevelMintingContract.removeSupportedAsset(asset);
    }

    function test_cannotAdd_addressZero_revert() public {
        vm.prank(owner);
        vm.expectRevert(InvalidAssetAddress);
        LevelMintingContract.addSupportedAsset(address(0));
    }

    function test_cannotAdd_lvlUSD_revert() public {
        vm.prank(owner);
        vm.expectRevert(InvalidAssetAddress);
        LevelMintingContract.addSupportedAsset(address(lvlusdToken));
    }

    function test_sending_redeem_order_to_mint_revert() public {
        ILevelMinting.Order memory order = redeem_setup(
            1 ether,
            50 ether,
            20,
            false
        );

        address[] memory targets = new address[](1);
        targets[0] = address(LevelMintingContract);

        uint256[] memory ratios = new uint256[](1);
        ratios[0] = 10_000;

        ILevelMinting.Route memory route = ILevelMinting.Route({
            addresses: targets,
            ratios: ratios
        });

        vm.expectRevert(InvalidOrder);
        vm.prank(minter);
        LevelMintingContract.mint(order, route);
    }

    function test_mismatchedAddressesAndRatios_revert() public {
        uint256 _smallUsdeToMint = 1.75 * 10 ** 23;
        (
            ILevelMinting.Order memory order,
            ILevelMinting.Route memory route
        ) = mint_setup(_smallUsdeToMint, _stETHToDeposit, 1, false);

        address[] memory targets = new address[](3);
        targets[0] = address(LevelMintingContract);
        targets[1] = reserve1;
        targets[2] = reserve2;

        uint256[] memory ratios = new uint256[](2);
        ratios[0] = 3_000;
        ratios[1] = 4_000;

        route = ILevelMinting.Route({addresses: targets, ratios: ratios});

        vm.recordLogs();
        vm.prank(minter);
        vm.expectRevert(InvalidRoute);
        LevelMintingContract.mint(order, route);
    }
}
