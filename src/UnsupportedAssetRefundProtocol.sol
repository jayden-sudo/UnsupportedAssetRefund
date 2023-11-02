// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./SomeProtocol.sol";
import "./AxiomV2Client.sol";

contract UnsupportedAssetRefundProtocol is SomeProtocol, AxiomV2Client {
    using SafeERC20 for IERC20;

    uint256 public immutable callbackSourceChainId;
    bytes32 public immutable axiomCallbackQuerySchema;

    /**
     * @dev Emiited when a proof is submitted
     * @param token the address of the unsupported token
     * @param from the address of the token sender
     * @param to the address of the token receiver
     * @param value the amount of the token
     * @param blockNumber the block number of the transfer event
     * @param txIndex the transaction index of the block
     * @param logIndex the log index of the transfer event
     * @param hashKey the hash key of record
     */
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

    /**
     * @dev Emiited after the user withdraw complete
     * @param token the address of the token
     * @param from the address of the token sender(this contract)
     * @param to the address of the token receiver
     * @param value the amount of the token
     * @param hashKey the hash key of record
     */
    event WithdrawnComplete(
        address indexed token, address indexed from, address indexed to, uint256 value, bytes32 hashKey
    );

    enum RetrieveStatusEnum {
        Default, // 0
        VerifiedNotClaimed, // 1: verified but user not claimed
        ClaimedComplete // 2: user claimed and complete
    }

    /**
     * @dev retrieve log
     * key => the hash key of record: keccak256(abi.encode(blockNumber, txIndex, logIndex, token, from, to, value))
     * value => RetrieveStatusEnum
     */
    mapping(bytes32 => RetrieveStatusEnum) public RetrieveStatusMapping;

    constructor(IERC20 _allowedToken, address _axiomV2QueryAddress, bytes32 _axiomCallbackQuerySchema)
        SomeProtocol(_allowedToken)
        AxiomV2Client(_axiomV2QueryAddress)
    {
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
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(blockNumber, txIndex, logIndex, token, from, to, value));
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

        require(token != address(allowedToken), "can not be allowed token");
        require(to == address(this), "must be transfer to this contract");

        bytes32 hashKey = _hashKey(blockNumber, txIndex, logIndex, token, from, to, value);

        RetrieveStatusEnum retrieveStatus = RetrieveStatusMapping[hashKey];

        require(retrieveStatus == RetrieveStatusEnum.Default, "already submitted");

        RetrieveStatusMapping[hashKey] = RetrieveStatusEnum.VerifiedNotClaimed;

        emit ReadyToWithdraw(token, from, to, value, blockNumber, txIndex, logIndex, hashKey);
    }

    function UnsupportedTokenWithdrawal(
        uint256 blockNumber,
        uint256 txIndex,
        uint256 logIndex,
        address token,
        address from,
        address to,
        uint256 value
    ) external {
        require(from == msg.sender, "only original sender can withdraw");

        bytes32 hashKey = _hashKey(blockNumber, txIndex, logIndex, token, from, to, value);
        RetrieveStatusEnum retrieveStatus = RetrieveStatusMapping[hashKey];
        require(retrieveStatus == RetrieveStatusEnum.VerifiedNotClaimed, "not ready to withdraw");
        RetrieveStatusMapping[hashKey] = RetrieveStatusEnum.ClaimedComplete;

        IERC20(token).safeTransfer(from, value);

        emit WithdrawnComplete(token, address(this), from, value, hashKey);
    }
}
