import * as helpers from "./index";

import { expect } from "chai";
import { describe } from "mocha";

async function checkSolvency() {
  let karakVaultBal = await helpers.getKarakVaultBalance(
    helpers.sepoliaKarakVault,
    helpers.levelReserveManagerAddress
  );
  let symbioticVaultBal = await helpers.getSymbioticVaultBalance(
    helpers.symbioticVault,
    helpers.levelReserveManagerAddress
  );
  let lvlMintingBal = await helpers.getERC20Balance(
    helpers.aaveSepoliaUSDT,
    helpers.LevelMintingAddress
  );
  let lrmBal = await helpers.getERC20Balance(
    helpers.aaveSepoliaUSDT,
    helpers.levelReserveManagerAddress
  );

  // calculate total lvlUSD and collateral outstanding
  let collateralDecimals = await helpers.getERC20Decimals(
    helpers.aaveSepoliaUSDT
  );
  let lvlUSDSupply = await helpers.getERC2TotalSupply(helpers.lvlUSDAddress);
  let totalCollateral =
    BigInt(karakVaultBal) +
    BigInt(symbioticVaultBal) +
    BigInt(lvlMintingBal) +
    BigInt(lrmBal);

  // check that lvlUSD is fully collateralized
  if (collateralDecimals == 18) {
    expect(totalCollateral >= lvlUSDSupply).to.be.true;
  } else if (collateralDecimals > 18) {
    expect(totalCollateral >= lvlUSDSupply * 10 ** (collateralDecimals - 18)).to
      .be.true;
  } else {
    expect(
      totalCollateral * BigInt(10 ** (18 - collateralDecimals)) >= lvlUSDSupply
    ).to.be.true;
  }
}

describe("Karak Integration Tests", () => {
  afterEach(async function () {
    console.log("checking solvency...");
    await checkSolvency();
  });
  describe("Deposit to Karak", async () => {
    it("it should deposit funds to karak vault", async () => {
      let hash = await helpers.depositToKarak(
        helpers.sepoliaKarakVault,
        BigInt("1")
      );
      expect(hash).to.be.a("string");
    });
  });
  describe("Start redeem from Karak", async () => {
    it("should initiate redeem from karak vault", async () => {
      let hash = await helpers.startRedeemFromKarak(
        helpers.sepoliaKarakVault,
        BigInt("1")
      );
      expect(hash).to.be.a("string");
    });
  });
});

describe("Symbiotic Integration Tests", () => {
  afterEach(async function () {
    console.log("checking solvency...");
    await checkSolvency();
  });
  describe("Deposit to Symbiotic", async () => {
    it("it should deposit funds to symbitoic vault", async () => {
      let hash = await helpers.depositToSymbiotic(
        helpers.symbioticVault,
        BigInt("5")
      );
      expect(hash).to.be.a("string");
    });
  });
  describe("Withdraw from Symbiotic", async () => {
    it("should initiate withdraw from symbiotic vault", async () => {
      let hash = await helpers.withdrawFromSymbiotic(
        helpers.symbioticVault,
        BigInt("1")
      );
      expect(hash).to.be.a("string");
    });
  });
});

// how to get lvlUSD in circulation?
// get total collateral amount - LevelMinting + LRM + vaults

// describe("Aave V3 Integration Tests", () => {
//   describe("Deposit to Aave", async () => {
//     it("it should deposit funds to aave pool", async () => {
//       let hash = await helpers.levelReserveManagerDepositIntoAave(
//         helpers.aaveSepoliaUSDT,
//         BigInt("1")
//       );
//       expect(hash).to.be.a("string");
//     });
//   });
//   describe("Withdraw from Aave", async () => {
//     it("should withdraw funds from aave pool", async () => {
//       let hash = await helpers.levelReserveManagerWithdrawFromAave(
//         helpers.aaveSepoliaUSDT,
//         BigInt("1")
//       );
//       expect(hash).to.be.a("string");
//     });
//   });
// });
