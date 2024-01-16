//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;

import {Test} from ".././lib/forge-std/src/Test.sol";
import {TMint} from "../src/TokenMint.sol";

contract TMintTest is Test{
    TMint public tMint;
    address owner;
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
    function testFailIfSaleIsInactive()public{
        tMint.deactivatePresale();
        bytes4 expectedSelectedError=bytes4(keccak256("TMint__PresaleInactive()")); 

        vm.startPrank(address(1));
        vm.deal(address(1),0.5 ether);
        vm.expectRevert(expectedSelectedError);
        tMint.contributeToPresale{value:0.5 ether}();
        vm.stopPrank();
    }

}