// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {UnsupportedAssetRefundProtocol} from "../src/UnsupportedAssetRefundProtocol.sol";
import {devToken} from "../src/devToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UnsupportedAssetRefundProtocolScript is Script {
    uint256 privateKey;

    function setUp() public {
        privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        console2.log("deployer address", vm.addr(privateKey));
    }

    function run() public {
        // querySchema 0x9a7ad4f7837463f317b2be9a2ae17c44ac529839f607f4e6dd870c8c8c19df8f

        address axiomV2QueryAddress = 0x28CeE427fCD58e5EF1cE4C93F877b621E2Db66df;
        bytes32 axiomCallbackQuerySchema = 0x9a7ad4f7837463f317b2be9a2ae17c44ac529839f607f4e6dd870c8c8c19df8f;

        vm.startBroadcast(privateKey);

        // token
        address _devTokenSupported = address(new devToken("_devTokenSupported","_devTokenSupported"));
        console2.log("_devTokenSupported address:", _devTokenSupported);
        address _devTokenNotSupported = address(new devToken("_devTokenNotSupported","_devTokenNotSupported"));
        console2.log("_devTokenNotSupported address:", _devTokenNotSupported);

        address unsupportedAssetRefundProtocol = address(
            new UnsupportedAssetRefundProtocol(IERC20(_devTokenSupported),axiomV2QueryAddress, axiomCallbackQuerySchema)
        );
        console2.log("UnsupportedAssetRefundProtocol address:", unsupportedAssetRefundProtocol);
        vm.stopBroadcast();
    }
}
