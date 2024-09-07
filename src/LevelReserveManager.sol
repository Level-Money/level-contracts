// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19;

import "./interfaces/ILevelReserveManager.sol";
import "./SingleAdminAccessControl.sol";
import "./interfaces/IlvlUSD.sol";
import "./interfaces/ILevelMinting.sol";
import "./interfaces/IStakedlvlUSD.sol";
import "./interfaces/ISymbioticVault.sol" as ISymbioticVault;
import "./interfaces/IKarakVault.sol" as IKarakVault;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Level Reserve Manager
 * @notice This contract stores and manages reserves from minted lvlUSD
 */
contract LevelReserveManager is ILevelReserveManager, SingleAdminAccessControl {
    using SafeERC20 for IERC20;
    using SafeERC20 for ERC20;

    /// @notice role that sets the addresses where funds can be sent from this contract
    bytes32 private constant ALLOWLIST_ROLE = keccak256("ALLOWLIST_ROLE");

    /* --------------- STATE VARIABLES --------------- */

    IlvlUSD public immutable lvlusd;
    IStakedlvlUSD public stakedlvlUSD;
    uint256 nonce = 1; // for LevelMinting
    ILevelMinting.Route route;
    mapping(address => bool) public allowlist;

    /* --------------- CONSTRUCTOR --------------- */

    constructor(
        IlvlUSD _lvlusd,
        IStakedlvlUSD _stakedlvlUSD,
        address _admin,
        address _allowlister
    ) {
        if (address(_lvlusd) == address(0)) revert InvalidlvlUSDAddress();
        if (_admin == address(0)) revert InvalidZeroAddress();
        lvlusd = _lvlusd;
        stakedlvlUSD = _stakedlvlUSD;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ALLOWLIST_ROLE, _allowlister);

        // TODO: grant approvals for transferring lvlUSD to stakedlvlUSD from this contract

        address[] memory addresses = new address[](1);
        addresses[0] = address(this);
        uint256[] memory ratios = new uint256[](1);
        ratios[0] = 10000;
        route = ILevelMinting.Route(addresses, ratios);
    }

    /* --------------- EXTERNAL --------------- */

    function transferERC20(
        address tokenAddress,
        address tokenReceiver,
        uint256 tokenAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (allowlist[tokenReceiver]) {
            IERC20(tokenAddress).safeTransfer(tokenReceiver, tokenAmount);
        } else {
            revert InvalidRecipient();
        }
    }

    function transferEth(
        address payable _to,
        uint _amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (allowlist[_to]) {
            (bool success, ) = _to.call{value: _amount}("");
            require(success, "Failed to send Ether");
        } else {
            revert InvalidRecipient();
        }
    }

    function addToAllowList(
        address recipient
    ) external onlyRole(ALLOWLIST_ROLE) {
        allowlist[recipient] = true;
    }

    function removeFromAllowList(
        address recipient
    ) external onlyRole(ALLOWLIST_ROLE) {
        allowlist[recipient] = false;
    }

    // deposit USDT to symbiotic vault
    function depositToSymbiotic(
        address vault,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ISymbioticVault.IVault(vault).deposit(address(this), amount);
        emit DepositedToSymbiotic(amount, vault);
    }

    // withdraw USDT from symbiotic vault
    function withdrawFromSymbiotic(
        address vault,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ISymbioticVault.IVault(vault).withdraw(address(this), amount);
        emit WithdrawnFromSymbiotic(amount, vault);
    }

    // claim collateral from Symbiotic
    function claimFromSymbiotic(
        address vault,
        uint256 epoch
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = ISymbioticVault.IVault(vault).claim(
            address(this),
            epoch
        );
        emit ClaimedFromSymbiotic(epoch, amount, vault);
    }

    function depositToKarak(
        address vault,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IKarakVault.IVault(vault).deposit(amount, address(this));
        emit DepositedToKarak(amount, vault);
    }

    function startRedeemFromKarak(
        address vault,
        uint256 shares
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bytes32 withdrawalKey) {
        withdrawalKey = IKarakVault.IVault(vault).startRedeem(
            shares,
            address(this)
        );
        emit RedeemFromKarakStarted(shares, vault);
    }

    function finishRedeemFromKarak(
        address vault,
        bytes32 withdrawalKey
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IKarakVault.IVault(vault).finishRedeem(withdrawalKey);
        emit RedeemFromKarakFinished(vault, withdrawalKey);
    }

    //deposit USDT to LevelMinting
    function depositToLevelMinting(
        address token,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(token).transfer(address(lvlusd.minter()), amount);
        emit DepositedToLevelMinting(amount);
    }

    // deposit lvlUSD to stakedlvlUSD
    function depositToStakedlvlUSD(
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakedlvlUSD.transferInRewards(amount);
    }

    function _depositToStakedlvlUSD(uint256 amount) internal {
        stakedlvlUSD.transferInRewards(amount);
        emit DepositedToStakedlvlUSD(amount);
    }

    function _mintlvlUSD(address collateral, uint256 amount) internal {
        uint256 collateral_decimals = ERC20(collateral).decimals();
        uint256 lvlUSD_decimals = lvlusd.decimals();
        uint lvlusd_amount = amount;
        if (collateral_decimals < lvlUSD_decimals) {
            lvlusd_amount =
                amount *
                (10 ** (lvlUSD_decimals - collateral_decimals));
        } else if (collateral_decimals > lvlUSD_decimals) {
            lvlusd_amount =
                amount /
                (10 ** (collateral_decimals - lvlUSD_decimals));
        }
        ILevelMinting.Order memory order = ILevelMinting.Order(
            ILevelMinting.OrderType.MINT,
            nonce, // nonce,
            address(this), // benefactor
            address(this), // beneficiary
            collateral, // collateral
            amount, // collateral amount
            lvlusd_amount // lvlusd_amount
        );
        nonce = nonce + 1;
        ILevelMinting(lvlusd.minter()).mint(order, route);
    }

    function mintlvlUSD(
        address collateral,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _mintlvlUSD(collateral, amount);
    }

    function approveSpender(
        address token,
        address spender,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(token).forceApprove(spender, amount);
    }

    /* --------------- SETTERS --------------- */

    function setStakedlvlUSDAddress(
        address newAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakedlvlUSD = IStakedlvlUSD(newAddress);
    }

    function setRoute(
        ILevelMinting.Route memory newRoute
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        route = newRoute;
    }
}
