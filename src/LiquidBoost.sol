// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "./Deposit.sol";
import "./LiquidityProvision.sol";
import "./interfaces/IUniversalRouter.sol";

struct RiskProfile {
        int24 tickLower;
        int24 tickUpper;
    }

contract LiquidBoost is IERC721Receiver, Deposit, LiquidityProvision {

    event PositionOpened(address indexed user, address token0, address token1, uint256 amount, uint24 fee, uint256 tokenId, uint128 liquidity);

    constructor (
        INonfungiblePositionManager _nonfungiblePositionManager,
        ISwapRouter _swapRouter,
        IUniversalRouter _universalRouter
    ) Deposit(_swapRouter, _universalRouter) LiquidityProvision(_nonfungiblePositionManager) {}
    
    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {

        _createPosition(operator, tokenId);
        return this.onERC721Received.selector;
    }

    function openPosition(address pool, uint256 amount, RiskProfile memory risk) external {
        _openPosition(pool, amount, risk);
    }

    function closePosition(uint256 tokenId) external {
        _closePosition(tokenId);
    }

    function calibratePosition(uint256 tokenId, address poolAddress) external {
        // TODO: Here, the liquidity is out of range, so one of the amounts we get it will be 0.
        // I guess we cannot use close position directly since it swaps the tokens to WETH.
        // Maybe a better approach is to find out which token amount is 0 and swap half for the other token.
        // It is still relevand to calculate the amounts based on the ticks (RiskProfile) and information from pool slot0.
        (uint256 deltaAmount) = _closePosition(tokenId);
        _openPosition(poolAddress, deltaAmount, RiskProfile(positions[tokenId].tickLower, positions[tokenId].tickUpper));
    }

    function _openPosition(address pool, uint256 amount, RiskProfile memory risk) internal {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Not enough balance");
        
        IUniswapV3Pool poolContract = IUniswapV3Pool(pool);

        address token0 = poolContract.token0();
        address token1 = poolContract.token1();
        uint24 fee = poolContract.fee();

        uint256 amount0;
        uint256 amount1;
        uint256 swapAmountIn = Math.mulDiv(1, amount, 2);

        if (token0 == Constants.WETH9) {
            amount0 = swapAmountIn;
            amount1 = this.swapExactInputSingle(swapAmountIn, token0, token1, fee);
        } else if (token1 == Constants.WETH9) {
            amount0 = this.swapExactInputSingle(swapAmountIn, token1, token0, fee);
            amount1 = swapAmountIn;
        } else {
            amount0 = this.swapExactInputSingle(swapAmountIn, Constants.WETH9, token0, fee);
            amount1 = this.swapExactInputSingle(swapAmountIn, Constants.WETH9, token1, fee);
        }

        (uint256 tokenId, uint128 liquidity) = this.mintNewPosition(token0, amount0, token1, amount1, fee, risk);
        balances[msg.sender] -= amount;
        emit PositionOpened(msg.sender, token0, token1, amount, fee, tokenId, liquidity);
    }

    function _closePosition(uint256 tokenId) internal returns (uint256 depositDelta) {
        (uint256 amount0, uint256 amount1, address token0, address token1) = this.removeLiquidity(tokenId);
        if (token0 != Constants.WETH9) {
            depositDelta += this.swapExactInputSingle(amount0, token0, Constants.WETH9, 3000);
        } else {
            depositDelta += amount0;
        }
        if (token1 != Constants.WETH9) {
            depositDelta += this.swapExactInputSingle(amount1, token1, Constants.WETH9, 3000);
        } else {
            depositDelta += amount1;
        }

        balances[msg.sender] += depositDelta;
    }
}
