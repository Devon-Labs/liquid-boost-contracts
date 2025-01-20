// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
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

    function openPosition(address token0, address token1, uint256 amount, uint24 fee, RiskProfile memory risk) external {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Not enough balance");

        uint256 swapAmountIn = amount / 2;

        uint256 swapAmountOut = this.swapExactInputSingle(swapAmountIn, token0, token1, fee);

        (uint256 tokenId, uint128 liquidity) = this.mintNewPosition(token0, amount-swapAmountIn, token1, swapAmountOut, fee, risk);
        balances[msg.sender] -= amount;
        emit PositionOpened(msg.sender, token0, token1, amount, fee, tokenId, liquidity);
    }
}
