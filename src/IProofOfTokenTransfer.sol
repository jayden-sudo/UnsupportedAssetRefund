// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/*
    Proof of token transfer Protocol:
        Can prove that the user has a specific transfer record in history (currently only supports ERC20)
 */
interface IProofOfTokenTransfer {
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
    event ProvenTransfer(
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
    ) external pure returns (bytes32);

    /**
     * @dev check if the transfer is proven
     * hashKey = keccak256(abi.encode(blockNumber, txIndex, logIndex, token, from, to, value))
     */
    function isZkpProvenHash(bytes32 hashKey) external view returns (bool);

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
    ) external view returns (bool);
}
