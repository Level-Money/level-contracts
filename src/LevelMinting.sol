// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19;

/**
 * solhint-disable private-vars-leading-underscore
 */

import "./SingleAdminAccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IlvlUSD.sol";
import "./interfaces/ILevelMinting.sol";

/**
 * @title Level Minting Contract
 * @notice This contract issues and redeems lvlUSD for/from other accepted stablecoins
 * @dev Changelog: change name to LevelMinting and lvlUSD, update solidity versions
 */
contract LevelMinting is
    ILevelMinting,
    SingleAdminAccessControl,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /* --------------- CONSTANTS --------------- */

    /// @notice EIP712 domain
    bytes32 private constant EIP712_DOMAIN =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /// @notice order type
    bytes32 private constant ORDER_TYPE =
        keccak256(
            "Order(uint8 order_type,uint256 nonce,address benefactor,address beneficiary,address collateral_asset,uint256 collateral_amount,uint256 lvlusd_amount)"
        );

    /// @notice role enabling to disable mint and redeem
    bytes32 private constant GATEKEEPER_ROLE = keccak256("GATEKEEPER_ROLE");

    /// @notice role for minting lvlUSD
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice role for redeeming lvlUSD
    bytes32 private constant REDEEMER_ROLE = keccak256("REDEEMER_ROLE");

    /// @notice EIP712 name
    bytes32 private constant EIP_712_NAME = keccak256("LevelMinting");

    /// @notice holds EIP712 revision
    bytes32 private constant EIP712_REVISION = keccak256("1");

    /* --------------- STATE VARIABLES --------------- */

    /// @notice lvlusd stablecoin
    IlvlUSD public immutable lvlusd;

    /// @notice Supported assets
    EnumerableSet.AddressSet internal _supportedAssets;

    // @notice reserve addresses
    EnumerableSet.AddressSet internal _reserveAddresses;

    /// @notice holds computable chain id
    uint256 private immutable _chainId;

    /// @notice holds computable domain separator
    bytes32 private immutable _domainSeparator;

    /// @notice user deduplication
    mapping(address => mapping(uint256 => uint256)) private _orderBitmaps;

    /// @notice lvlUSD minted per block
    mapping(uint256 => uint256) public mintedPerBlock;
    /// @notice lvlUSD redeemed per block
    mapping(uint256 => uint256) public redeemedPerBlock;

    /// @notice For smart contracts to delegate signing to EOA address
    mapping(address => mapping(address => bool)) public delegatedSigner;

    /// @notice max minted lvlUSD allowed per block
    uint256 public maxMintPerBlock;
    /// @notice max redeemed lvlUSD allowed per block
    uint256 public maxRedeemPerBlock;

    bool private checkMinterRole = true;
    bool private checkRedeemerRole = true;

    uint24 public constant MAX_COOLDOWN_DURATION = 7 days;
    uint24 public cooldownDuration;

    mapping(address => mapping(address => UserCooldown)) public cooldowns;

    /* --------------- MODIFIERS --------------- */

    /// @notice ensure that the already minted lvlUSD in the actual block plus the amount to be minted is below the maxMintPerBlock var
    /// @param mintAmount The lvlUSD amount to be minted
    modifier belowMaxMintPerBlock(uint256 mintAmount) {
        if (mintedPerBlock[block.number] + mintAmount > maxMintPerBlock)
            revert MaxMintPerBlockExceeded();
        _;
    }

    /// @notice ensure that the already redeemed lvlUSD in the actual block plus the amount to be redeemed is below the maxRedeemPerBlock var
    /// @param redeemAmount The lvlUSD amount to be redeemed
    modifier belowMaxRedeemPerBlock(uint256 redeemAmount) {
        if (redeemedPerBlock[block.number] + redeemAmount > maxRedeemPerBlock)
            revert MaxRedeemPerBlockExceeded();
        _;
    }

    modifier onlyMinterWhenEnabled() {
        if (checkMinterRole) {
            _checkRole(MINTER_ROLE);
        }
        _;
    }

    modifier onlyRedeemerWhenEnabled() {
        if (checkRedeemerRole) {
            _checkRole(REDEEMER_ROLE);
        }
        _;
    }

    /// @notice ensure cooldownDuration is zero
    modifier ensureCooldownOff() {
        if (cooldownDuration != 0) revert OperationNotAllowed();
        _;
    }

    /// @notice ensure cooldownDuration is gt 0
    modifier ensureCooldownOn() {
        if (cooldownDuration == 0) revert OperationNotAllowed();
        _;
    }

    /* --------------- CONSTRUCTOR --------------- */

    constructor(
        IlvlUSD _lvlusd,
        address[] memory _assets,
        address[] memory _reserves,
        address _admin,
        uint256 _maxMintPerBlock,
        uint256 _maxRedeemPerBlock
    ) {
        if (address(_lvlusd) == address(0)) revert InvalidlvlUSDAddress();
        if (_assets.length == 0) revert NoAssetsProvided();
        if (_admin == address(0)) revert InvalidZeroAddress();
        lvlusd = _lvlusd;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        for (uint256 i = 0; i < _assets.length; i++) {
            addSupportedAsset(_assets[i]);
        }

        for (uint256 j = 0; j < _reserves.length; j++) {
            addReserveAddress(_reserves[j]);
        }

        // Set the max mint/redeem limits per block
        _setMaxMintPerBlock(_maxMintPerBlock);
        _setMaxRedeemPerBlock(_maxRedeemPerBlock);

        if (msg.sender != _admin) {
            _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        }

        _chainId = block.chainid;
        _domainSeparator = _computeDomainSeparator();

        cooldownDuration = MAX_COOLDOWN_DURATION;

        emit lvlUSDSet(address(_lvlusd));
    }

    /* --------------- EXTERNAL --------------- */

    /**
     * @notice Mint stablecoins from assets
     * @param order struct containing order details and confirmation from server
     * @param route the addresses to which the collateral should be sent (and ratios describing the amount to send to each address)
     */
    function _mint(
        Order calldata order,
        Route calldata route
    ) internal nonReentrant belowMaxMintPerBlock(order.lvlusd_amount) {
        if (order.order_type != OrderType.MINT) revert InvalidOrder();
        verifyOrder(order);
        if (!verifyRoute(route, order.order_type)) revert InvalidRoute();
        _deduplicateOrder(order.benefactor, order.nonce);
        // Add to the minted amount in this block
        mintedPerBlock[block.number] += order.lvlusd_amount;
        _transferCollateral(
            order.collateral_amount,
            order.collateral_asset,
            order.benefactor,
            route.addresses,
            route.ratios
        );
        lvlusd.mint(order.beneficiary, order.lvlusd_amount);
        emit Mint(
            msg.sender,
            order.benefactor,
            order.beneficiary,
            order.collateral_asset,
            order.collateral_amount,
            order.lvlusd_amount
        );
    }

    function checkCollateralAndlvlUSDAmountEquality(
        Order memory order
    ) private view {
        uint8 collateral_asset_decimals = ERC20(order.collateral_asset)
            .decimals();
        uint8 lvlusd_decimals = lvlusd.decimals();
        if (collateral_asset_decimals == lvlusd_decimals) {
            assert(order.collateral_amount == order.lvlusd_amount);
        } else if (collateral_asset_decimals > lvlusd_decimals) {
            uint8 diff = collateral_asset_decimals - lvlusd_decimals;
            assert(
                order.collateral_amount == order.lvlusd_amount * (10 ** diff)
            );
        } else {
            uint8 diff = lvlusd_decimals - collateral_asset_decimals;
            assert(
                order.collateral_amount * (10 ** diff) == order.lvlusd_amount
            );
        }
    }

    function mint(
        Order calldata order,
        Route calldata route
    ) external virtual onlyMinterWhenEnabled {
        checkCollateralAndlvlUSDAmountEquality(order);
        _mint(order, route);
    }

    /**
     * @notice Redeem stablecoins for assets
     * @param order struct containing order details and confirmation from server
     */
    function _redeem(
        Order memory order
    ) internal nonReentrant belowMaxRedeemPerBlock(order.lvlusd_amount) {
        if (order.order_type != OrderType.REDEEM) revert InvalidOrder();
        _deduplicateOrder(order.benefactor, order.nonce);
        // Add to the redeemed amount in this block
        redeemedPerBlock[block.number] += order.lvlusd_amount;
        lvlusd.burnFrom(order.benefactor, order.lvlusd_amount);
        _transferToBeneficiary(
            order.beneficiary,
            order.collateral_asset,
            order.collateral_amount
        );
        emit Redeem(
            msg.sender,
            order.benefactor,
            order.beneficiary,
            order.collateral_asset,
            order.collateral_amount,
            order.lvlusd_amount
        );
    }

    function initiateRedeem(
        Order memory order
    ) external ensureCooldownOn onlyRedeemerWhenEnabled {
        if (order.order_type != OrderType.REDEEM) revert InvalidOrder();

        UserCooldown memory newCooldown = UserCooldown({
            cooldownEnd: uint104(block.timestamp + cooldownDuration),
            order: order
        });

        cooldowns[msg.sender][order.collateral_asset] = newCooldown;

        emit RedeemInitiated(
            msg.sender,
            order.collateral_asset,
            order.collateral_amount,
            order.lvlusd_amount
        );
    }

    function completeRedeem(
        address token // collateral
    ) external virtual ensureCooldownOn onlyRedeemerWhenEnabled {
        UserCooldown memory userCooldown = cooldowns[msg.sender][token];
        checkCollateralAndlvlUSDAmountEquality(userCooldown.order);
        if (
            block.timestamp >= userCooldown.cooldownEnd || cooldownDuration == 0
        ) {
            userCooldown.cooldownEnd = 0;
            cooldowns[msg.sender][token] = userCooldown;
            _redeem(userCooldown.order);
            emit RedeemCompleted(
                msg.sender,
                userCooldown.order.collateral_asset,
                userCooldown.order.collateral_amount,
                userCooldown.order.lvlusd_amount
            );
        } else {
            revert InvalidCooldown();
        }
    }

    function redeem(
        Order memory order
    ) external virtual ensureCooldownOff onlyRedeemerWhenEnabled {
        if (order.order_type != OrderType.REDEEM) revert InvalidOrder();
        checkCollateralAndlvlUSDAmountEquality(order);
        _redeem(order);
    }

    /// @notice Sets the max mintPerBlock limit
    function setMaxMintPerBlock(
        uint256 _maxMintPerBlock
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setMaxMintPerBlock(_maxMintPerBlock);
    }

    /// @notice Sets the max redeemPerBlock limit
    function setMaxRedeemPerBlock(
        uint256 _maxRedeemPerBlock
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setMaxRedeemPerBlock(_maxRedeemPerBlock);
    }

    /// @notice Disables the mint and redeem
    function disableMintRedeem() external onlyRole(GATEKEEPER_ROLE) {
        _setMaxMintPerBlock(0);
        _setMaxRedeemPerBlock(0);
    }

    /// @notice Enables smart contracts to delegate an address for signing
    function setDelegatedSigner(address _delegateTo) external {
        delegatedSigner[_delegateTo][msg.sender] = true;
        emit DelegatedSignerAdded(_delegateTo, msg.sender);
    }

    /// @notice Enables smart contracts to undelegate an address for signing
    function removeDelegatedSigner(address _removedSigner) external {
        delegatedSigner[_removedSigner][msg.sender] = false;
        emit DelegatedSignerRemoved(_removedSigner, msg.sender);
    }

    /// @notice transfers an asset to a reserve wallet
    function transferToReserve(
        address wallet,
        address asset,
        uint256 amount
    ) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        if (wallet == address(0) || !_reserveAddresses.contains(wallet))
            revert InvalidAddress();
        IERC20(asset).safeTransfer(wallet, amount);
        emit ReserveTransfer(wallet, asset, amount);
    }

    /// @notice Removes an asset from the supported assets list
    function removeSupportedAsset(
        address asset
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!_supportedAssets.remove(asset)) revert InvalidAssetAddress();
        emit AssetRemoved(asset);
    }

    /// @notice Checks if an asset is supported.
    function isSupportedAsset(address asset) external view returns (bool) {
        return _supportedAssets.contains(asset);
    }

    /// @notice Removes a reserve from the reserve address list
    function removeReserveAddress(
        address reserve
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!_reserveAddresses.remove(reserve)) revert InvalidReserveAddress();
        emit ReserveAddressRemoved(reserve);
    }

    /* --------------- PUBLIC --------------- */

    /// @notice Adds an asset to the supported assets list.
    function addSupportedAsset(
        address asset
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (
            asset == address(0) ||
            asset == address(lvlusd) ||
            !_supportedAssets.add(asset)
        ) {
            revert InvalidAssetAddress();
        }
        emit AssetAdded(asset);
    }

    /// @notice Adds a reserve to the supported reserves list.
    function addReserveAddress(
        address reserve
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (
            reserve == address(0) ||
            reserve == address(lvlusd) ||
            !_reserveAddresses.add(reserve)
        ) {
            revert InvalidReserveAddress();
        }
        emit ReserveAddressAdded(reserve);
    }

    /// @notice Get the domain separator for the token
    /// @dev Return cached value if chainId matches cache, otherwise recomputes separator, to prevent replay attack across forks
    /// @return The domain separator of the token at current chain
    function getDomainSeparator() public view returns (bytes32) {
        if (block.chainid == _chainId) {
            return _domainSeparator;
        }
        return _computeDomainSeparator();
    }

    /// @notice hash an Order struct
    function hashOrder(
        Order calldata order
    ) public view override returns (bytes32) {
        return
            ECDSA.toTypedDataHash(
                getDomainSeparator(),
                keccak256(encodeOrder(order))
            );
    }

    function encodeOrder(
        Order calldata order
    ) public pure returns (bytes memory) {
        return
            abi.encode(
                ORDER_TYPE,
                order.order_type,
                order.nonce,
                order.benefactor,
                order.beneficiary,
                order.collateral_asset,
                order.collateral_amount,
                order.lvlusd_amount
            );
    }

    /// @notice assert validity of signed order
    function verifyOrder(
        Order calldata order
    ) public view override returns (bool, bytes32) {
        bytes32 taker_order_hash = hashOrder(order);
        if (order.beneficiary == address(0)) revert InvalidAmount();
        if (order.collateral_amount == 0) revert InvalidAmount();
        if (order.lvlusd_amount == 0) revert InvalidAmount();
        return (true, taker_order_hash);
    }

    /// @notice assert validity of route object per type
    function verifyRoute(
        Route calldata route,
        OrderType orderType
    ) public view override returns (bool) {
        // routes only used to mint
        if (orderType == OrderType.REDEEM) {
            return true;
        }
        uint256 totalRatio = 0;
        if (route.addresses.length != route.ratios.length) {
            return false;
        }
        if (route.addresses.length == 0) {
            return false;
        }
        for (uint256 i = 0; i < route.addresses.length; ++i) {
            if (
                !_reserveAddresses.contains(route.addresses[i]) ||
                route.addresses[i] == address(0) ||
                route.ratios[i] == 0
            ) {
                return false;
            }
            totalRatio += route.ratios[i];
        }
        if (totalRatio != 10_000) {
            return false;
        }
        return true;
    }

    /// @notice verify validity of nonce by checking its presence
    function verifyNonce(
        address sender,
        uint256 nonce
    ) public view override returns (bool, uint256, uint256, uint256) {
        if (nonce == 0) revert InvalidNonce();
        uint256 invalidatorSlot = nonce >> 8;
        uint256 invalidatorBit = 1 << uint8(nonce);
        mapping(uint256 => uint256) storage invalidatorStorage = _orderBitmaps[
            sender
        ];
        uint256 invalidator = invalidatorStorage[invalidatorSlot];
        if (invalidator & invalidatorBit != 0) revert InvalidNonce();

        return (true, invalidatorSlot, invalidator, invalidatorBit);
    }

    function setCheckMinterRole(
        bool _check
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        checkMinterRole = _check;
    }

    function setCheckRedeemerRole(
        bool _check
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        checkRedeemerRole = _check;
    }

    /* --------------- PRIVATE --------------- */

    /// @notice deduplication of taker order
    function _deduplicateOrder(
        address sender,
        uint256 nonce
    ) private returns (bool) {
        (
            bool valid,
            uint256 invalidatorSlot,
            uint256 invalidator,
            uint256 invalidatorBit
        ) = verifyNonce(sender, nonce);
        mapping(uint256 => uint256) storage invalidatorStorage = _orderBitmaps[
            sender
        ];
        invalidatorStorage[invalidatorSlot] = invalidator | invalidatorBit;
        return valid;
    }

    /* --------------- INTERNAL --------------- */

    /// @notice transfer supported asset to beneficiary address
    function _transferToBeneficiary(
        address beneficiary,
        address asset,
        uint256 amount
    ) internal {
        if (!_supportedAssets.contains(asset)) revert UnsupportedAsset();
        IERC20(asset).safeTransfer(beneficiary, amount);
    }

    /// @notice transfer supported asset to array of reserve addresses per defined ratio
    function _transferCollateral(
        uint256 amount,
        address asset,
        address benefactor,
        address[] calldata addresses,
        uint256[] calldata ratios
    ) internal {
        // cannot mint using unsupported asset or native ETH even if it is supported for redemptions
        if (!_supportedAssets.contains(asset)) revert UnsupportedAsset();
        IERC20 token = IERC20(asset);
        uint256 totalTransferred;
        uint256 amountToTransfer;
        for (uint256 i = 0; i < addresses.length - 1; ++i) {
            amountToTransfer = (amount * ratios[i]) / 10_000;
            totalTransferred += amountToTransfer;
            token.safeTransferFrom(benefactor, addresses[i], amountToTransfer);
        }
        token.safeTransferFrom(
            benefactor,
            addresses[addresses.length - 1],
            amount - totalTransferred
        );
    }

    /// @notice Sets the max mintPerBlock limit
    function _setMaxMintPerBlock(uint256 _maxMintPerBlock) internal {
        uint256 oldMaxMintPerBlock = maxMintPerBlock;
        maxMintPerBlock = _maxMintPerBlock;
        emit MaxMintPerBlockChanged(oldMaxMintPerBlock, maxMintPerBlock);
    }

    /// @notice Sets the max redeemPerBlock limit
    function _setMaxRedeemPerBlock(uint256 _maxRedeemPerBlock) internal {
        uint256 oldMaxRedeemPerBlock = maxRedeemPerBlock;
        maxRedeemPerBlock = _maxRedeemPerBlock;
        emit MaxRedeemPerBlockChanged(oldMaxRedeemPerBlock, maxRedeemPerBlock);
    }

    /// @notice Compute the current domain separator
    /// @return The domain separator for the token
    function _computeDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN,
                    EIP_712_NAME,
                    EIP712_REVISION,
                    block.chainid,
                    address(this)
                )
            );
    }
}
