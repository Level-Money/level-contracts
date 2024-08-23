// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

// currently the LRM only supports USDT
interface ILevelReserveManager {
    error InvalidAmount();
    error InvalidZeroAddress();
    error InvalidlvlUSDAddress();

    // deposit and withdraw functions
    function depositToAave(uint256 amount) external; // deposit USDT to Aave pool

    function withdrawFromAave(uint256 amount) external; // withdraw from Aave pool

    function depositToSymbiotic(uint256 amount) external; // deposit USDT to symbiotic vault

    function withdrawFromSymbiotic(uint256 amount) external; // withdraw USDT from symbiotic vault

    function depositToLevelMinting(uint256 amount) external; //deposit USDT to LevelMinting

    function depositToStakedlvlUSD(uint256 amount) external; // deposit lvlUSD to stakedlvlUSD

    function convertATokenTolvlUSDAndDepositIntoStakedlvlUSD() external;

    // conversion functions
    function convertAUSDTtolvlUSD() external returns (uint256);

    // setters
    function setSymbioticVaultAddress(address newAddress) external;

    function setLevelMintingAddress(address newAddress) external;

    function setAaveV3PoolAddress(address newAddress) external;

    function setStakedlvlUSDAddress(address newAddress) external;

    function setUsdtAddress(address newAddress) external;

    function setATokenAddress(address newAddress) external;
}
