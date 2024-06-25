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

    function testSwapExactOutputWrongMath() public {
        uint inputReserve = 100e18;
        uint outputReserve = 100e18;

        uint amount = 1e18;

        // fix getInputAmountBasedOnOutput to pass this test
        assertEq(pool.getOutputAmountBasedOnInput(
            pool.getInputAmountBasedOnOutput(
                amount,
                inputReserve,
                outputReserve
            ),
            inputReserve,
            outputReserve
        ),
        pool.getInputAmountBasedOnOutput(
            pool.getOutputAmountBasedOnInput(
                amount,
                inputReserve,
                outputReserve
            ),
            inputReserve,
            outputReserve
        ));
    }
}
