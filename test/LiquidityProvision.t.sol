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

        vm.prank(alice);
        (uint256 tokenId, uint128 liquidity) = liquidBoost.mintNewPosition(Constants.WBTC, amountOut, Constants.WETH9, 0.5 ether, 3000, risk);

        (
            uint96 nonce,
            ,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            ,
            ,
            ,
            ,
        ) = nonfungiblePositionManager.positions(tokenId);

        address positionOwner = nonfungiblePositionManager.ownerOf(tokenId);

        assertEq(positionOwner, address(liquidBoost), "Position owner should be the contract address");
        assertGt(liquidity, 0, "Liquidity should be greater than 0");
        assertEq(nonce, 0, "Nonce should be 0");
        assertEq(token0, Constants.WBTC, "Token0 should be WBTC");
        assertEq(token1, Constants.WETH9, "Token1 should be WETH");
        assertEq(fee, 3000, "Fee should be 3000");
        assertEq(tickLower, -887220, "Tick Lower should be -887220");
        assertEq(tickUpper, 887220, "Tick Upper should be 887220");        
    }

    function testRemoveLiquidity() public {
        vm.prank(alice);
        liquidBoost.depositETH{value: 1 ether}();

        vm.prank(alice);
        uint256 amountOut = liquidBoost.swapExactInputSingle(0.5 ether, Constants.WETH9, Constants.WBTC, 3000);
        RiskProfile memory risk = RiskProfile(
            -887220,
            887220
        );

        vm.prank(alice);
        (uint256 tokenId, uint128 liquidity) = liquidBoost.mintNewPosition(Constants.WBTC, amountOut, Constants.WETH9, 0.5 ether, 3000, risk);

        LiquidBoost.Position memory position = liquidBoost.getPosition(tokenId);

        assertGt(position.liquidity, 0, "Liquidity should be greater than 0");
        assertEq(position.liquidity, liquidity, "Liquidity should be equal to the minted liquidity");
        assertEq(alice, position.owner, "Alice should be the owner of the position");

        vm.prank(alice);
        (uint256 amount0, uint256 amount1, , ) = liquidBoost.removeLiquidity(tokenId);

        assertGt(amount0, 0, "Amount0 should be greater than 0");
        assertGt(amount1, 0, "Amount1 should be greater than 0");

    }
}