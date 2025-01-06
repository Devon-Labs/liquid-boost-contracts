// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {LiquidBoost} from "../src/LiquidBoost.sol";
import {INonfungiblePositionManager} from "lib/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {ISwapRouter} from "lib/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IUniversalRouter} from "../src/interfaces/IUniversalRouter.sol";

contract LiquidBoostScript is Script {
    function setUp() public {}

    function run() public {
        // Replace these addresses with the actual addresses on the forked mainnet
        address nonfungiblePositionManagerAddress = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
        address swapRouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        address universalRouterAddress = 0xEf1c6E67703c7BD7107eed8303Fbe6EC2554BF6B;

        vm.startBroadcast();

        INonfungiblePositionManager nonfungiblePositionManager = INonfungiblePositionManager(nonfungiblePositionManagerAddress);
        ISwapRouter swapRouter = ISwapRouter(swapRouterAddress);
        IUniversalRouter universalRouter = IUniversalRouter(universalRouterAddress);

        LiquidBoost liquidBoost = new LiquidBoost(nonfungiblePositionManager, swapRouter, universalRouter);

        console.log("LiquidBoost deployed at:", address(liquidBoost));

        vm.stopBroadcast();
    }
}