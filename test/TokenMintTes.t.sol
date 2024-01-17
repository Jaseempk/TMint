//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;

import {Test} from ".././lib/forge-std/src/Test.sol";
import {console} from ".././lib/forge-std/src/console.sol";

import {TMint} from "../src/TokenMint.sol";

contract TMintTest is Test{
    TMint public tMint;
    address owner;
    event PresaleContribution(address indexed contributor, uint256 amount,uint256 tokensAllocated);

    function setUp() public{
        owner=address(this); //set the test contract as the owner of the contract

        tMint=new TMint(1000 ether,2000 ether,0.05 ether,1 ether,0.009 ether, 5 ether );

    }

    //Tests whether constrcutor assignments are executed correctly
    function testToCheckConstrcutorInitialisation()public{
        assertEq(tMint.i_presaleCap(),1000 ether);
        assertEq(tMint.publicSaleCap(),2000 ether);
        assertEq(tMint.i_presaleMinPurchase(), 0.05 ether);
        assertEq(tMint.i_presaleMaxPurchase(),1 ether);
        assertEq(tMint.publicSaleMinPurchase(),0.009 ether);
        assertEq(tMint.publicSaleMaxPurchase(),5 ether);
    }

    function testContributePresaleFunc()public{
        vm.deal(address(1),0.5 ether);
        vm.startPrank(address(1));
        tMint.contributeToPresale{value:0.5 ether}();
        assertEq(tMint.etherDepositted(address(1)),0.5 ether); //test to check whether the address of the contributor and corresponding contribution is recorded
        assertEq(tMint.presaleRaisedAmount(),0.5 ether); //Tests whether presaleRaisedAmount is updated after a successful contribution

        vm.stopPrank();

    }

    function testToCheckDeacivatePresaleIsWorking()public{
        tMint.deactivatePresale();
        assertEq(tMint.isPresaleActive(),false); //testing whether isPresaleActive bool can be changed
    }
    
    function testFailIfSaleIsInactive()public{
        tMint.deactivatePresale();
        bytes4 expectedSelectedError=bytes4(keccak256("TMint__PresaleInactive()")); 

        vm.startPrank(address(1));
        vm.deal(address(1),0.5 ether);
        vm.expectRevert(expectedSelectedError); //reverts if isPresaleActive is set to false
        tMint.contributeToPresale{value:0.5 ether}();
        vm.stopPrank();
    }

    function testEventEmittedOnPresaleContribution() public {

        // Set up expectations for the event emission

        uint256 contributionAmount=0.5 ether;
        uint256 expectedTokenAmount=contributionAmount/(0.00000001 ether);
        vm.expectEmit(true, true, true, true);
        emit PresaleContribution(address(1), contributionAmount, expectedTokenAmount);

        // Make a contribution
        vm.startPrank(address(1));
        vm.deal(address(1), contributionAmount);
        tMint.contributeToPresale{value: contributionAmount}();
        vm.stopPrank();
    } 

    function testFailPresaleContributionBelowMinimum() public {
        tMint.contributeToPresale{value: 0.004 ether}(); // This should fail
    }

    function testStartPublicSale() public {
        //test for checking whether startPublicSale function is working
        tMint.deactivatePresale();
        tMint.startPublicSale();
        assertTrue(tMint.isPublicSaleActive());
    }
    function testFailStartPublicSaleByNonOwner() public {
        tMint.deactivatePresale();
        vm.prank(address(1)); // Simulate call from a non-owner
        tMint.startPublicSale(); // This should fail
    }
    function testWithdrawTokens() public {
        address receiver = address(2);
        uint256 amountToWithdraw = 100 ether;
        tMint.withdrawTokens(receiver, amountToWithdraw);
        assertEq(tMint.balanceOf(receiver), amountToWithdraw); //testing whether the withdrawal function is working or not
    }
    function testFailWithdrawTokensByNonOwner() public {
        vm.prank(address(1)); // Non-owner address
        tMint.withdrawTokens(address(2), 100 ether); // This should fail
    }

    function testRefund() public {
        // ... set up contributions
        vm.startPrank(address(1));
        vm.deal(address(1),5 ether);
        tMint.contributeToPresale{value:1 ether}();
        uint256 initialBalance = address(1).balance;

        assertEq(tMint.etherDepositted(address(1)),1 ether); //verifying whether presale contribution is succesful
        vm.stopPrank();

        tMint.deactivatePresale();
        tMint.deactivatePublicsale();

        vm.startPrank(address(1));
        
        tMint.getRefund();
        uint256 finalBalance = address(1).balance;
        assertGt(finalBalance, initialBalance); // Check if the balance increased after the refund
        vm.stopPrank();
    }
    function testFailRefundNoContribution() public {
        vm.startPrank(address(2)); //
        //Simulate call from an address that didn't contribute
        tMint.getRefund(); // This should fail
        vm.stopPrank();
    }
    function testWithdrawETH() public {
        //uint256 contractBalanceBefore = address(tMint).balance;
        vm.startPrank(address(1));
        vm.deal(address(1),5 ether);
        tMint.contributeToPresale{value: 0.8 ether}();
        vm.stopPrank();

        uint256 ownerBalanceBefore = owner.balance;
        tMint.withdrawETH();
        uint256 ownerBalanceAfter = owner.balance;

        assertEq(address(tMint).balance, 0); // Contract balance should be zero after withdrawal
        assertGt(ownerBalanceAfter, ownerBalanceBefore); // Owner's balance should increase
    }
    
    function testFailWithdrawETHByNonOwner() public {
        vm.startPrank(address(1)); // Non-owner address
        tMint.withdrawETH(); // This should fail
        vm.stopPrank();
    }
 receive() external payable{}

}