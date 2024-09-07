// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./ILevelMinting.sol";

interface ILevelReserveManager {
    error InvalidAmount();
    error InvalidZeroAddress();
    error InvalidlvlUSDAddress();
    error InvalidRecipient();
    error ZeroExcessAToken();
    error InsufficientATokensInReserve();

    event DepositedToSymbiotic(uint256 amount, address symbioticVault);
    event WithdrawnFromSymbiotic(uint256 amount, address symbioticVault);
    event ClaimedFromSymbiotic(
        uint256 epoch,
        uint256 amount,
        address symbioticVault
    );
    event DepositedToKarak(uint256 amount, address karakVault);
    event RedeemFromKarakStarted(uint256 shares, address karakVault);
    event RedeemFromKarakFinished(address karakVault, bytes32 withdrawalKey);

    event DepositedToLevelMinting(uint256 amount);

    // deposit and withdraw functions
    function depositToSymbiotic(address vault, uint256 amount) external;

    function withdrawFromSymbiotic(address vault, uint256 amount) external;

    function claimFromSymbiotic(address vault, uint256 epoch) external;

    function depositToLevelMinting(address token, uint256 amount) external;

    // approval function
    function approveSpender(
        address token,
        address spender,
        uint256 amount
    ) external;
}
