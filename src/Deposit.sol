// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "lib/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "lib/v3-periphery/contracts/libraries/TransferHelper.sol";
import "./interfaces/IUniversalRouter.sol";
import {Commands} from "./libraries/Commands.sol";
import {Constants} from "./libraries/Constants.sol";

contract Deposit {
    mapping(address => uint256) public balances;

    event UserDeposit(address indexed user, uint256 amount);
    event UserWithdraw(address indexed user, uint256 amount);

    ISwapRouter public immutable swapRouter;
    IUniversalRouter public immutable universalRouter;

    constructor(ISwapRouter _swapRouter, IUniversalRouter _universalRouter) {
        swapRouter = _swapRouter;
        universalRouter = _universalRouter;
    }

    function depositETH() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        _wrapETH(address(this), msg.value);

        emit UserDeposit(msg.sender, msg.value);
    }

    function wrapETH(address to) external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        _wrapETH(to, msg.value);
    }

    function depositWETH(uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than 0");
        TransferHelper.safeTransferFrom(Constants.WETH9, msg.sender, address(this), amount);
        balances[msg.sender] += amount;

        emit UserDeposit(msg.sender, amount);
    }

    function withdrawWETH(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough balance");
        balances[msg.sender] -= amount;
        TransferHelper.safeTransferFrom(Constants.WETH9, address(this), msg.sender, amount);

        emit UserWithdraw(msg.sender, amount);
    }

    function getBalance(address owner) public view returns (uint256) {
        return balances[owner];
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

    function _wrapETH(address to, uint256 amount) internal {
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = abi.encode(to, amount);
        uint256 deadline = block.timestamp + 60;
        bytes memory commands = abi.encodePacked(bytes1(uint8(Commands.WRAP_ETH)));
        universalRouter.execute{value: amount}(commands, inputs, deadline);
    }
}