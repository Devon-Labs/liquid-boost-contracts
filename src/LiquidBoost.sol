// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./Deposit.sol";
import "./LiquidityProvision.sol";

contract LiquidBoost is IERC721Receiver, Deposit, LiquidityProvision {

    constructor (
        INonfungiblePositionManager _nonfungiblePositionManager,
        ISwapRouter _swapRouter
    ) Deposit(_swapRouter) LiquidityProvision(_nonfungiblePositionManager) {}
    
    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {

        _createPosition(operator, tokenId);
        return this.onERC721Received.selector;
    }
}
