// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "./interfaces/IlvUSDDefinitions.sol";
import "./SingleAdminAccessControl.sol";
import "forge-std/console.sol";

/**
 * @title lvUSD
 * @notice lvUSD contract
 */
contract lvUSD is
    ERC20Burnable,
    ERC20Permit,
    IlvUSDDefinitions,
    SingleAdminAccessControl
{
    /// @notice The role that is allowed to denylist and un-denylist addresses
    bytes32 private constant DENYLIST_MANAGER_ROLE =
        keccak256("DENYLIST_MANAGER_ROLE");

    mapping(address => bool) public denylisted;

    address public minter;

    address public slasher;

    constructor(
        address admin
    ) ERC20("Level USD", "lvUSD") ERC20Permit("lvUSD") {
        if (admin == address(0)) revert ZeroAddressException();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(DENYLIST_MANAGER_ROLE, admin);
    }

    modifier notOwner(address account) {
        if (hasRole(DEFAULT_ADMIN_ROLE, account)) revert IsOwner();
        _;
    }

    function setMinter(
        address newMinter
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit MinterUpdated(newMinter, minter);
        minter = newMinter;
    }

    function setSlasher(
        address newSlasher
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit SlasherUpdated(newSlasher, slasher);
        slasher = newSlasher;
    }

    function mint(address to, uint256 amount) external {
        if (msg.sender != minter) revert OnlyMinter();
        _mint(to, amount);
    }

    /**
     * @dev Remove renounce role access from AccessControl, to prevent users from resigning from roles.
     */
    function renounceRole(bytes32, address) public virtual override {
        revert OperationNotAllowed();
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning. Disables transfers from or to of addresses with the DENYLISTED_ROLE role.
     */

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal virtual override {
        if (denylisted[from] || denylisted[to]) {
            revert Denylisted();
        }
    }

    /**
     * @notice Allows the owner (DEFAULT_ADMIN_ROLE) and denylist managers to denylist addresses.
     * @param target The address to denylist.
     */
    function addToDenylist(
        address target
    ) external onlyRole(DENYLIST_MANAGER_ROLE) notOwner(target) {
        denylisted[target] = true;
    }

    /**
     * @notice Allows denylist managers to remove addresses from the denylist.
     * @param target The address to remove from the denylist.
     */
    function removeFromDenylist(
        address target
    ) external onlyRole(DENYLIST_MANAGER_ROLE) {
        denylisted[target] = false;
    }
}
