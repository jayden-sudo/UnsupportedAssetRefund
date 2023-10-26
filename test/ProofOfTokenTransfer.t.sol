// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {ProofOfTokenTransfer} from "../src/ProofOfTokenTransfer.sol";

contract ProofOfTokenTransferTest is Test {
    ProofOfTokenTransfer public _proofOfTokenTransfer;

    address axiomV2QueryAddress = address(0x123);
    bytes32 axiomCallbackQuerySchema = 0xabc0000000000000000000000000000000000000000000000000000000000000;

    function setUp() public {
        // constructor(address _axiomV2QueryAddress, bytes32 _axiomCallbackQuerySchema)
        _proofOfTokenTransfer = new ProofOfTokenTransfer(axiomV2QueryAddress, axiomCallbackQuerySchema);
    }

    function test_axiomCallback() public {
        bytes32[] memory axiomResults = new bytes32[](7);
        axiomResults[0] = 0x00000000000000000000000000000000000000000000000000000000009755bc; // blockNumber
        axiomResults[1] = 0x0000000000000000000000000000000000000000000000000000000000000007; // txIndex
        axiomResults[2] = 0x0000000000000000000000000000000000000000000000000000000000000000; // logIndex
        axiomResults[3] = 0x00000000000000000000000007865c6e87b9f70255377e024ace6630c1eaa37f; // token
        axiomResults[4] = 0x0000000000000000000000008d3e5e1e42383036f7be4049e0dc9d746d3e2c9d; // from
        axiomResults[5] = 0x00000000000000000000000032d123756d32d3ed6580935f8edf416e57b940f4; // to
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
            _proofOfTokenTransfer.axiomV2Callback(
                uint64(block.chainid), address(0xa), axiomCallbackQuerySchema, 0, axiomResults, "0x"
            );
        }
        {
            // from known axiomV2QueryAddress or unknown axiomCallbackQuerySchema
            vm.prank(axiomV2QueryAddress);
            vm.expectRevert("AxiomV2: query schema mismatch");
            _proofOfTokenTransfer.axiomV2Callback(
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
            _proofOfTokenTransfer.axiomV2Callback(
                uint64(block.chainid), address(0xa), axiomCallbackQuerySchema, 0, axiomResults, "0x"
            );

            /*
                function getHashKey(
                        uint256 blockNumber,
                        uint256 txIndex,
                        uint256 logIndex,
                        address token,
                        address from,
                        address to,
                        uint256 value
                )
            */
            bytes32 hashKey = _proofOfTokenTransfer.getHashKey(
                uint256(axiomResults[0]), // blockNumber
                uint256(axiomResults[1]), // txIndex
                uint256(axiomResults[2]), // logIndex
                address(uint160(uint256(axiomResults[3]))), // token
                address(uint160(uint256(axiomResults[4]))), // from
                address(uint160(uint256(axiomResults[5]))), // to
                uint256(axiomResults[6]) // value
            );
            assertEq(_proofOfTokenTransfer.isZkpProvenHash(hashKey), true);
        }
    }
}
