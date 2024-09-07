import { createPublicClient, createWalletClient } from "viem";
import { sepolia, holesky } from "viem/chains";
import { http } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import {
  sepoliaUSDC,
  holeskyUSDT,
  aaveSepoliaUSDT,
  aaveSepoliaPoolProxy,
  sepoliaKarakERC20,
  sepoliaKarakVault,
  lvlUSDAddress,
  LevelMintingAddress,
  stakedlvlUSDAddress,
  levelReserveManagerAddress,
  tether,
} from "./addresses";
import {
  LevelMintingABI,
  lvlUSDABI,
  erc20ABI,
  stakedlvlUSDABI,
  aaveV3PoolABI,
  LevelReserveManagerABI,
} from "./abis/abis";

import { Address } from "viem";
import { parseAbi } from "viem";
import * as dotenv from "dotenv";

// This test file utilizes multiple Sepolia testnet accounts to test mint and redeem flows
// among other on-chain functionalities. This file also includes multiple
// helper methods for granting LevelMinting roles such as MINTER_ROLE and REDEEMER_ROLE,
// as well as ERC20 approvals for Sepolia lvlUSD and Sepolia USDC.

dotenv.config();

const chain = sepolia;

// Local Account
// Note: set your private key using PRIVATE_KEY="..." within apps/server/.env
const privateKey = process.env.SEPOLIA_PRIVATE_KEY;
const minterPrivateKey = process.env.SEPOLIA_MINTER_KEY;
const sepoliaPrivateKey3 = process.env.SEPOLIA_PRIVATE_KEY_3;
const sepoliaPrivateKey4 = process.env.SEPOLIA_PRIVATE_KEY_4;
const sepoliaPrivateKey5 = process.env.SEPOLIA_PRIVATE_KEY_5;
// console.log(privateKey, minterPrivateKey, sepoliaPrivateKey3)

export const adminAccount = privateKeyToAccount(privateKey as Address);
export const minterAccount = privateKeyToAccount(minterPrivateKey as Address);
export const sepoliaAccount3 = privateKeyToAccount(
  sepoliaPrivateKey3 as Address
);
export const sepoliaAccount4 = privateKeyToAccount(
  sepoliaPrivateKey4 as Address
);
export const sepoliaAccount5 = privateKeyToAccount(
  sepoliaPrivateKey5 as Address
);

export const publicClient = createPublicClient({
  chain,
  transport: http(),
});

const walletClient = createWalletClient({
  chain,
  transport: http(),
});

/**
 * @param contractAddress: address of erc20 token
 * @param accountAddress: address of account whose balance we are interested in
 * @returns erc20 balance of account
 */
export async function getERC20Balance(
  contractAddress: Address,
  accountAddress: Address
) {
  const abiItem = parseAbi([
    "function balanceOf(address account) returns (uint256)",
  ]);
  const { request } = await publicClient.simulateContract({
    address: contractAddress,
    abi: abiItem,
    functionName: "balanceOf",
    args: [accountAddress],
  });
  var result = await publicClient.readContract(request);
  return result;
}

export async function getEthBalance(address: Address) {
  return await publicClient.getBalance({ address, blockTag: "safe" });
}

export function generateTestMintOrder() {
  console.log(minterAccount.address);
  return {
    order_type: 0, // Mint
    nonce: BigInt(String(Math.floor(Math.random() * 1000000000000))),
    benefactor: minterAccount.address as Address,
    beneficiary: adminAccount.address as Address,
    collateral_asset: aaveSepoliaUSDT as Address,
    collateral_amount: BigInt("10"),
    lvlusd_amount: BigInt("10"),
  };
}

/**
 *  When we sign an order object to generate a signature, we expect order_type to be
 *  an int (either 0 or 1), but when the user submits an Order, we expect that
 *  field to be 'MINT'or 'REDEEM'.
 *
 *  This convenience function converts an order object that is directly signable
 *  into a JSON order object that a client can submit to the /order POST endpoint.
 */
export function convertOrderToJSONAndSetOrderTypeToString(order: any) {
  order.order_type = order.order_type == 0 ? "MINT" : "REDEEM"; // very important!
  order.nonce = String(order.nonce);
  order.collateral_amount = order.collateral_amount.toString();
  order.lvlusd_amount = order.lvlusd_amount.toString();
  return order;
}

/**
 * @param order: an Order object (can be a mint or redeem order)
 * @param admin: if set to true, uses admin key to sign, otherwise minter key
 * @returns a valid signature
 */
export async function generateTestSignature(order: any, admin = false) {
  const domain = {
    name: "LevelMinting",
    version: "1",
    chainId: 11155111,
    verifyingContract: LevelMintingAddress as any,
  };

  const sig = await walletClient.signTypedData({
    account: admin ? adminAccount : minterAccount,
    domain,
    types,
    primaryType: "Order",
    message: order,
  });
  return sig;
}

/**
 * Currently unused, since routes are loaded from server config file.
 */
export function generateTestRoute() {
  return {
    addresses: ["0x74C3dC2F48b9cc5f167B0C8AE09FbbDc6315f519" as `0x${string}`],
    ratios: [BigInt("10000")],
  };
}

/**
 * @returns a redeem order that attempts to burn benefactor's (adminAccount) lvlUSD and send USDC
 * stored in the contract to the beneficiary (minterAccount)
 */
export function generateTestRedeemOrder() {
  return {
    order_type: 1, // Redeem
    nonce: BigInt(String(Math.floor(Math.random() * 1000000000000))),
    benefactor: adminAccount.address as Address,
    beneficiary: minterAccount.address as Address,
    collateral_asset: holeskyUSDT as Address, // Sepolia USDC
    collateral_amount: BigInt("1"),
    lvlusd_amount: BigInt("1"),
  };
}

// Sample quote:
// {
//   id: '2a7aac89-9b4b-4cb0-a266-937754ec1da5',
//   requestId: 'e12e5231-a336-4147-8e0a-cfc99b4b2114',
//   pair: 'USDC/lvlUSD',
//   side: 'MINT',
//   size: '1',
//   amount: '1000149990000',
//   collateralAssetAddress: '0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238',
//   lvlusdAddress: '0x78C4840A402e42A8Bc463F3dAd61324C09fE8624',
//   collateralAmount: '123',
//   lvlusdAmount: '1',
//   gas: '2',
//   createdAt: '2024-06-18T22:50:32.024Z',
//   expiresAt: '2024-06-18T18:50:32.525Z'
// }
// TODO
export function generateOrderFromQuote(
  quote: any,
  benefactor: Address = adminAccount.address,
  beneficiary: Address = minterAccount.address
) {
  if (quote.side !== "MINT" && quote.side !== "REDEEM") {
    throw new Error(
      `quote.side must be 'MINT' or 'REDEEM', instead got ${quote.side}`
    );
  }
  return {
    order_type: quote.side === "MINT" ? 0 : 1, // Mint
    nonce: String(Math.floor(Math.random() * 1000000000000)),
    benefactor,
    beneficiary,
    collateral_asset: quote.collateralAssetAddress as Address,
    collateral_amount: quote.collateralAmount,
    lvlusd_amount: quote.lvlusdAmount,
  };
}

export const types = {
  Order: [
    { name: "order_type", type: "uint8" },
    { name: "nonce", type: "uint256" },
    { name: "benefactor", type: "address" },
    { name: "beneficiary", type: "address" },
    { name: "collateral_asset", type: "address" },
    { name: "collateral_amount", type: "uint256" },
    { name: "lvlusd_amount", type: "uint256" },
  ],
} as const;

export async function approve(account = adminAccount) {
  const abiItem = parseAbi([
    "function approve(address spender, uint256 amount) returns (bool)",
  ]);
  const { request } = await publicClient.simulateContract({
    account: account,
    address: aaveSepoliaUSDT,
    abi: abiItem,
    functionName: "approve",
    args: [LevelMintingAddress, BigInt(1000000000000)],
  });
  var hash = await walletClient.writeContract(request);
  console.log("approve txn hash: ", hash);
  return hash;
}

export async function getERC20Decimals(contractAddress: Address) {
  const abiItem = parseAbi(["function decimals() public view returns (uint8)"]);
  const { request } = await publicClient.simulateContract({
    address: contractAddress,
    abi: abiItem,
    functionName: "decimals",
    args: [],
  });
  var result = await publicClient.readContract(request);
  return result;
}

export async function getERC2TotalSupply(contractAddress: Address) {
  const abiItem = parseAbi([
    "function totalSupply() public view returns (uint256)",
  ]);
  const { request } = await publicClient.simulateContract({
    address: contractAddress,
    abi: abiItem,
    functionName: "totalSupply",
    args: [],
  });
  var result = await publicClient.readContract(request);
  return result;
}

/**
 * It is necessary for account to approve LevelMinting as LvlUSD spender in redeem flow,
 * because LevelMinting calls burnFrom to burn lvlUSD held by account
 */
export async function approveLvlUSD(account = minterAccount) {
  const abiItem = parseAbi([
    "function approve(address spender, uint256 amount) returns (bool)",
  ]);
  const { request } = await publicClient.simulateContract({
    account: account,
    address: lvlUSDAddress,
    abi: abiItem,
    functionName: "approve",
    args: [LevelMintingAddress, BigInt(1000000000000)],
  });
  var hash = await walletClient.writeContract(request);
  console.log("approve lvlUSD txn hash: ", hash);
  return hash;
}

/**
 * Helper method for minting lvlUSD by putting up collateral assets.
 */
export async function mint(simulateOnly = true) {
  const mintOrder = generateTestMintOrder();
  const route = generateTestRoute();

  const { request } = await publicClient.simulateContract({
    account: minterAccount,
    address: LevelMintingAddress,
    abi: LevelMintingABI,
    functionName: "mint",
    args: [mintOrder, route],
  });

  console.log("mint simulation successful");

  if (simulateOnly) {
    const text = "simulate mint successful";
    console.log("mint: ", text);
    return text;
  }

  var hash = await walletClient.writeContract(request);
  console.log("mint txn hash: ", hash);
  return hash;
}

export async function issueTether() {
  const abiItem = parseAbi(["function issue(uint amount)"]);
  const { request } = await publicClient.simulateContract({
    account: adminAccount,
    address: tether,
    abi: abiItem,
    functionName: "issue",
    args: [BigInt("100000000000000000000000")],
  });
  var hash = await walletClient.writeContract(request);
  console.log("issue tether txn hash: ", hash);
  return hash;
}

/**
 * Helper method for burning lvlUSD and redeeming collateral assets.
 */
async function redeem() {
  const redeemOrder = await generateTestRedeemOrder();
  const route = generateTestRoute();
  const { request } = await publicClient.simulateContract({
    account: adminAccount,
    address: LevelMintingAddress,
    abi: LevelMintingABI,
    functionName: "redeem",
    args: [redeemOrder],
  });
  var hash = await walletClient.writeContract(request);
  console.log("redeem txn hash: ", hash);
  return hash;
}

export async function addSupportedAsset(asset: Address) {
  const { request } = await publicClient.simulateContract({
    account: adminAccount,
    address: LevelMintingAddress,
    abi: LevelMintingABI,
    functionName: "addSupportedAsset",
    args: [asset],
  });
  var hash = await walletClient.writeContract(request);
  console.log("addSupportedAsset txn hash: ", hash);
  return hash;
}

export async function setMaxMintPerBlock(amount: bigint) {
  const { request } = await publicClient.simulateContract({
    account: adminAccount,
    address: LevelMintingAddress,
    abi: LevelMintingABI,
    functionName: "setMaxMintPerBlock",
    args: [amount],
  });
  var hash = await walletClient.writeContract(request);
  console.log("setMaxMintPerBlock txn hash: ", hash);
  return hash;
}

export async function setMaxRedeemPerBlock(amount: bigint) {
  const { request } = await publicClient.simulateContract({
    account: adminAccount,
    address: LevelMintingAddress,
    abi: LevelMintingABI,
    functionName: "setMaxRedeemPerBlock",
    args: [amount],
  });
  var hash = await walletClient.writeContract(request);
  console.log("setMaxRedeemPerBlock txn hash: ", hash);
  return hash;
}

export async function addReserveAddress(address: Address) {
  const { request } = await publicClient.simulateContract({
    account: adminAccount,
    address: LevelMintingAddress,
    abi: LevelMintingABI,
    functionName: "addReserveAddress",
    args: [address],
  });
  var hash = await walletClient.writeContract(request);
  console.log("addReserveAddress txn hash: ", hash);
  return hash;
}

export async function grantRole(role: `0x${string}`, address: Address) {
  const { request } = await publicClient.simulateContract({
    account: adminAccount,
    address: LevelMintingAddress,
    abi: LevelMintingABI,
    functionName: "grantRole",
    args: [role, address],
  });
  var hash = await walletClient.writeContract(request);
  console.log("grantRole txn hash: ", hash);
  return hash;
}

/**
 * Check if an address has a specific role, for example:
 * keccak256(toHex("REDEEMER_ROLE"))
 */
export async function hasRole(role: `0x${string}`, address: Address) {
  const { request } = await publicClient.simulateContract({
    address: LevelMintingAddress,
    abi: LevelMintingABI,
    //@ts-ignore
    functionName: "hasRole",
    args: [role, address],
  });
  var data = await publicClient.readContract(request);
  console.log("hasRole txn data: ", data);
  return data;
}

/**
 * Set minter in lvlUSD contract (who has authority to mint lvlUSD).
 */
export async function setLvlUSDMinter() {
  const { request } = await publicClient.simulateContract({
    account: adminAccount,
    address: lvlUSDAddress,
    abi: lvlUSDABI,
    functionName: "setMinter",
    args: [LevelMintingAddress],
  });
  var data = await walletClient.writeContract(request);
  console.log("lvlUSDSetMinter txn data: ", data);
  return data;
}

/**
 * @returns address of minter in lvlUSD contract
 */
export async function getLvlUSDMinter() {
  const { request } = await publicClient.simulateContract({
    address: lvlUSDAddress,
    abi: lvlUSDABI,
    //@ts-ignore
    functionName: "minter",
    args: [],
  });
  var data = await publicClient.readContract(request);
  console.log("getLvlUSDMinter txn data: ", data);
  return data;
}

/**
 * @returns address of lvlUSD associated with LevelMinting contract
 */
export async function getLvlUSDAddress() {
  const { request } = await publicClient.simulateContract({
    address: LevelMintingAddress,
    abi: LevelMintingABI,
    //@ts-ignore
    functionName: "lvlusd",
    args: [],
  });
  var data = await publicClient.readContract(request);
  console.log("getLvlUSDAddress txn data: ", data);
  return data;
}

// grant approval for the StakedlvlUSD contract to spend your lvlUSD
export async function lvlUSDApproveStakedlvlUSD() {
  const abiItem = parseAbi([
    "function approve(address spender, uint256 amount) returns (bool)",
  ]);
  const account = adminAccount;
  const { request } = await publicClient.simulateContract({
    account: account,
    address: lvlUSDAddress,
    abi: abiItem,
    functionName: "approve",
    args: [stakedlvlUSDAddress, BigInt(1000000000000)],
  });
  var hash = await walletClient.writeContract(request);
  console.log("approve StakedlvlUSD contract to spend lvlUSD txn hash: ", hash);
  return hash;
}

export async function depositIntoStakedlvlUSD() {
  const { request } = await publicClient.simulateContract({
    account: adminAccount,
    address: stakedlvlUSDAddress,
    abi: stakedlvlUSDABI,
    functionName: "deposit",
    args: [BigInt("2"), adminAccount.address],
  });
  var hash = await walletClient.writeContract(request);
  console.log("deposit into StakedlvlUSD txn hash: ", hash);
  return hash;
}

export async function setCooldownDuration() {
  const { request } = await publicClient.simulateContract({
    account: adminAccount,
    address: stakedlvlUSDAddress,
    abi: stakedlvlUSDABI,
    functionName: "setCooldownDuration",
    args: [1],
  });
  var hash = await walletClient.writeContract(request);
  console.log("setCooldownDuration txn hash: ", hash);
  return hash;
}

export async function cooldownShares() {
  const { request } = await publicClient.simulateContract({
    account: adminAccount,
    address: stakedlvlUSDAddress,
    abi: stakedlvlUSDABI,
    functionName: "cooldownShares",
    args: [BigInt("1"), adminAccount.address],
  });
  var hash = await walletClient.writeContract(request);
  console.log("cooldownShares txn hash: ", hash);
  return hash;
}

export async function unstake() {
  const { request } = await publicClient.simulateContract({
    account: adminAccount,
    address: stakedlvlUSDAddress,
    abi: stakedlvlUSDABI,
    functionName: "unstake",
    args: [adminAccount.address],
  });
  var hash = await walletClient.writeContract(request);
  console.log("unstake txn hash: ", hash);
  return hash;
}

export async function grantRoleStakedlvlUSD(
  role: `0x${string}`,
  address: Address
) {
  const { request } = await publicClient.simulateContract({
    account: adminAccount,
    address: stakedlvlUSDAddress,
    abi: stakedlvlUSDABI,
    functionName: "grantRole",
    args: [role, address],
  });
  var hash = await walletClient.writeContract(request);
  console.log("grantRole staked lvlUSD txn hash: ", hash);
  return hash;
}

export async function transferInRewards() {
  const { request } = await publicClient.simulateContract({
    account: adminAccount,
    address: stakedlvlUSDAddress,
    abi: stakedlvlUSDABI,
    functionName: "transferInRewards",
    args: [BigInt("1")],
  });
  var hash = await walletClient.writeContract(request);
  console.log("transferInRewards txn hash: ", hash);
  return hash;
}

///
/// Level Reserve Manager (LRM) helpers
///

export async function levelReserveManagerTransferERC20(
  token: Address,
  to: Address,
  amount: bigint,
  account = adminAccount
) {
  const { request } = await publicClient.simulateContract({
    account: account,
    address: levelReserveManagerAddress,
    abi: LevelReserveManagerABI,
    functionName: "transferERC20",
    args: [token, to, amount],
  });
  var hash = await walletClient.writeContract(request);
  console.log("LRM transfer ERC20 txn hash: ", hash);
  return hash;
}

export async function levelReserveManagerTransferETH(
  to: Address,
  amount: bigint,
  account = adminAccount
) {
  const { request } = await publicClient.simulateContract({
    account: account,
    address: levelReserveManagerAddress,
    abi: LevelReserveManagerABI,
    functionName: "transferEth",
    args: [to, amount],
  });
  var hash = await walletClient.writeContract(request);
  console.log("LRM transfer ETH txn hash: ", hash);
  return hash;
}

export async function levelReserveManagerApproveSpender(
  token: Address,
  spender: Address,
  amount: bigint,
  account = adminAccount
) {
  const { request } = await publicClient.simulateContract({
    account: account,
    address: levelReserveManagerAddress,
    abi: LevelReserveManagerABI,
    functionName: "approveSpender",
    args: [token, spender, amount],
  });
  var hash = await walletClient.writeContract(request);
  console.log("LRM approve spender txn hash: ", hash);
  return hash;
}

export async function levelReserveManagerDepositIntoAave(
  token: Address,
  amount: bigint,
  account = adminAccount
) {
  const { request } = await publicClient.simulateContract({
    account: account,
    address: levelReserveManagerAddress,
    abi: LevelReserveManagerABI,
    functionName: "depositToAave",
    args: [token, amount],
  });
  var hash = await walletClient.writeContract(request);
  console.log("LRM deposit to AAVE txn hash: ", hash);
  return hash;
}

export async function levelReserveManagerWithdrawFromAave(
  token: Address,
  amount: bigint,
  account = adminAccount
) {
  const { request } = await publicClient.simulateContract({
    account: account,
    address: levelReserveManagerAddress,
    abi: LevelReserveManagerABI,
    functionName: "withdrawFromAave",
    args: [token, amount],
  });
  var hash = await walletClient.writeContract(request);
  console.log("LRM withdraw from AAVE txn hash: ", hash);
  return hash;
}

export async function convertATokensTolvlUSDAndDepositIntoStakedlvlUSD(
  aToken: Address,
  amount: bigint,
  account = adminAccount
) {
  const { request } = await publicClient.simulateContract({
    account: account,
    address: levelReserveManagerAddress,
    abi: LevelReserveManagerABI,
    functionName: "convertATokensTolvlUSDAndDepositIntoStakedlvlUSD",
    args: [aToken, amount],
  });
  var hash = await walletClient.writeContract(request);
  console.log(
    "LRM convertATokensTolvlUSDAndDepositIntoStakedlvlUSD txn hash: ",
    hash
  );
  return hash;
}

export async function mintlvlUSD(
  collateral: Address,
  amount: bigint,
  account = adminAccount
) {
  const { request } = await publicClient.simulateContract({
    account: account,
    address: levelReserveManagerAddress,
    abi: LevelReserveManagerABI,
    functionName: "mintlvlUSD",
    args: [collateral, amount],
  });
  var hash = await walletClient.writeContract(request);
  console.log("LRM mintlvlUSD txn hash: ", hash);
  return hash;
}

export async function convertATokentolvlUSD(
  underlying: Address,
  amount: bigint,
  account = adminAccount
) {
  const { request } = await publicClient.simulateContract({
    account: account,
    address: levelReserveManagerAddress,
    abi: LevelReserveManagerABI,
    functionName: "convertATokentolvlUSD",
    args: [underlying, amount],
  });
  var hash = await walletClient.writeContract(request);
  console.log("LRM convertATokentolvlUSD txn hash: ", hash);
  return hash;
}

export async function depositToStakedlvlUSD(
  amount: bigint,
  account = adminAccount
) {
  const { request } = await publicClient.simulateContract({
    account: account,
    address: levelReserveManagerAddress,
    abi: LevelReserveManagerABI,
    functionName: "depositToStakedlvlUSD",
    args: [amount],
  });
  var hash = await walletClient.writeContract(request);
  console.log("LRM depositToStakedlvlUSD txn hash: ", hash);
  return hash;
}

export async function depositToKarak(vault: Address, amount: bigint) {
  const account = adminAccount;
  const { request } = await publicClient.simulateContract({
    account: account,
    address: levelReserveManagerAddress,
    abi: LevelReserveManagerABI,
    functionName: "depositToKarak",
    args: [vault, amount],
  });
  var hash = await walletClient.writeContract(request);
  console.log("deposit to Karak txn: ", hash);
  return hash;
}

export async function startRedeemFromKarak(vault: Address, shares: bigint) {
  const account = adminAccount;
  const { request } = await publicClient.simulateContract({
    account: account,
    address: levelReserveManagerAddress,
    abi: LevelReserveManagerABI,
    functionName: "startRedeemFromKarak",
    args: [vault, shares],
  });
  var hash = await walletClient.writeContract(request);
  console.log("start redeem from Karak txn: ", hash);
  return hash;
}

export async function finishRedeemFromKarak(
  vault: Address,
  withdrawalKey: `0x${string}`
) {
  const account = adminAccount;
  const { request } = await publicClient.simulateContract({
    account: account,
    address: levelReserveManagerAddress,
    abi: LevelReserveManagerABI,
    functionName: "finishRedeemFromKarak",
    args: [vault, withdrawalKey],
  });
  var hash = await walletClient.writeContract(request);
  console.log("finish redeem from Karak txn: ", hash);
  return hash;
}

export async function depositToSymbiotic(vault: Address, amount: bigint) {
  const account = adminAccount;
  const { request } = await publicClient.simulateContract({
    account: account,
    address: levelReserveManagerAddress,
    abi: LevelReserveManagerABI,
    functionName: "depositToSymbiotic",
    args: [vault, amount],
  });
  var hash = await walletClient.writeContract(request);
  console.log("deposit to Symbiotic txn: ", hash);
  return hash;
}

export async function withdrawFromSymbiotic(vault: Address, amount: bigint) {
  const account = adminAccount;
  const { request } = await publicClient.simulateContract({
    account: account,
    address: levelReserveManagerAddress,
    abi: LevelReserveManagerABI,
    functionName: "withdrawFromSymbiotic",
    args: [vault, amount],
  });
  var hash = await walletClient.writeContract(request);
  console.log("withdraw from Symbiotic txn: ", hash);
  return hash;
}

export async function getSymbioticVaultBalance(vault: Address, user: Address) {
  const abiItem = parseAbi([
    "function activeBalanceOf(address account) external view returns (uint256)",
  ]);
  const { request } = await publicClient.simulateContract({
    address: vault,
    abi: abiItem,
    functionName: "activeBalanceOf",
    args: [user],
  });
  var result = await publicClient.readContract(request);
  return result;
}

///
/// Karak helpers
///

export async function getKarakVaultBalance(vault: Address, user: Address) {
  const abiItem = parseAbi([
    "function balanceOf(address owner) public view returns (uint256)",
  ]);
  const { request } = await publicClient.simulateContract({
    address: vault,
    abi: abiItem,
    functionName: "balanceOf",
    args: [user],
  });
  var result = await publicClient.readContract(request);
  return result;
}

// https://docs.karak.network/protocol/v2/contracts
export async function mintKarakVaultToken() {
  const abiItem = parseAbi(["function mint(address to, uint256 amount)"]);
  const account = adminAccount;
  const { request } = await publicClient.simulateContract({
    account: account,
    address: "0x3c491C4427B00b2eB264298E03655A83E1FddB9E", // Karak Sepolia test token
    abi: abiItem,
    functionName: "mint",
    args: ["0x74C3dC2F48b9cc5f167B0C8AE09FbbDc6315f519", BigInt(1000000000000)],
  });
  var hash = await walletClient.writeContract(request);
  console.log("mint Karak ERC20: ", hash);
  return hash;
}

///
/// Aave helpers
///

export async function mintAaveUSDT() {
  const abiItem = parseAbi(["function mint(address account, uint256 value)"]);
  const account = adminAccount;
  const { request } = await publicClient.simulateContract({
    account: account,
    address: aaveSepoliaUSDT,
    abi: abiItem,
    functionName: "mint",
    args: ["0x74C3dC2F48b9cc5f167B0C8AE09FbbDc6315f519", BigInt(1000000000000)],
  });
  var hash = await walletClient.writeContract(request);
  console.log("mint AAVE USDT: ", hash);
  return hash;
}

export async function depositAaveV3Pool() {
  const abiItem = parseAbi([
    "function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode)",
  ]);
  const account = adminAccount;
  const { request } = await publicClient.simulateContract({
    account: account,
    address: aaveSepoliaPoolProxy,
    abi: abiItem,
    functionName: "deposit",
    args: [aaveSepoliaUSDT, BigInt(10), adminAccount.address, 0],
  });
  var hash = await walletClient.writeContract(request);
  console.log("deposit AAVE USDT: ", hash);
  return hash;
}
