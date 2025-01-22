// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";

library LiquidityAmounts {
    uint256 constant Q96 = 0x1000000000000000000000000;

    function maxLiquidityForAmount0Imprecise(
        uint256 sqrtRatioAX96,
        uint256 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint256) {
        if (sqrtRatioAX96 > sqrtRatioBX96) {
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        }
        uint256 intermediate = Math.mulDiv(sqrtRatioAX96, sqrtRatioBX96, Q96);
        (bool success, uint256 result) = Math.trySub(sqrtRatioBX96, sqrtRatioAX96);
        require(success,"SUB_FAIL");
        return Math.mulDiv(amount0, intermediate, result);
    }

    function maxLiquidityForAmount0Precise(
        uint256 sqrtRatioAX96,
        uint256 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint256) {
        if (sqrtRatioAX96 > sqrtRatioBX96) {
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        }
        uint256 ratio = Math.mulDiv(sqrtRatioAX96, sqrtRatioBX96, 1);
        uint256 numerator = Math.mulDiv(amount0, ratio, 1);
        (bool success, uint256 diffRatio) = Math.trySub(sqrtRatioBX96, sqrtRatioAX96);
        require(success,"SUB_FAIL");
        uint256 denominator = Math.mulDiv(Q96, diffRatio, 1);

        return Math.mulDiv(1, numerator, denominator);
    }

    function maxLiquidityForAmount1(
        uint256 sqrtRatioAX96,
        uint256 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint256) {
        if (sqrtRatioAX96 > sqrtRatioBX96) {
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        }
        (bool success, uint256 diffRatio) = Math.trySub(sqrtRatioBX96, sqrtRatioAX96);
        require(success,"SUB_FAIL");
        return Math.mulDiv(amount1, Q96, diffRatio);
    }

    function maxLiquidityForAmounts(
        uint256 sqrtRatioCurrentX96,
        uint256 sqrtRatioAX96,
        uint256 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1,
        bool useFullPrecision
    ) internal pure returns (uint256) {
        if (sqrtRatioAX96 > sqrtRatioBX96) {
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        }

        uint256 maxLiquidityForAmount0 = useFullPrecision ? 
            maxLiquidityForAmount0Precise(sqrtRatioAX96, sqrtRatioBX96, amount0) : 
            maxLiquidityForAmount0Imprecise(sqrtRatioAX96, sqrtRatioBX96, amount0);

        if (sqrtRatioCurrentX96 <= sqrtRatioAX96) {
            return maxLiquidityForAmount0;
        } else if (sqrtRatioCurrentX96 < sqrtRatioBX96) {
            uint256 liquidity0 = maxLiquidityForAmount0Precise(sqrtRatioCurrentX96, sqrtRatioBX96, amount0);
            uint256 liquidity1 = maxLiquidityForAmount1(sqrtRatioAX96, sqrtRatioCurrentX96, amount1);
            return liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            return maxLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }
}