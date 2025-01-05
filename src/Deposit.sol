// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "lib/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "lib/v3-periphery/contracts/libraries/TransferHelper.sol";

contract Deposit {
    mapping(address => uint256) public balances;

    event UserDeposit(address indexed user, uint256 amount);

    ISwapRouter public immutable swapRouter;
    IUniversalRouter public immutable universalRouter;

    constructor(ISwapRouter _swapRouter, IUniversalRouter _universalRouter) {
        swapRouter = _swapRouter;
        universalRouter = _universalRouter;
    }

    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        emit UserDeposit(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
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

    function wrapETH(address owner, uint256 amount) external {
        require(balances[owner] >= amount, "Not enough balance");

        balances[owner] -= amount;

        
    }
}