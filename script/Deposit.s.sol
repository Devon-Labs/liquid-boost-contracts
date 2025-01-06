// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {LiquidBoost} from "../src/LiquidBoost.sol";
import {Constants} from "../src/libraries/Constants.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract DepositScript is Script {
    function setUp() public {}

    function run() public {
        // Replace this address with the actual address of the deployed LiquidBoost contract
        address liquidBoostAddress = 0xcf23CE2ffa1DDd9Cc2b445aE6778c4DBD605a1A0;
        address messageSender = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        vm.startBroadcast();

        LiquidBoost liquidBoost = LiquidBoost(payable(liquidBoostAddress));
        IERC20 weth = IERC20(Constants.WETH9);

        // Deposit some ETH
        liquidBoost.depositETH{value: 1 ether}();
        console.log("Deposited 1 ETH");

        // Check balance
        uint256 balance = liquidBoost.getBalance(messageSender);
        console.log("Balance after deposit:", balance);
    
        // Balance after wrapping ETH
        uint256 wethBalance = weth.balanceOf(liquidBoostAddress);
        console.log("WETH balance after wrapping ETH:", wethBalance);

        liquidBoost.withdrawWETH(balance);
        console.log("Withdrew WETH");

        // Check balance
        balance = liquidBoost.getBalance(messageSender);
        console.log("Balance after withdrawal:", balance);

        // Balance after withdrawing WETH
        wethBalance = weth.balanceOf(liquidBoostAddress);
        console.log("WETH balance after withdrawal:", wethBalance);

        vm.stopBroadcast();
    }
}