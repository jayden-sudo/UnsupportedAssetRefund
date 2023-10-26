import { JsonRpcProvider } from "ethers";
import { CircuitConfig, CircuitScaffold, Halo2LibWasm, getHalo2LibWasm } from '@axiom-crypto/experimental/halo2-js/web';
import { AxiomCircuitRunner } from "@axiom-crypto/experimental/halo2-js";
import { CircuitInputs, circuit } from "./circuit";
import { convertToBytes, convertToBytes32 } from "../../shared/utils";
import { UnbuiltSubquery } from "@axiom-crypto/experimental";
import { DataQuery, getNewDataQuery } from "@axiom-crypto/experimental/v2/circuit/utils";
import { expose } from 'comlink';

export class AxiomCircuit extends CircuitScaffold {
    provider: JsonRpcProvider;
    halo2Lib!: Halo2LibWasm;
    private dataQuery!: DataQuery;


    constructor(provider: string) {
        super({ shouldTime: true });
        this.provider = new JsonRpcProvider(provider);
        this.config = circuit.config;
        // this.dataQuery = getNewDataQuery();
    }

    async setup(numThreads: number) {
        await super.setup(numThreads);
        this.halo2Lib = getHalo2LibWasm(this.halo2wasm);
    }

    async newCircuitFromConfig() {
        super.newCircuitFromConfig(this.config);
        await this.loadParamsAndVk(new Uint8Array(circuit.vk));
    }

    async run(inputs: string) {

        let circuitInputs: CircuitInputs;
        try {
            circuitInputs = JSON.parse(inputs);
        } catch (error) {
            console.error(error);
            return;
        }

        this.newCircuitFromConfig();
        this.timeStart("Witness generation");
        const { dataQuery, results } = await AxiomCircuitRunner(this.halo2wasm, this.halo2Lib, this.config, this.provider).build(circuit.circuit, circuitInputs as any);
        const { numUserInstances } = await AxiomCircuitRunner(this.halo2wasm, this.halo2Lib, this.config, this.provider).run(circuit.circuit, circuitInputs as any, results);
        this.timeEnd("Witness generation");
        this.prove();
        const proof = this.getComputeProof();
        const vk = this.getVk();
        this.dataQuery = dataQuery;
        const dataQueryResult = await this.getDataQuery();
        return {
            proof,
            vk,
            dataQuery: dataQueryResult,
            resultLen: numUserInstances / 2
        }
    }

    getComputeProof = () => {
        if (!this.proof) throw new Error("No proof generated");
        let proofString = "";
        const instances = this.getInstances();
        for (let i = 0; i < 2; i++) {
            const instanceHi = BigInt(instances[2 * i]);
            const instanceLo = BigInt(instances[2 * i + 1]);
            const instance = instanceHi * BigInt(2 ** 128) + instanceLo;
            const instanceString = instance.toString(16).padStart(64, "0");
            proofString += instanceString;
        }
        proofString += convertToBytes(this.proof);
        return "0x" + proofString;
    }

    getVk() {
        const vk = this.halo2wasm.getPartialVk();
        return convertToBytes32(vk);
    }

    async getDataQuery() {
        let dataSubquery: UnbuiltSubquery[] = [];
        for (let headerSubquery of this.dataQuery.headerSubqueries) {
            dataSubquery.push(headerSubquery)
        }
        for (let accountSubquery of this.dataQuery.accountSubqueries) {
            dataSubquery.push(accountSubquery)
        }
        for (let storageSubquery of this.dataQuery.storageSubqueries) {
            dataSubquery.push(storageSubquery)
        }
        for (let txSubquery of this.dataQuery.txSubqueries) {
            const block = await this.provider.getBlock(txSubquery.blockNumber);
            const txHash = block?.transactions[txSubquery.txIdx];
            const subquery = {
                txHash,
                fieldOrCalldataIdx: txSubquery.fieldOrCalldataIdx,
            }
            dataSubquery.push(subquery)
        }
        for (let receiptSubquery of this.dataQuery.receiptSubqueries) {
            const block = await this.provider.getBlock(receiptSubquery.blockNumber);
            const txHash = block?.transactions[receiptSubquery.txIdx];
            const subquery = {
                txHash,
                fieldOrLogIdx: receiptSubquery.fieldOrLogIdx,
                topicOrDataOrAddressIdx: receiptSubquery.topicOrDataOrAddressIdx,
                eventSchema: receiptSubquery.eventSchema,
            }
            dataSubquery.push(subquery)
        }
        for (let solidityNestedMappingSubquery of this.dataQuery.solidityNestedMappingSubqueries) {
            dataSubquery.push(solidityNestedMappingSubquery)
        }
        return dataSubquery;
    }
}

expose(AxiomCircuit);