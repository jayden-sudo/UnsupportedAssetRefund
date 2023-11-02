// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {UnsupportedAssetRefundProtocol} from "../src/UnsupportedAssetRefundProtocol.sol";
import {devToken} from "../src/devToken.sol";

contract UnsupportedAssetRefundProtocolTest is Test {
    devToken public _devTokenSupported;
    devToken public _devTokenNotSupported;

    UnsupportedAssetRefundProtocol public _unsupportedAssetRefundProtocol;

    address axiomV2QueryAddress = address(0x123);
    bytes32 axiomCallbackQuerySchema = 0xabc0000000000000000000000000000000000000000000000000000000000000;

    function setUp() public {
        _devTokenSupported = new devToken("_devTokenSupported","_devTokenSupported");
        _devTokenNotSupported = new devToken("_devTokenNotSupported","_devTokenNotSupported");

        _unsupportedAssetRefundProtocol = new UnsupportedAssetRefundProtocol(
            _devTokenSupported, axiomV2QueryAddress, axiomCallbackQuerySchema 
        );
    }

    function test_axiomCallback() public {
        bytes32[] memory axiomResults = new bytes32[](7);
        axiomResults[0] = 0x00000000000000000000000000000000000000000000000000000000009755bc; // blockNumber
        axiomResults[1] = 0x0000000000000000000000000000000000000000000000000000000000000007; // txIndex
        axiomResults[2] = 0x0000000000000000000000000000000000000000000000000000000000000000; // logIndex
        axiomResults[3] = 0x00000000000000000000000007865c6e87b9f70255377e024ace6630c1eaa37f; // token
        axiomResults[4] = 0x0000000000000000000000008d3e5e1e42383036f7be4049e0dc9d746d3e2c9d; // from
        // _unsupportedAssetRefundProtocol to bytes32
        bytes32 _unsupportedAssetRefundProtocolBytes32 =
            bytes32(uint256(uint160(address(_unsupportedAssetRefundProtocol))));
        axiomResults[5] = _unsupportedAssetRefundProtocolBytes32; // to
        axiomResults[6] = 0x0000000000000000000000000000000000000000000000000000000000989680; // value
        /*
           function axiomV2Callback(
              uint64 sourceChainId,
              address callerAddr,
              bytes32 querySchema,
              uint256 queryId,
              bytes32[] calldata axiomResults,
              bytes calldata callbackExtraData
           )
        */
        {
            // from unknown axiomV2QueryAddress or known axiomCallbackQuerySchema
            vm.prank(address(1));
            vm.expectRevert("AxiomV2Client: caller must be axiomV2QueryAddress");
            _unsupportedAssetRefundProtocol.axiomV2Callback(
                uint64(block.chainid), address(0xa), axiomCallbackQuerySchema, 0, axiomResults, "0x"
            );
        }
        {
            // from known axiomV2QueryAddress or unknown axiomCallbackQuerySchema
            vm.prank(axiomV2QueryAddress);
            vm.expectRevert("AxiomV2: query schema mismatch");
            _unsupportedAssetRefundProtocol.axiomV2Callback(
                uint64(block.chainid),
                address(0xa),
                0x0100000000000000000000000000000000000000000000000000000000000000,
                0,
                axiomResults,
                "0x"
            );
        }
        {
            // from known axiomV2QueryAddress or known axiomCallbackQuerySchema
            vm.prank(axiomV2QueryAddress);
            _unsupportedAssetRefundProtocol.axiomV2Callback(
                uint64(block.chainid), address(0xa), axiomCallbackQuerySchema, 0, axiomResults, "0x"
            );
        }
    }

    function test_withdrawalSupportedToken() public {
        address user = address(0xa);

        vm.startPrank(user);
        _devTokenSupported.devMint();
        _devTokenSupported.transfer(address(_unsupportedAssetRefundProtocol), 1);
        vm.stopPrank();

        // _unsupportedAssetRefundProtocol to bytes32
        bytes32 _unsupportedAssetRefundProtocolBytes32 =
            bytes32(uint256(uint160(address(_unsupportedAssetRefundProtocol))));

        // _devTokenSupported to bytes32
        bytes32 _devTokenSupportedBytes32 = bytes32(uint256(uint160(address(_devTokenSupported))));

        bytes32[] memory axiomResults = new bytes32[](7);
        axiomResults[0] = 0x00000000000000000000000000000000000000000000000000000000009755bc; // blockNumber
        axiomResults[1] = 0x0000000000000000000000000000000000000000000000000000000000000007; // txIndex
        axiomResults[2] = 0x0000000000000000000000000000000000000000000000000000000000000000; // logIndex
        axiomResults[3] = _devTokenSupportedBytes32; // token
        axiomResults[4] = 0x000000000000000000000000000000000000000000000000000000000000000a; // from
        axiomResults[5] = _unsupportedAssetRefundProtocolBytes32; // to
        axiomResults[6] = 0x0000000000000000000000000000000000000000000000000000000000000001; // value
        {}

        vm.prank(axiomV2QueryAddress);
        vm.expectRevert("can not be allowed token");
        _unsupportedAssetRefundProtocol.axiomV2Callback(
            uint64(block.chainid), address(0xa), axiomCallbackQuerySchema, 0, axiomResults, "0x"
        );
    }

    event ReadyToWithdraw(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 value,
        uint256 blockNumber,
        uint256 txIndex,
        uint256 logIndex,
        bytes32 hashKey
    );
    event WithdrawnComplete(
        address indexed token, address indexed from, address indexed to, uint256 value, bytes32 hashKey
    );

    function test_withdrawalUnsupportedToken() public {
        address user = address(0xa);

        vm.startPrank(user);
        _devTokenNotSupported.devMint();
        _devTokenNotSupported.transfer(address(_unsupportedAssetRefundProtocol), 1);
        vm.stopPrank();

        // _unsupportedAssetRefundProtocol to bytes32
        bytes32 _unsupportedAssetRefundProtocolBytes32 =
            bytes32(uint256(uint160(address(_unsupportedAssetRefundProtocol))));

        // _devTokenNotSupported to bytes32
        bytes32 _devTokenNotSupportedBytes32 = bytes32(uint256(uint160(address(_devTokenNotSupported))));

        bytes32[] memory axiomResults = new bytes32[](7);
        axiomResults[0] = 0x00000000000000000000000000000000000000000000000000000000009755bc; // blockNumber
        axiomResults[1] = 0x0000000000000000000000000000000000000000000000000000000000000007; // txIndex
        axiomResults[2] = 0x0000000000000000000000000000000000000000000000000000000000000000; // logIndex
        axiomResults[3] = _devTokenNotSupportedBytes32; // token
        axiomResults[4] = 0x000000000000000000000000000000000000000000000000000000000000000a; // from
        axiomResults[5] = _unsupportedAssetRefundProtocolBytes32; // to
        axiomResults[6] = 0x0000000000000000000000000000000000000000000000000000000000000001; // value

        bytes32 hashKey = _unsupportedAssetRefundProtocol._hashKey(
            0x9755bc, 7, 0, address(_devTokenNotSupported), address(0xa), address(_unsupportedAssetRefundProtocol), 1
        );

        vm.startPrank(axiomV2QueryAddress);
        vm.expectEmit(true, true, true, true);
        emit ReadyToWithdraw(
            address(_devTokenNotSupported),
            address(0xa),
            address(_unsupportedAssetRefundProtocol),
            1,
            0x9755bc,
            7,
            0,
            hashKey
        );

        _unsupportedAssetRefundProtocol.axiomV2Callback(
            uint64(block.chainid), address(0xa), axiomCallbackQuerySchema, 0, axiomResults, "0x"
        );
        vm.stopPrank();

        // withdraw
        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit WithdrawnComplete(
            address(_devTokenNotSupported), address(_unsupportedAssetRefundProtocol), address(0xa), 1, hashKey
        );
        _unsupportedAssetRefundProtocol.UnsupportedTokenWithdrawal(
            0x9755bc, 7, 0, address(_devTokenNotSupported), address(0xa), address(_unsupportedAssetRefundProtocol), 1
        );
    }
}
