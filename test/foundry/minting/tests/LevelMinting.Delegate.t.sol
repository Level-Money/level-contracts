// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "../LevelMinting.utils.sol";

contract LevelMintingDelegateTest is LevelMintingUtils {
    function setUp() public override {
        super.setUp();
    }

    function testDelegateSuccessfulMint() public {
        (
            ILevelMinting.Order memory order,
            ,
            ILevelMinting.Route memory route
        ) = mint_setup(_lvlusdToMint, _stETHToDeposit, 1, false);

        vm.prank(benefactor);
        LevelMintingContract.setDelegatedSigner(trader2);

        bytes32 digest1 = LevelMintingContract.hashOrder(order);
        vm.prank(trader2);
        ILevelMinting.Signature memory trader2Sig = signOrder(
            trader2PrivateKey,
            digest1,
            ILevelMinting.SignatureType.EIP712
        );

        assertEq(
            stETHToken.balanceOf(address(LevelMintingContract)),
            0,
            "Mismatch in Minting contract stETH balance before mint"
        );
        assertEq(
            stETHToken.balanceOf(benefactor),
            _stETHToDeposit,
            "Mismatch in benefactor stETH balance before mint"
        );
        assertEq(
            lvlusdToken.balanceOf(beneficiary),
            0,
            "Mismatch in beneficiary lvlUSD balance before mint"
        );

        vm.prank(minter);
        LevelMintingContract.mint(order, route, trader2Sig);

        assertEq(
            stETHToken.balanceOf(address(LevelMintingContract)),
            _stETHToDeposit,
            "Mismatch in Minting contract stETH balance after mint"
        );
        assertEq(
            stETHToken.balanceOf(beneficiary),
            0,
            "Mismatch in beneficiary stETH balance after mint"
        );
        assertEq(
            lvlusdToken.balanceOf(beneficiary),
            _lvlusdToMint,
            "Mismatch in beneficiary lvlUSD balance after mint"
        );
    }

    function testDelegateFailureMint() public {
        (
            ILevelMinting.Order memory order,
            ,
            ILevelMinting.Route memory route
        ) = mint_setup(_lvlusdToMint, _stETHToDeposit, 1, false);

        // omit delegation by benefactor

        bytes32 digest1 = LevelMintingContract.hashOrder(order);
        vm.prank(trader2);
        ILevelMinting.Signature memory trader2Sig = signOrder(
            trader2PrivateKey,
            digest1,
            ILevelMinting.SignatureType.EIP712
        );

        assertEq(
            stETHToken.balanceOf(address(LevelMintingContract)),
            0,
            "Mismatch in Minting contract stETH balance before mint"
        );
        assertEq(
            stETHToken.balanceOf(benefactor),
            _stETHToDeposit,
            "Mismatch in benefactor stETH balance before mint"
        );
        assertEq(
            lvlusdToken.balanceOf(beneficiary),
            0,
            "Mismatch in beneficiary lvlUSD balance before mint"
        );

        vm.prank(minter);
        vm.expectRevert(InvalidSignature);
        LevelMintingContract.mint(order, route, trader2Sig);

        assertEq(
            stETHToken.balanceOf(address(LevelMintingContract)),
            0,
            "Mismatch in Minting contract stETH balance after mint"
        );
        assertEq(
            stETHToken.balanceOf(benefactor),
            _stETHToDeposit,
            "Mismatch in beneficiary stETH balance after mint"
        );
        assertEq(
            lvlusdToken.balanceOf(beneficiary),
            0,
            "Mismatch in beneficiary lvlUSD balance after mint"
        );
    }

    function testDelegateSuccessfulRedeem() public {
        (ILevelMinting.Order memory order, ) = redeem_setup(
            _lvlusdToMint,
            _stETHToDeposit,
            1,
            false
        );

        vm.prank(beneficiary);
        LevelMintingContract.setDelegatedSigner(trader2);

        bytes32 digest1 = LevelMintingContract.hashOrder(order);
        vm.prank(trader2);
        ILevelMinting.Signature memory trader2Sig = signOrder(
            trader2PrivateKey,
            digest1,
            ILevelMinting.SignatureType.EIP712
        );

        assertEq(
            stETHToken.balanceOf(address(LevelMintingContract)),
            _stETHToDeposit,
            "Mismatch in Minting contract stETH balance before mint"
        );
        assertEq(
            stETHToken.balanceOf(beneficiary),
            0,
            "Mismatch in beneficiary stETH balance before mint"
        );
        assertEq(
            lvlusdToken.balanceOf(beneficiary),
            _lvlusdToMint,
            "Mismatch in beneficiary lvlUSD balance before mint"
        );

        vm.prank(redeemer);
        LevelMintingContract.redeem(order, trader2Sig);

        assertEq(
            stETHToken.balanceOf(address(LevelMintingContract)),
            0,
            "Mismatch in Minting contract stETH balance after mint"
        );
        assertEq(
            stETHToken.balanceOf(beneficiary),
            _stETHToDeposit,
            "Mismatch in beneficiary stETH balance after mint"
        );
        assertEq(
            lvlusdToken.balanceOf(beneficiary),
            0,
            "Mismatch in beneficiary lvlUSD balance after mint"
        );
    }

    function testDelegateFailureRedeem() public {
        (ILevelMinting.Order memory order, ) = redeem_setup(
            _lvlusdToMint,
            _stETHToDeposit,
            1,
            false
        );

        // omit delegation by beneficiary

        bytes32 digest1 = LevelMintingContract.hashOrder(order);
        vm.prank(trader2);
        ILevelMinting.Signature memory trader2Sig = signOrder(
            trader2PrivateKey,
            digest1,
            ILevelMinting.SignatureType.EIP712
        );

        assertEq(
            stETHToken.balanceOf(address(LevelMintingContract)),
            _stETHToDeposit,
            "Mismatch in Minting contract stETH balance before mint"
        );
        assertEq(
            stETHToken.balanceOf(beneficiary),
            0,
            "Mismatch in beneficiary stETH balance before mint"
        );
        assertEq(
            lvlusdToken.balanceOf(beneficiary),
            _lvlusdToMint,
            "Mismatch in beneficiary lvlUSD balance before mint"
        );

        vm.prank(redeemer);
        vm.expectRevert(InvalidSignature);
        LevelMintingContract.redeem(order, trader2Sig);

        assertEq(
            stETHToken.balanceOf(address(LevelMintingContract)),
            _stETHToDeposit,
            "Mismatch in Minting contract stETH balance after mint"
        );
        assertEq(
            stETHToken.balanceOf(beneficiary),
            0,
            "Mismatch in beneficiary stETH balance after mint"
        );
        assertEq(
            lvlusdToken.balanceOf(beneficiary),
            _lvlusdToMint,
            "Mismatch in beneficiary lvlUSD balance after mint"
        );
    }

    function testCanUndelegate() public {
        (
            ILevelMinting.Order memory order,
            ,
            ILevelMinting.Route memory route
        ) = mint_setup(_lvlusdToMint, _stETHToDeposit, 1, false);

        // delegate and then undelegate
        vm.startPrank(benefactor);
        LevelMintingContract.setDelegatedSigner(trader2);
        LevelMintingContract.removeDelegatedSigner(trader2);
        vm.stopPrank();

        bytes32 digest1 = LevelMintingContract.hashOrder(order);
        vm.prank(trader2);
        ILevelMinting.Signature memory trader2Sig = signOrder(
            trader2PrivateKey,
            digest1,
            ILevelMinting.SignatureType.EIP712
        );

        assertEq(
            stETHToken.balanceOf(address(LevelMintingContract)),
            0,
            "Mismatch in Minting contract stETH balance before mint"
        );
        assertEq(
            stETHToken.balanceOf(benefactor),
            _stETHToDeposit,
            "Mismatch in benefactor stETH balance before mint"
        );
        assertEq(
            lvlusdToken.balanceOf(beneficiary),
            0,
            "Mismatch in beneficiary lvlUSD balance before mint"
        );

        vm.prank(minter);
        vm.expectRevert(InvalidSignature);
        LevelMintingContract.mint(order, route, trader2Sig);

        assertEq(
            stETHToken.balanceOf(address(LevelMintingContract)),
            0,
            "Mismatch in Minting contract stETH balance after mint"
        );
        assertEq(
            stETHToken.balanceOf(benefactor),
            _stETHToDeposit,
            "Mismatch in beneficiary stETH balance after mint"
        );
        assertEq(
            lvlusdToken.balanceOf(beneficiary),
            0,
            "Mismatch in beneficiary lvlUSD balance after mint"
        );
    }
}
