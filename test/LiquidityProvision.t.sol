// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {LiquidBoost, RiskProfile} from "../src/LiquidBoost.sol";
import {INonfungiblePositionManager} from "lib/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {ISwapRouter} from "lib/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IUniversalRouter} from "../src/interfaces/IUniversalRouter.sol";
import {Constants} from "../src/libraries/Constants.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract LiquidityProvision is Test {
    LiquidBoost public liquidBoost;
    address public alice;
    INonfungiblePositionManager public nonfungiblePositionManager;

    function setUp() public {
        (alice, ) = makeAddrAndKey("alice");
        hoax(alice, 100 ether);

        address nonfungiblePositionManagerAddress = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
        address swapRouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        address universalRouterAddress = 0xEf1c6E67703c7BD7107eed8303Fbe6EC2554BF6B;

        nonfungiblePositionManager = INonfungiblePositionManager(nonfungiblePositionManagerAddress);
        ISwapRouter swapRouter = ISwapRouter(swapRouterAddress);
        IUniversalRouter universalRouter = IUniversalRouter(universalRouterAddress);

        liquidBoost = new LiquidBoost(nonfungiblePositionManager, swapRouter, universalRouter);
    }

    function testMintNewPosition() public {
        vm.prank(alice);
        liquidBoost.depositETH{value: 1 ether}();

        vm.prank(alice);
        uint256 amountOut = liquidBoost.swapExactInputSingle(0.5 ether, Constants.WETH9, Constants.WBTC, 3000);
        RiskProfile memory risk = RiskProfile(
            -887220,
            887220
        );
        (uint256 tokenId, uint128 liquidity) = liquidBoost.mintNewPosition(Constants.WBTC, amountOut, Constants.WETH9, 0.5 ether, 3000, risk);

        console.log("Token ID: ", tokenId);
        console.log("Liquidity: ", liquidity);

        (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            ,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = nonfungiblePositionManager.positions(tokenId);

        console.log("Nonce: ", nonce);
        console.log("Operator: ", operator);
        console.log("Token0: ", token0);
        console.log("Token1: ", token1);
        console.log("Fee: ", fee);
        console.log("Tick Lower: ", tickLower);
        console.log("Tick Upper: ", tickUpper);
        console.log("Fee Growth Inside 0 Last X128: ", feeGrowthInside0LastX128);
        console.log("Fee Growth Inside 1 Last X128: ", feeGrowthInside1LastX128);
        console.log("Tokens Owed 0: ", tokensOwed0);
        console.log("Tokens Owed 1: ", tokensOwed1);
        
    }
}