//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");

    uint256 constant SEND_VALUE = 0.1 ether; //100000000000000000
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;
    modifier funded() {
        vm.prank(USER); // The next transaction will be from USER.
        fundMe.fund{value: SEND_VALUE}(); //Funds from the USER with SEND_VALUE
        _;
    }

    function setUp() external {
        // setup
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        // test that uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
        console.log("fundMe.MINIMUM_USD(): %s", fundMe.MINIMUM_USD());
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMessageSender() public {
        // test that address public /* immutable */ i_owner;
        console.log("fundMe.i_owner(): %s", fundMe.getOwner());
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        // test that function getVersion() public view returns 4
        console.log("fundMe.getVersion(): %s", fundMe.getVersion());
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataSTrucuture() public {
        vm.prank(USER); // The next transaction will be from USER.
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        vm.prank(USER); // The next transaction will be from USER.
        fundMe.fund{value: SEND_VALUE}(); //Funds from the USER with SEND_VALUE

        address funder = fundMe.getFunders(0);

        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert(); // We expect that USER is not OWNER and cannot withdraw.
        vm.prank(USER); // The next transaction will be from USER.
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner()); // The next transaction will be from OWNER.
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * GAS_PRICE;
        console.log("gasUsed: %s", gasUsed);
        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
    }

    function testWithdrawWithMultipleFunders() public funded {
        //Arrange-----------------------------
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal new address
            //address()
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act--------------------------------
        vm.startPrank(fundMe.getOwner()); // The next transaction will be from OWNER.
        fundMe.withdraw();
        vm.stopPrank();

        //Assert-----------------------------

        assertEq(address(fundMe).balance, 0);
        assertEq(
            fundMe.getOwner().balance,
            startingOwnerBalance + startingFundMeBalance
        );
    }

    function testCheaperWithdrawWithMultipleFunders() public funded {
        //Arrange-----------------------------
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal new address
            //address()
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act--------------------------------
        vm.startPrank(fundMe.getOwner()); // The next transaction will be from OWNER.
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //Assert-----------------------------

        assertEq(address(fundMe).balance, 0);
        assertEq(
            fundMe.getOwner().balance,
            startingOwnerBalance + startingFundMeBalance
        );
    }
}
