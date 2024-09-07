export const LevelMintingABI = [
  {
    type: "constructor",
    inputs: [
      {
        name: "_lvlusd",
        type: "address",
        internalType: "contract IlvlUSD",
      },
      { name: "_assets", type: "address[]", internalType: "address[]" },
      {
        name: "_reserves",
        type: "address[]",
        internalType: "address[]",
      },
      { name: "_admin", type: "address", internalType: "address" },
      {
        name: "_maxMintPerBlock",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_maxRedeemPerBlock",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "DEFAULT_ADMIN_ROLE",
    inputs: [],
    outputs: [{ name: "", type: "bytes32", internalType: "bytes32" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "acceptAdmin",
    inputs: [],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "addReserveAddress",
    inputs: [{ name: "reserve", type: "address", internalType: "address" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "addSupportedAsset",
    inputs: [{ name: "asset", type: "address", internalType: "address" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "delegatedSigner",
    inputs: [
      { name: "", type: "address", internalType: "address" },
      { name: "", type: "address", internalType: "address" },
    ],
    outputs: [{ name: "", type: "bool", internalType: "bool" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "disableMintRedeem",
    inputs: [],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "encodeOrder",
    inputs: [
      {
        name: "order",
        type: "tuple",
        internalType: "struct ILevelMinting.Order",
        components: [
          {
            name: "order_type",
            type: "uint8",
            internalType: "enum ILevelMinting.OrderType",
          },
          { name: "nonce", type: "uint256", internalType: "uint256" },
          {
            name: "benefactor",
            type: "address",
            internalType: "address",
          },
          {
            name: "beneficiary",
            type: "address",
            internalType: "address",
          },
          {
            name: "collateral_asset",
            type: "address",
            internalType: "address",
          },
          {
            name: "collateral_amount",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "lvlusd_amount",
            type: "uint256",
            internalType: "uint256",
          },
        ],
      },
    ],
    outputs: [{ name: "", type: "bytes", internalType: "bytes" }],
    stateMutability: "pure",
  },
  {
    type: "function",
    name: "getDomainSeparator",
    inputs: [],
    outputs: [{ name: "", type: "bytes32", internalType: "bytes32" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getRoleAdmin",
    inputs: [{ name: "role", type: "bytes32", internalType: "bytes32" }],
    outputs: [{ name: "", type: "bytes32", internalType: "bytes32" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "grantRole",
    inputs: [
      { name: "role", type: "bytes32", internalType: "bytes32" },
      { name: "account", type: "address", internalType: "address" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "hasRole",
    inputs: [
      { name: "role", type: "bytes32", internalType: "bytes32" },
      { name: "account", type: "address", internalType: "address" },
    ],
    outputs: [{ name: "", type: "bool", internalType: "bool" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "hashOrder",
    inputs: [
      {
        name: "order",
        type: "tuple",
        internalType: "struct ILevelMinting.Order",
        components: [
          {
            name: "order_type",
            type: "uint8",
            internalType: "enum ILevelMinting.OrderType",
          },
          { name: "nonce", type: "uint256", internalType: "uint256" },
          {
            name: "benefactor",
            type: "address",
            internalType: "address",
          },
          {
            name: "beneficiary",
            type: "address",
            internalType: "address",
          },
          {
            name: "collateral_asset",
            type: "address",
            internalType: "address",
          },
          {
            name: "collateral_amount",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "lvlusd_amount",
            type: "uint256",
            internalType: "uint256",
          },
        ],
      },
    ],
    outputs: [{ name: "", type: "bytes32", internalType: "bytes32" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "isSupportedAsset",
    inputs: [{ name: "asset", type: "address", internalType: "address" }],
    outputs: [{ name: "", type: "bool", internalType: "bool" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "lvlusd",
    inputs: [],
    outputs: [{ name: "", type: "address", internalType: "contract IlvlUSD" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "maxMintPerBlock",
    inputs: [],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "maxRedeemPerBlock",
    inputs: [],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "mint",
    inputs: [
      {
        name: "order",
        type: "tuple",
        internalType: "struct ILevelMinting.Order",
        components: [
          {
            name: "order_type",
            type: "uint8",
            internalType: "enum ILevelMinting.OrderType",
          },
          { name: "nonce", type: "uint256", internalType: "uint256" },
          {
            name: "benefactor",
            type: "address",
            internalType: "address",
          },
          {
            name: "beneficiary",
            type: "address",
            internalType: "address",
          },
          {
            name: "collateral_asset",
            type: "address",
            internalType: "address",
          },
          {
            name: "collateral_amount",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "lvlusd_amount",
            type: "uint256",
            internalType: "uint256",
          },
        ],
      },
      {
        name: "route",
        type: "tuple",
        internalType: "struct ILevelMinting.Route",
        components: [
          {
            name: "addresses",
            type: "address[]",
            internalType: "address[]",
          },
          {
            name: "ratios",
            type: "uint256[]",
            internalType: "uint256[]",
          },
        ],
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "mintedPerBlock",
    inputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "owner",
    inputs: [],
    outputs: [{ name: "", type: "address", internalType: "address" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "redeem",
    inputs: [
      {
        name: "order",
        type: "tuple",
        internalType: "struct ILevelMinting.Order",
        components: [
          {
            name: "order_type",
            type: "uint8",
            internalType: "enum ILevelMinting.OrderType",
          },
          { name: "nonce", type: "uint256", internalType: "uint256" },
          {
            name: "benefactor",
            type: "address",
            internalType: "address",
          },
          {
            name: "beneficiary",
            type: "address",
            internalType: "address",
          },
          {
            name: "collateral_asset",
            type: "address",
            internalType: "address",
          },
          {
            name: "collateral_amount",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "lvlusd_amount",
            type: "uint256",
            internalType: "uint256",
          },
        ],
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "redeemedPerBlock",
    inputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "removeReserveAddress",
    inputs: [{ name: "reserve", type: "address", internalType: "address" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "removeDelegatedSigner",
    inputs: [
      {
        name: "_removedSigner",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "removeMinterRole",
    inputs: [{ name: "minter", type: "address", internalType: "address" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "removeRedeemerRole",
    inputs: [{ name: "redeemer", type: "address", internalType: "address" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "removeSupportedAsset",
    inputs: [{ name: "asset", type: "address", internalType: "address" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "renounceRole",
    inputs: [
      { name: "role", type: "bytes32", internalType: "bytes32" },
      { name: "account", type: "address", internalType: "address" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "revokeRole",
    inputs: [
      { name: "role", type: "bytes32", internalType: "bytes32" },
      { name: "account", type: "address", internalType: "address" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "setDelegatedSigner",
    inputs: [{ name: "_delegateTo", type: "address", internalType: "address" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "setMaxMintPerBlock",
    inputs: [
      {
        name: "_maxMintPerBlock",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "setMaxRedeemPerBlock",
    inputs: [
      {
        name: "_maxRedeemPerBlock",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "supportsInterface",
    inputs: [{ name: "interfaceId", type: "bytes4", internalType: "bytes4" }],
    outputs: [{ name: "", type: "bool", internalType: "bool" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "transferAdmin",
    inputs: [{ name: "newAdmin", type: "address", internalType: "address" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "transferToReserve",
    inputs: [
      { name: "wallet", type: "address", internalType: "address" },
      { name: "asset", type: "address", internalType: "address" },
      { name: "amount", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "verifyNonce",
    inputs: [
      { name: "sender", type: "address", internalType: "address" },
      { name: "nonce", type: "uint256", internalType: "uint256" },
    ],
    outputs: [
      { name: "", type: "bool", internalType: "bool" },
      { name: "", type: "uint256", internalType: "uint256" },
      { name: "", type: "uint256", internalType: "uint256" },
      { name: "", type: "uint256", internalType: "uint256" },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "verifyOrder",
    inputs: [
      {
        name: "order",
        type: "tuple",
        internalType: "struct ILevelMinting.Order",
        components: [
          {
            name: "order_type",
            type: "uint8",
            internalType: "enum ILevelMinting.OrderType",
          },
          { name: "nonce", type: "uint256", internalType: "uint256" },
          {
            name: "benefactor",
            type: "address",
            internalType: "address",
          },
          {
            name: "beneficiary",
            type: "address",
            internalType: "address",
          },
          {
            name: "collateral_asset",
            type: "address",
            internalType: "address",
          },
          {
            name: "collateral_amount",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "lvlusd_amount",
            type: "uint256",
            internalType: "uint256",
          },
        ],
      },
    ],
    outputs: [
      { name: "", type: "bool", internalType: "bool" },
      { name: "", type: "bytes32", internalType: "bytes32" },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "verifyRoute",
    inputs: [
      {
        name: "route",
        type: "tuple",
        internalType: "struct ILevelMinting.Route",
        components: [
          {
            name: "addresses",
            type: "address[]",
            internalType: "address[]",
          },
          {
            name: "ratios",
            type: "uint256[]",
            internalType: "uint256[]",
          },
        ],
      },
      {
        name: "orderType",
        type: "uint8",
        internalType: "enum ILevelMinting.OrderType",
      },
    ],
    outputs: [{ name: "", type: "bool", internalType: "bool" }],
    stateMutability: "view",
  },
  {
    type: "event",
    name: "AdminTransferRequested",
    inputs: [
      {
        name: "oldAdmin",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "newAdmin",
        type: "address",
        indexed: true,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "AdminTransferred",
    inputs: [
      {
        name: "oldAdmin",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "newAdmin",
        type: "address",
        indexed: true,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "AssetAdded",
    inputs: [
      {
        name: "asset",
        type: "address",
        indexed: true,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "AssetRemoved",
    inputs: [
      {
        name: "asset",
        type: "address",
        indexed: true,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "ReserveAddressAdded",
    inputs: [
      {
        name: "reserve",
        type: "address",
        indexed: true,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "ReserveAddressRemoved",
    inputs: [
      {
        name: "reserve",
        type: "address",
        indexed: true,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "ReserveTransfer",
    inputs: [
      {
        name: "wallet",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "asset",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "amount",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "ReserveWalletAdded",
    inputs: [
      {
        name: "wallet",
        type: "address",
        indexed: false,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "ReserveWalletRemoved",
    inputs: [
      {
        name: "wallet",
        type: "address",
        indexed: false,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "DelegatedSignerAdded",
    inputs: [
      {
        name: "signer",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "delegator",
        type: "address",
        indexed: true,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "DelegatedSignerRemoved",
    inputs: [
      {
        name: "signer",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "delegator",
        type: "address",
        indexed: true,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "MaxMintPerBlockChanged",
    inputs: [
      {
        name: "oldMaxMintPerBlock",
        type: "uint256",
        indexed: true,
        internalType: "uint256",
      },
      {
        name: "newMaxMintPerBlock",
        type: "uint256",
        indexed: true,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "MaxRedeemPerBlockChanged",
    inputs: [
      {
        name: "oldMaxRedeemPerBlock",
        type: "uint256",
        indexed: true,
        internalType: "uint256",
      },
      {
        name: "newMaxRedeemPerBlock",
        type: "uint256",
        indexed: true,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "Mint",
    inputs: [
      {
        name: "minter",
        type: "address",
        indexed: false,
        internalType: "address",
      },
      {
        name: "benefactor",
        type: "address",
        indexed: false,
        internalType: "address",
      },
      {
        name: "beneficiary",
        type: "address",
        indexed: false,
        internalType: "address",
      },
      {
        name: "collateral_asset",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "collateral_amount",
        type: "uint256",
        indexed: true,
        internalType: "uint256",
      },
      {
        name: "lvlusd_amount",
        type: "uint256",
        indexed: true,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "Received",
    inputs: [
      {
        name: "",
        type: "address",
        indexed: false,
        internalType: "address",
      },
      {
        name: "",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "Redeem",
    inputs: [
      {
        name: "redeemer",
        type: "address",
        indexed: false,
        internalType: "address",
      },
      {
        name: "benefactor",
        type: "address",
        indexed: false,
        internalType: "address",
      },
      {
        name: "beneficiary",
        type: "address",
        indexed: false,
        internalType: "address",
      },
      {
        name: "collateral_asset",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "collateral_amount",
        type: "uint256",
        indexed: true,
        internalType: "uint256",
      },
      {
        name: "lvlusd_amount",
        type: "uint256",
        indexed: true,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "RoleAdminChanged",
    inputs: [
      {
        name: "role",
        type: "bytes32",
        indexed: true,
        internalType: "bytes32",
      },
      {
        name: "previousAdminRole",
        type: "bytes32",
        indexed: true,
        internalType: "bytes32",
      },
      {
        name: "newAdminRole",
        type: "bytes32",
        indexed: true,
        internalType: "bytes32",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "RoleGranted",
    inputs: [
      {
        name: "role",
        type: "bytes32",
        indexed: true,
        internalType: "bytes32",
      },
      {
        name: "account",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "sender",
        type: "address",
        indexed: true,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "RoleRevoked",
    inputs: [
      {
        name: "role",
        type: "bytes32",
        indexed: true,
        internalType: "bytes32",
      },
      {
        name: "account",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "sender",
        type: "address",
        indexed: true,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "lvlUSDSet",
    inputs: [
      {
        name: "lvlUSD",
        type: "address",
        indexed: true,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  { type: "error", name: "Duplicate", inputs: [] },
  { type: "error", name: "OnlyMinter", inputs: [] },
  { type: "error", name: "InvalidAddress", inputs: [] },
  { type: "error", name: "InvalidAdminChange", inputs: [] },
  { type: "error", name: "InvalidAffirmedAmount", inputs: [] },
  { type: "error", name: "InvalidAmount", inputs: [] },
  { type: "error", name: "InvalidAssetAddress", inputs: [] },
  { type: "error", name: "InvalidReserveAddress", inputs: [] },
  { type: "error", name: "InvalidNonce", inputs: [] },
  { type: "error", name: "InvalidOrder", inputs: [] },
  { type: "error", name: "InvalidRoute", inputs: [] },
  { type: "error", name: "InvalidSignature", inputs: [] },
  { type: "error", name: "InvalidZeroAddress", inputs: [] },
  { type: "error", name: "InvalidlvlUSDAddress", inputs: [] },
  { type: "error", name: "MaxMintPerBlockExceeded", inputs: [] },
  { type: "error", name: "MaxRedeemPerBlockExceeded", inputs: [] },
  { type: "error", name: "NoAssetsProvided", inputs: [] },
  { type: "error", name: "NotPendingAdmin", inputs: [] },
  { type: "error", name: "SignatureExpired", inputs: [] },
  { type: "error", name: "TransferFailed", inputs: [] },
  { type: "error", name: "UnsupportedAsset", inputs: [] },
] as const;
