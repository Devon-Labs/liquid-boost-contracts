// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
pragma abicoder v2;

import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "lib/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "lib/v3-core/contracts/libraries/TickMath.sol";
import "lib/v3-periphery/contracts/libraries/TransferHelper.sol";
import "lib/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract LiquidBoost is IERC721Receiver {
    struct Position {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
    }

    mapping(uint256 => Position) public positions;
    
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);

    INonfungiblePositionManager nonfungiblePositionManager;
    ISwapRouter public immutable swapRouter;
    

    constructor (
        INonfungiblePositionManager _nonfungiblePositionManager,
        ISwapRouter _swapRouter
    ) {
        nonfungiblePositionManager = _nonfungiblePositionManager;
        swapRouter = _swapRouter;
    }

    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {

        _createPosition(operator, tokenId);
        return this.onERC721Received.selector;
    }

    function _createPosition(address owner, uint256 tokenId) internal {
        (, , address token0, address token1, , , , uint128 liquidity, , , , ) = nonfungiblePositionManager.positions(tokenId);

        positions[tokenId] = Position({
            owner: owner, 
            token0: token0,
            token1: token1,
            liquidity: liquidity
        });
    }

    function mintNewPosition(address token0, uint256 amount0, address token1, uint256 amount1, uint24 poolFee) external returns (uint256 tokenId, uint128 liquidity) {

        TransferHelper.safeApprove(token0, address(nonfungiblePositionManager), amount0);
        TransferHelper.safeApprove(token1, address(nonfungiblePositionManager), amount1);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: poolFee,
            tickLower: TickMath.MIN_TICK,
            tickUpper: TickMath.MAX_TICK,
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp
        });

        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(params);

        _createPosition(msg.sender, tokenId);
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

    function swapExactInputSingle(uint256 amountIn, address tokenIn, address tokenOut, uint24 poolFee) external returns (uint256 amountOut) {
        require(amountIn > 0 && balances[msg.sender] >= amountIn, "Not enough balance");

        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = 
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        
        amountOut = swapRouter.exactInputSingle(params);
    }
}
