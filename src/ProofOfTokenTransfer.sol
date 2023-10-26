// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IProofOfTokenTransfer.sol";
import "./AxiomV2Client.sol";

/*
    Proof of token transfer Protocol:
        Can prove that the user has a specific transfer record in history (currently only supports ERC20)
 */

contract ProofOfTokenTransfer is IProofOfTokenTransfer, AxiomV2Client {
    uint256 public immutable callbackSourceChainId;
    bytes32 public immutable axiomCallbackQuerySchema;

    /**
     * @dev proof log
     * key => the hash key of record: keccak256(abi.encode(txHash, logIndex, token, from, to, value))
     * value => status: BLANK: 0, PROVEN: 1
     */
    mapping(bytes32 => uint256) private zkpProvenLog;

    constructor(address _axiomV2QueryAddress, bytes32 _axiomCallbackQuerySchema) AxiomV2Client(_axiomV2QueryAddress) {
        callbackSourceChainId = block.chainid;
        axiomCallbackQuerySchema = _axiomCallbackQuerySchema;
    }

    function _hashKey(
        uint256 blockNumber,
        uint256 txIndex,
        uint256 logIndex,
        address token,
        address from,
        address to,
        uint256 value
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(blockNumber, txIndex, logIndex, token, from, to, value));
    }

    /**
     * @dev cauclate the hash of the retrieved log Key
     * @param blockNumber the block number of the transfer event
     * @param txIndex the transaction index of the block
     * @param logIndex any log index included ERC20 Transfer event
     * @param token the address of the ERC20 token
     * @param from  from address of the Transfer event
     * @param to  to address of the Transfer event
     * @param value the amount of the token
     */
    function getHashKey(
        uint256 blockNumber,
        uint256 txIndex,
        uint256 logIndex,
        address token,
        address from,
        address to,
        uint256 value
    ) external pure returns (bytes32) {
        return _hashKey(blockNumber, txIndex, logIndex, token, from, to, value);
    }

    /**
     * @dev check if the transfer is proven
     * hashKey = keccak256(abi.encode(blockNumber, txIndex, logIndex, token, from, to, value))
     */
    function isZkpProvenHash(bytes32 hashKey) external view returns (bool) {
        return zkpProvenLog[hashKey] == 1;
    }

    /**
     * @dev check if the transfer is proven
     */
    function isZkpProvenHash(
        uint256 blockNumber,
        uint256 txIndex,
        uint256 logIndex,
        address token,
        address from,
        address to,
        uint256 value
    ) external view returns (bool) {
        bytes32 hashKey = _hashKey(blockNumber, txIndex, logIndex, token, from, to, value);
        return zkpProvenLog[hashKey] == 1;
    }

    function _validateAxiomV2Call(uint64 sourceChainId, address callerAddr, bytes32 querySchema)
        internal
        virtual
        override
    {
        (callerAddr);
        require(sourceChainId == callbackSourceChainId, "AxiomV2: caller sourceChainId mismatch");
        require(querySchema == axiomCallbackQuerySchema, "AxiomV2: query schema mismatch");
    }

    function _axiomV2Callback(
        uint64 sourceChainId,
        address callerAddr,
        bytes32 querySchema,
        uint256 queryId,
        bytes32[] calldata axiomResults,
        bytes calldata callbackExtraData
    ) internal virtual override {
        // unused variables
        (sourceChainId);
        (queryId);
        (callerAddr);
        (callbackExtraData);
        (querySchema);

        /*
            // blockNumber
            addToCallback(blockNumber);
            // txIndex
            addToCallback(txIdx);
            // logIndex
            addToCallback(logIdx);
            // token
            addToCallback(receiptLog.address());
            // from
            addToCallback(transfer_from);
            // to
            addToCallback(transfer_to);
            // value
            addToCallback(transfer_value);
         */

        uint256 blockNumber;
        uint256 txIndex;
        uint256 logIndex;
        address token;
        address from;
        address to;
        uint256 value;

        // Parse results
        blockNumber = uint256(axiomResults[0]);
        txIndex = uint256(axiomResults[1]);
        logIndex = uint256(axiomResults[2]);
        token = address(uint160(uint256(axiomResults[3])));
        from = address(uint160(uint256(axiomResults[4])));
        to = address(uint160(uint256(axiomResults[5])));
        value = uint256(axiomResults[6]);

        /*
            no need to check the eventSchema, because it is already checked in the circuit:
                
                // Transfer (index_topic_1 address from, index_topic_2 address to, uint256 value)
                const transferEventSchema = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef";
                const transferEventSchema_hi = constant(BigInt("0xddf252ad1be2c89b69c2b068fc378daa"));
                const transferEventSchema_lo = constant(BigInt("0x952ba7f163c4a11628f55a4df523b3ef"));

                const receipt = getReceipt(blockNumber, txIdx);
                const receiptLog = receipt.log(logIdx);
                const eventSchema = receiptLog.topic(0);

                checkEqual(eventSchema.hi(), transferEventSchema_hi);
                checkEqual(eventSchema.lo(), transferEventSchema_lo);
        */

        bytes32 hashKey = _hashKey(blockNumber, txIndex, logIndex, token, from, to, value);
        /*
            No need to check for duplicate submissions because the mapping will only record it once.
            Having duplicate records in the logs doesn't have any adverse effects.
        */
        zkpProvenLog[hashKey] = 1;
        emit ProvenTransfer(token, from, to, value, blockNumber, txIndex, logIndex, hashKey);
    }
}
