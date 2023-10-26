import { Axiom, AxiomConfig, AxiomV2Callback, AxiomV2ComputeQuery, QueryV2, UnbuiltSubquery } from "@axiom-crypto/experimental";
import { parseEther } from "viem";
import { getRandom32Bytes } from "./utils";

export const useAxiom = (providerUri: string) => {
    const axiomConfig: AxiomConfig = {
        providerUri: providerUri,
        version: "v2",
        chainId: 5,
        mock: true,
    };
    const axiom = new Axiom(axiomConfig);
    const axiomQueryAddress = axiom.getAxiomQueryAddress();
    const axiomAbi = axiom.getAxiomQueryAbi();
    return {
        axiom,
        axiomQueryAddress,
        axiomAbi
    }
}

export const buildSendQuery = async (providerUri: string, { compute, callback, dataQuery, address }: { address: string, compute: AxiomV2ComputeQuery, callback: AxiomV2Callback, dataQuery: UnbuiltSubquery[] }) => {

    const { axiom, axiomQueryAddress, axiomAbi } = useAxiom(providerUri);
    const query = axiom.query as QueryV2;
    const qb = query.new(dataQuery, compute, callback);
    const {
        dataQueryHash,
        dataQuery: dataQueryEncoded,
        computeQuery,
        callback: callbackQuery,
        maxFeePerGas,
        callbackGasLimit,
        sourceChainId
    } = await qb.build();


    const BuiltQuery = qb.getBuiltQuery();
    if (BuiltQuery === undefined) {
        alert('BuiltQuery is undefined');
        throw new Error('BuiltQuery is undefined');
    }
    console.log('querySchema', qb.getBuiltQuery()!.querySchema);

    const salt = getRandom32Bytes();

    return ({
        address: axiomQueryAddress as `0x${string}`,
        abi: axiomAbi,
        functionName: 'sendQuery',
        value: parseEther('0.03'),
        args: [sourceChainId, dataQueryHash, computeQuery, callbackQuery, salt, maxFeePerGas, callbackGasLimit, address, dataQueryEncoded],
    });

}