// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19;

import "./interfaces/ILevelReserveManager.sol";
import "./SingleAdminAccessControl.sol";
import "./interfaces/IlvlUSD.sol";
import "./interfaces/IAaveV3Pool.sol";
import "./interfaces/ILevelMinting.sol";
import "./interfaces/IStakedlvlUSD.sol";
import "./interfaces/ISymbioticVault.sol";

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Level Minting Contract
 * @notice This contract issues and redeems lvlUSD for/from other accepted stablecoins
 * @dev Changelog: change name to LevelMinting and lvlUSD, update solidity versions
 */
contract LevelReserveManager is ILevelReserveManager, SingleAdminAccessControl {
    using SafeERC20 for IERC20;

    /* --------------- STATE VARIABLES --------------- */

    IlvlUSD public immutable lvlusd;
    IPool public aavePool;
    ILevelMinting public levelMinting;
    IStakedlvlUSD public stakedlvlUSD;
    IVault public symbioticVault;
    address usdt; // usdt token address
    address aaveAToken; // AToken corresponding to usdt
    uint256 aaveNetAmountDeposited;

    /* --------------- CONSTRUCTOR --------------- */

    constructor(
        IlvlUSD _lvlusd,
        IPool _aavePool,
        ILevelMinting _levelMinting,
        IStakedlvlUSD _stakedlvlUSD,
        address _admin,
        address _usdt,
        address _aaveAToken
    ) {
        if (address(_lvlusd) == address(0)) revert InvalidlvlUSDAddress();
        if (_admin == address(0)) revert InvalidZeroAddress();
        lvlusd = _lvlusd;
        aavePool = _aavePool;
        levelMinting = _levelMinting;
        stakedlvlUSD = _stakedlvlUSD;
        usdt = _usdt;
        aaveAToken = _aaveAToken;

        if (msg.sender != _admin) {
            _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        } else {
            _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        }
        // TODO: grant approvals for transferring lvlUSD to stakedlvlUSD from this contract
    }

    /* --------------- INTERNAL --------------- */

    function _calculateExcessAaveAToken() internal view returns (uint256) {
        return
            IERC20(aaveAToken).balanceOf(address(this)) -
            aaveNetAmountDeposited;
    }

    function _withdrawFromAave(uint256 amount) internal {
        aavePool.withdraw(usdt, amount, address(this));
        aaveNetAmountDeposited -= amount;
    }

    /* --------------- EXTERNAL --------------- */

    // deposit USDT to Aave pool
    // https://docs.aave.com/developers/deployed-contracts/v3-testnet-addresses
    function depositToAave(
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        aavePool.supply(usdt, amount, address(this), 0);
        aaveNetAmountDeposited += amount;
    }

    // withdraw from Aave pool
    function withdrawFromAave(
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _withdrawFromAave(amount);
    }

    // deposit USDT to symbiotic vault
    function depositToSymbiotic(
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        symbioticVault.deposit(address(this), amount);
    }

    // withdraw USDT from symbiotic vault
    function withdrawFromSymbiotic(
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        symbioticVault.withdraw(address(this), amount);
    }

    //deposit USDT to LevelMinting
    function depositToLevelMinting(
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(usdt).transfer(address(levelMinting), amount);
    }

    // deposit lvlUSD to stakedlvlUSD
    function depositToStakedlvlUSD(
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakedlvlUSD.transferInRewards(amount);
    }

    function convertAUSDTtolvlUSD()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256)
    {
        // 1. compute excess ATokens
        uint256 amount = _calculateExcessAaveAToken();

        // 2. burn all excess ATokens and withdraw collateral from AAVE
        _withdrawFromAave(amount);

        // 3. mint lvlUSD via LevelMinting
        ILevelMinting.Order memory order = ILevelMinting.Order(
            ILevelMinting.OrderType.MINT,
            999999999999, // expiry
            block.timestamp, // nonce,
            address(this),
            address(this),
            address(usdt), // collateral
            amount, // collateral amount
            amount // lvlusd_amount
        );
        address[] memory addresses = new address[](1);
        addresses[0] = address(this);
        uint256[] memory ratios = new uint256[](1);
        ratios[0] = 10000;
        ILevelMinting.Route memory route = ILevelMinting.Route(
            addresses,
            ratios
        );
        levelMinting.mint(order, route);
        return amount;
    }

    function convertATokenTolvlUSDAndDepositIntoStakedlvlUSD()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 amount = this.convertAUSDTtolvlUSD();
        this.depositToStakedlvlUSD(amount);
    }

    function approveSpender(
        address token,
        address spender,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(token).approve(spender, amount);
    }

    /* --------------- SETTERS --------------- */

    function setSymbioticVaultAddress(
        address newAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        symbioticVault = IVault(newAddress);
    }

    function setLevelMintingAddress(
        address newAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        levelMinting = ILevelMinting(newAddress);
    }

    function setAaveV3PoolAddress(
        address newAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        aavePool = IPool(newAddress);
    }

    function setStakedlvlUSDAddress(
        address newAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakedlvlUSD = IStakedlvlUSD(newAddress);
    }

    function setUsdtAddress(
        address newAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        usdt = newAddress;
    }

    function setATokenAddress(
        address newAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        aaveAToken = newAddress;
    }
}
