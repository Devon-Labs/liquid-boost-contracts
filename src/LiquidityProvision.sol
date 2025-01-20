// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "lib/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "lib/v3-periphery/contracts/libraries/TransferHelper.sol";
import "lib/v3-core/contracts/libraries/TickMath.sol";
import {RiskProfile} from "./LiquidBoost.sol";

contract LiquidityProvision {
    INonfungiblePositionManager public immutable nonfungiblePositionManager;

    struct Position {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
        uint24 poolFee;
        int24 tickLower;
        int24 tickUpper;
    }

    mapping(uint256 => Position) public positions;

    constructor(INonfungiblePositionManager _nonfungiblePositionManager) {
        nonfungiblePositionManager = _nonfungiblePositionManager;
    }

    function _createPosition(address owner, uint256 tokenId) internal {
        (, , address token0, address token1, uint24 fee, int24 tickLower , int24 tickUpper, uint128 liquidity, , , , ) = nonfungiblePositionManager.positions(tokenId);

        positions[tokenId] = Position({
            owner: owner, 
            token0: token0,
            token1: token1,
            liquidity: liquidity,
            poolFee: fee,
            tickLower: tickLower,
            tickUpper: tickUpper
        });
    }

    function getPosition(uint256 tokenId) external view returns (Position memory) {
        return positions[tokenId];
    }

    function mintNewPosition(address token0, uint256 amount0, address token1, uint256 amount1, uint24 poolFee, RiskProfile memory risk) external returns (uint256 tokenId, uint128 liquidity) {

        TransferHelper.safeApprove(token0, address(nonfungiblePositionManager), amount0);
        TransferHelper.safeApprove(token1, address(nonfungiblePositionManager), amount1);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: poolFee,
            tickLower: risk.tickLower,
            tickUpper: risk.tickUpper,
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp
        });

        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(params);
    }

    function collectAllFees(uint256 tokenId) external returns (uint256 amount0, uint256 amount1) {
        INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
            tokenId: tokenId,
            recipient: address(this),
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });

        (amount0, amount1) = nonfungiblePositionManager.collect(params);

        // TODO: Compund
    }

    function removeLiquidity(uint256 tokenId) external returns (uint256 amount0, uint256 amount1) {
        require(msg.sender == positions[tokenId].owner, "Not the owner");

        uint128 liquidity = positions[tokenId].liquidity;

        INonfungiblePositionManager.DecreaseLiquidityParams memory params = 
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId, 
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

            (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(params);  
    }

    function increaseLiquidity(uint256 tokenId, uint256 amount0Add, uint256 amount1Add) external returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
        INonfungiblePositionManager.IncreaseLiquidityParams memory params = 
            INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: tokenId,
                amount0Desired: amount0Add,
                amount1Desired: amount1Add,
                amount0Min: 0,
                amount1Min: 0, 
                deadline: block.timestamp
            });

        (liquidity, amount0, amount1) = nonfungiblePositionManager.increaseLiquidity(params);
    }
}