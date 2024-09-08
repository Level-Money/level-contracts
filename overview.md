## Summary

The Level Protocol allows users to earn yield from restaking protocols and lending protocols by
staking a stablecoin called lvlUSD. Level will generate returns by lending out its reserves in Aave and Compound,
and further earn points restaking rewards for users by depositing liquid restaking tokens in Symbiotic, Eigenlayer, and Karak vaults.

LevelMinting is the contract for minting and redeeming lvlUSD. The redemption process has two steps and can take several
days due to a cooldown period. Collateral provided by users is routed to the LevelReserveManager. An admin multisig wallet
controls the funds in LevelReserveManager, and can initiate deposits and withdrawals into pools and vaults.

When funds are deposited into Symbiotic or Karak vaults, they are delegated to networks, for example, actively validated services (AVSes), or operators, who run node network infrastructure. The vaults may accrue rewards, or rewards may be sent to a pre-specified rewards contract. The funds in the vault may also be slashed, depending on the vault implementation.

## Dependencies
### Karak
- Karak is a restaking layer that provides security for chains by connecting stakers with operators and networks ([Docs](https://docs.karak.network/))
- Source code for [vaults](https://github.com/code-423n4/2024-07-karak/blob/main/src/interfaces/IVault.sol)

### Symbiotic
- Symbiotic is an accounting and coordination layer for networks, operators, and vaults to work together to provide economic security to networks ([Docs](https://docs.symbiotic.fi/))
- Source code for [vaults](https://github.com/symbioticfi/core/blob/main/src/contracts/vault/Vault.sol)