// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/StakingPool.sol";

contract StakingPoolTest is Test {
    StakingPool public pool;
    address wethStub = address(0x1);
    address veOcto = address(0x2);
    address treasury = address(0x3);

    function setUp() public {
        pool = new StakingPool(wethStub, veOcto, treasury);


    }
    
    function testRug() public {
    }
}
