// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19;

/// @dev Changelog: changed solidity version and name
interface IlvUSDDefinitions {
    /// @notice This event is fired when the minter changes
    event MinterUpdated(address indexed newMinter, address indexed oldMinter);

    /// @notice Zero address not allowed
    error ZeroAddressException();
    /// @notice It's not possible to renounce the ownership
    error OperationNotAllowed();
    /// @notice Only the minter role can perform an action
    error OnlyMinter();
    /// @notice Address is denylisted
    error Denylisted();
    /// @notice Address is owner
    error IsOwner();
}
