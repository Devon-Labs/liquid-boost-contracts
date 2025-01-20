// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {LiquidBoost} from "../src/LiquidBoost.sol";
import {INonfungiblePositionManager} from "lib/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {ISwapRouter} from "lib/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IUniversalRouter} from "../src/interfaces/IUniversalRouter.sol";
import {Constants} from "../src/libraries/Constants.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract DepositTest is Test {
    LiquidBoost public liquidBoost;
    address public alice;

    function setUp() public {
        (alice, ) = makeAddrAndKey("alice");
        hoax(alice, 100 ether);

        address nonfungiblePositionManagerAddress = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
        address swapRouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        address universalRouterAddress = 0xEf1c6E67703c7BD7107eed8303Fbe6EC2554BF6B;

        INonfungiblePositionManager nonfungiblePositionManager = INonfungiblePositionManager(nonfungiblePositionManagerAddress);
        ISwapRouter swapRouter = ISwapRouter(swapRouterAddress);
        IUniversalRouter universalRouter = IUniversalRouter(universalRouterAddress);

        liquidBoost = new LiquidBoost(nonfungiblePositionManager, swapRouter, universalRouter);
    }

    function testDepositETHWithdrawWETH() public {
        vm.prank(alice);
        liquidBoost.depositETH{value: 1 ether}();
        uint256 contractBalance = IERC20(Constants.WETH9).balanceOf(address(liquidBoost));
        assertEq(contractBalance, 1 ether, "Contract balance should be 1 WETH");

        uint256 balance = liquidBoost.getBalance(alice);
        assertEq(balance, 1 ether, "Balance should be 1 ether");
        vm.prank(alice);
        liquidBoost.withdrawWETH(1 ether);
        uint256 wethBalance = IERC20(Constants.WETH9).balanceOf(address(liquidBoost));
        assertEq(wethBalance, 0 ether, "WETH balance should be 0");
        uint256 balanceDeposit = liquidBoost.getBalance(alice);
        assertEq(balanceDeposit, 0, "Balance should be 0");
    }

    function testWrapETH() public {
        vm.prank(alice);
        liquidBoost.wrapETH{value: 1 ether}(alice);
        uint256 aliceBalance = IERC20(Constants.WETH9).balanceOf(alice);
        assertEq(aliceBalance, 1 ether, "Contract balance should be 1 WETH");
    }

    function testSwapExactiInputSingle() public {
        vm.prank(alice);
        liquidBoost.depositETH{value: 1 ether}();

        vm.prank(alice);
        uint256 amountOut = liquidBoost.swapExactInputSingle(0.5 ether, Constants.WETH9, Constants.WBTC, 3000);
        uint256 contractBalance = IERC20(Constants.WBTC).balanceOf(address(liquidBoost));
        assertEq(contractBalance, amountOut, "Alice balance shoulb be equal to swap output");
    }
}
