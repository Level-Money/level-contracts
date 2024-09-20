// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

/* solhint-disable private-vars-leading-underscore  */
/* solhint-disable func-name-mixedcase  */
/* solhint-disable var-name-mixedcase  */

import {stdStorage, StdStorage, Test} from "forge-std/Test.sol";
import {SigUtils} from "../../utils/SigUtils.sol";
import {Vm} from "forge-std/Vm.sol";
import {Utils} from "../../utils/Utils.sol";

import "../../mocks/MockToken.sol";
import "../../../src/lvlUSD.sol";
import "../../../src/LevelReserveManager.sol";
import "../../../src/interfaces/ILevelMinting.sol";
import "../../../src/interfaces/ILevelMintingEvents.sol";
import "../../../src/interfaces/ILevelReserveManager.sol";
import "./LevelMintingChild.sol";
import "../../../src/interfaces/ISingleAdminAccessControl.sol";
import "../../../src/interfaces/IlvlUSDDefinitions.sol";

contract MintingBaseSetup is Test, ILevelMintingEvents, IlvlUSDDefinitions {
    Utils internal utils;
    lvlUSD internal lvlusdToken;
    LevelReserveManager internal levelReserveManager;
    MockToken internal stETHToken;
    MockToken internal cbETHToken;
    MockToken internal rETHToken;
    MockToken internal USDCToken;
    MockToken internal USDTToken;
    MockToken internal token;
    LevelMintingChild internal LevelMintingContract;
    SigUtils internal sigUtils;
    SigUtils internal sigUtilslvlUSD;

    uint256 internal ownerPrivateKey;
    uint256 internal newOwnerPrivateKey;
    uint256 internal minterPrivateKey;
    uint256 internal redeemerPrivateKey;
    uint256 internal maker1PrivateKey;
    uint256 internal maker2PrivateKey;
    uint256 internal benefactorPrivateKey;
    uint256 internal beneficiaryPrivateKey;
    uint256 internal trader1PrivateKey;
    uint256 internal trader2PrivateKey;
    uint256 internal gatekeeperPrivateKey;
    uint256 internal bobPrivateKey;
    uint256 internal reserve1PrivateKey;
    uint256 internal reserve2PrivateKey;
    uint256 internal randomerPrivateKey;
    address internal poolAddressesProvider;

    address internal owner;
    address internal newOwner;
    address internal minter;
    address internal redeemer;
    address internal benefactor;
    address internal beneficiary;
    address internal maker1;
    address internal maker2;
    address internal trader1;
    address internal trader2;
    address internal gatekeeper;
    address internal bob;
    address internal reserve1;
    address internal reserve2;
    address internal randomer;

    address[] assets;
    address[] reserves;
    uint256[] ratios;

    address internal NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // Roles references
    bytes32 internal minterRole = keccak256("MINTER_ROLE");
    bytes32 internal gatekeeperRole = keccak256("GATEKEEPER_ROLE");
    bytes32 internal adminRole = 0x00;
    bytes32 internal redeemerRole = keccak256("REDEEMER_ROLE");

    bytes32 internal denylisterRole = keccak256("DENYLIST_MANAGER_ROLE");

    // error encodings
    bytes internal InvalidCooldown =
        abi.encodeWithSelector(ILevelMinting.InvalidCooldown.selector);
    bytes internal MinimumCollateralAmountNotMet =
        abi.encodeWithSelector(
            ILevelMinting.MinimumCollateralAmountNotMet.selector
        );
    bytes internal Duplicate =
        abi.encodeWithSelector(ILevelMinting.Duplicate.selector);
    bytes internal InvalidAddress =
        abi.encodeWithSelector(ILevelMinting.InvalidAddress.selector);
    bytes internal InvalidlvlUSDAddress =
        abi.encodeWithSelector(ILevelMinting.InvalidlvlUSDAddress.selector);
    bytes internal InvalidAssetAddress =
        abi.encodeWithSelector(ILevelMinting.InvalidAssetAddress.selector);
    bytes internal InvalidOrder =
        abi.encodeWithSelector(ILevelMinting.InvalidOrder.selector);
    bytes internal InvalidAffirmedAmount =
        abi.encodeWithSelector(ILevelMinting.InvalidAffirmedAmount.selector);
    bytes internal InvalidAmount =
        abi.encodeWithSelector(ILevelMinting.InvalidAmount.selector);
    bytes internal InvalidRoute =
        abi.encodeWithSelector(ILevelMinting.InvalidRoute.selector);
    bytes internal InvalidAdminChange =
        abi.encodeWithSelector(
            ISingleAdminAccessControl.InvalidAdminChange.selector
        );
    bytes internal UnsupportedAsset =
        abi.encodeWithSelector(ILevelMinting.UnsupportedAsset.selector);
    bytes internal NoAssetsProvided =
        abi.encodeWithSelector(ILevelMinting.NoAssetsProvided.selector);
    bytes internal InvalidNonce =
        abi.encodeWithSelector(ILevelMinting.InvalidNonce.selector);
    bytes internal MaxMintPerBlockExceeded =
        abi.encodeWithSelector(ILevelMinting.MaxMintPerBlockExceeded.selector);
    bytes internal MaxRedeemPerBlockExceeded =
        abi.encodeWithSelector(
            ILevelMinting.MaxRedeemPerBlockExceeded.selector
        );
    // lvlUSD error encodings
    bytes internal OnlyMinterErr =
        abi.encodeWithSelector(IlvlUSDDefinitions.OnlyMinter.selector);
    bytes internal ZeroAddressExceptionErr =
        abi.encodeWithSelector(
            IlvlUSDDefinitions.ZeroAddressException.selector
        );
    bytes internal OperationNotAllowedErr =
        abi.encodeWithSelector(IlvlUSDDefinitions.OperationNotAllowed.selector);
    bytes internal IsOwnerErr =
        abi.encodeWithSelector(IlvlUSDDefinitions.IsOwner.selector);
    bytes internal DenylistedErr =
        abi.encodeWithSelector(IlvlUSDDefinitions.Denylisted.selector);

    bytes32 internal constant ROUTE_TYPE =
        keccak256("Route(address[] addresses,uint256[] ratios)");
    bytes32 internal constant ORDER_TYPE =
        keccak256(
            "Order(uint256 nonce,address benefactor,address beneficiary,address asset,uint256 base_amount,uint256 quote_amount)"
        );

    uint256 internal _slippageRange = 50000000000000000;
    uint256 internal _stETHToDeposit = 50 * 10 ** 18;
    uint256 internal _stETHToWithdraw = 30 * 10 ** 18;
    uint256 internal _lvlusdToMint = 8.75 * 10 ** 23;
    uint256 internal _maxMintPerBlock = 10e23;
    uint256 internal _maxRedeemPerBlock = _maxMintPerBlock;

    // Declared at contract level to avoid stack too deep
    SigUtils.Permit public permit;
    ILevelMinting.Order public mint;

    /// @notice packs r, s, v into signature bytes
    function _packRsv(
        bytes32 r,
        bytes32 s,
        uint8 v
    ) internal pure returns (bytes memory) {
        bytes memory sig = new bytes(65);
        assembly {
            mstore(add(sig, 32), r)
            mstore(add(sig, 64), s)
            mstore8(add(sig, 96), v)
        }
        return sig;
    }

    function setUp() public virtual {
        utils = new Utils();

        lvlusdToken = new lvlUSD(address(this));
        stETHToken = new MockToken("Staked ETH", "sETH", 18, msg.sender);
        cbETHToken = new MockToken("Coinbase ETH", "cbETH", 18, msg.sender);
        rETHToken = new MockToken("Rocket Pool ETH", "rETH", 18, msg.sender);
        USDCToken = new MockToken(
            "United States Dollar Coin",
            "USDC",
            6,
            msg.sender
        );
        USDTToken = new MockToken(
            "United States Dollar Token",
            "USDT",
            18,
            msg.sender
        );

        sigUtils = new SigUtils(stETHToken.DOMAIN_SEPARATOR());
        sigUtilslvlUSD = new SigUtils(lvlusdToken.DOMAIN_SEPARATOR());

        assets = new address[](6);
        assets[0] = address(stETHToken);
        assets[1] = address(cbETHToken);
        assets[2] = address(rETHToken);
        assets[3] = address(USDCToken);
        assets[4] = address(USDTToken);
        assets[5] = NATIVE_TOKEN;

        ownerPrivateKey = 0xA11CE;
        newOwnerPrivateKey = 0xA14CE;
        minterPrivateKey = 0xB44DE;
        redeemerPrivateKey = 0xB45DE;
        maker1PrivateKey = 0xA13CE;
        maker2PrivateKey = 0xA14CE;
        benefactorPrivateKey = 0x1DC;
        beneficiaryPrivateKey = 0x1DAC;
        trader1PrivateKey = 0x1DE;
        trader2PrivateKey = 0x1DEA;
        gatekeeperPrivateKey = 0x1DEA1;
        bobPrivateKey = 0x1DEA2;
        reserve1PrivateKey = 0x1DCDE;
        reserve2PrivateKey = 0x1DCCE;
        randomerPrivateKey = 0x1DECC;

        owner = vm.addr(ownerPrivateKey);
        newOwner = vm.addr(newOwnerPrivateKey);
        minter = vm.addr(minterPrivateKey);
        redeemer = vm.addr(redeemerPrivateKey);
        maker1 = vm.addr(maker1PrivateKey);
        maker2 = vm.addr(maker2PrivateKey);
        benefactor = vm.addr(benefactorPrivateKey);
        beneficiary = vm.addr(beneficiaryPrivateKey);
        trader1 = vm.addr(trader1PrivateKey);
        trader2 = vm.addr(trader2PrivateKey);
        gatekeeper = vm.addr(gatekeeperPrivateKey);
        bob = vm.addr(bobPrivateKey);
        reserve1 = vm.addr(reserve1PrivateKey);
        reserve2 = vm.addr(reserve2PrivateKey);
        randomer = vm.addr(randomerPrivateKey);

        reserves = new address[](1);
        reserves[0] = reserve1;

        ratios = new uint256[](1);
        ratios[0] = 10000;

        vm.label(minter, "minter");
        vm.label(redeemer, "redeemer");
        vm.label(owner, "owner");
        vm.label(maker1, "maker1");
        vm.label(maker2, "maker2");
        vm.label(benefactor, "benefactor");
        vm.label(beneficiary, "beneficiary");
        vm.label(trader1, "trader1");
        vm.label(trader2, "trader2");
        vm.label(gatekeeper, "gatekeeper");
        vm.label(bob, "bob");
        vm.label(reserve1, "reserve1");
        vm.label(reserve2, "reserve2");
        vm.label(randomer, "randomer");

        // Set the roles
        vm.startPrank(owner);
        LevelMintingContract = new LevelMintingChild(
            IlvlUSD(address(lvlusdToken)),
            assets,
            reserves,
            ratios,
            owner,
            _maxMintPerBlock,
            _maxRedeemPerBlock
        );

        LevelMintingContract.grantRole(gatekeeperRole, gatekeeper);
        LevelMintingContract.grantRole(minterRole, minter);
        LevelMintingContract.grantRole(redeemerRole, redeemer);

        // Set the max mint per block
        LevelMintingContract.setMaxMintPerBlock(_maxMintPerBlock);
        // Set the max redeem per block
        LevelMintingContract.setMaxRedeemPerBlock(_maxRedeemPerBlock);

        // Add self as approved reserve
        LevelMintingContract.addReserveAddress(address(LevelMintingContract));

        // Mint stEth to the benefactor in order to test
        stETHToken.mint(_stETHToDeposit, benefactor);
        // stETHToken.mint(_stETHToDeposit, beneficiary);

        // set up level reserve manager
        levelReserveManager = new LevelReserveManager(
            IlvlUSD(address(lvlusdToken)),
            address(owner),
            address(owner)
        );
        USDCToken.mint(100000000, address(levelReserveManager));

        LevelMintingContract.addReserveAddress(address(levelReserveManager));

        vm.stopPrank();

        lvlusdToken.setMinter(address(LevelMintingContract));
    }

    function _generateRouteTypeHash(
        ILevelMinting.Route memory route
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ROUTE_TYPE,
                    keccak256(abi.encodePacked(route.addresses)),
                    keccak256(abi.encodePacked(route.ratios))
                )
            );
    }

    function signOrder(
        uint256 key,
        bytes32 digest,
        ILevelMinting.SignatureType sigType
    ) public pure returns (ILevelMinting.Signature memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, digest);
        bytes memory sigBytes = _packRsv(r, s, v);

        ILevelMinting.Signature memory signature = ILevelMinting.Signature({
            signature_type: sigType,
            signature_bytes: sigBytes
        });

        return signature;
    }

    // Generic mint setup reused in the tests to reduce lines of code
    function mint_setup(
        uint256 lvlusdAmount,
        uint256 collateralAmount,
        uint256 nonce,
        bool multipleMints
    )
        public
        returns (
            ILevelMinting.Order memory order,
            ILevelMinting.Route memory route
        )
    {
        order = ILevelMinting.Order({
            order_type: ILevelMinting.OrderType.MINT,
            nonce: nonce,
            benefactor: benefactor,
            beneficiary: beneficiary,
            collateral_asset: address(stETHToken),
            lvlusd_amount: lvlusdAmount,
            collateral_amount: collateralAmount
        });

        address[] memory targets = new address[](1);
        targets[0] = address(LevelMintingContract);

        uint256[] memory _ratios = new uint256[](1);
        _ratios[0] = 10_000;

        route = ILevelMinting.Route({addresses: targets, ratios: ratios});

        vm.startPrank(benefactor);
        stETHToken.approve(address(LevelMintingContract), collateralAmount);
        vm.stopPrank();

        vm.startPrank(benefactor);
        lvlusdToken.approve(address(LevelMintingContract), lvlusdAmount);
        vm.stopPrank();

        vm.startPrank(beneficiary);
        stETHToken.approve(address(LevelMintingContract), collateralAmount);
        vm.stopPrank();

        vm.startPrank(beneficiary);
        lvlusdToken.approve(address(LevelMintingContract), lvlusdAmount);
        vm.stopPrank();

        vm.startPrank(redeemer);
        stETHToken.approve(address(LevelMintingContract), collateralAmount);
        vm.stopPrank();
    }

    // Generic redeem setup reused in the tests to reduce lines of code
    function redeem_setup(
        uint256 lvlusdAmount,
        uint256 collateralAmount,
        uint256 nonce,
        bool multipleRedeem
    ) public returns (ILevelMinting.Order memory redeemOrder) {
        (
            ILevelMinting.Order memory mintOrder,
            ILevelMinting.Route memory route
        ) = mint_setup(lvlusdAmount, collateralAmount, nonce, false);
        vm.prank(minter);
        LevelMintingContract.mint(mintOrder, route);

        //redeem
        redeemOrder = ILevelMinting.Order({
            order_type: ILevelMinting.OrderType.REDEEM,
            nonce: nonce + 1,
            benefactor: beneficiary,
            beneficiary: beneficiary,
            collateral_asset: address(stETHToken),
            lvlusd_amount: lvlusdAmount,
            collateral_amount: collateralAmount
        });

        // taker
        vm.startPrank(beneficiary);
        lvlusdToken.approve(
            address(LevelMintingContract),
            10000000 * lvlusdAmount
        );
        vm.stopPrank();
        vm.startPrank(owner);
        LevelMintingContract.grantRole(redeemerRole, redeemer);
        vm.stopPrank();
    }

    function _getInvalidRoleError(
        bytes32 role,
        address addr
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(addr),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            );
    }
}
