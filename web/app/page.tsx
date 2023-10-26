"use client"

import { wrap, Remote } from "comlink";
import { useRef, useEffect, useState } from "react";
import { AxiomV2Callback, AxiomV2ComputeQuery } from "@axiom-crypto/experimental";
import { AxiomCircuit } from "./worker";
import { circuit } from "./worker/circuit";
import { ConnectKitButton } from "connectkit";
import { writeContract } from "wagmi/actions";
import { buildSendQuery } from "@/shared/axiom";
import { useAccount } from "wagmi";

const providerUri = `https://eth-goerli.g.alchemy.com/v2/${process.env.NEXT_PUBLIC_ALCHEMY_KEY}`;

export default function Home() {

  const [input, setInput] = useState<string>(JSON.stringify(circuit.defaultInputs));
  const [target, setTarget] = useState<string>("0x3dDce6DF15Da1DA7b03Bfb81c88f72392e3A4799");
  const [extraData, setExtraData] = useState<string>("0x0");
  const { address } = useAccount();

  const workerApi = useRef<Remote<AxiomCircuit>>();
  useEffect(() => {
    const setupWorker = async () => {
      const worker = new Worker(new URL("./worker", import.meta.url), { type: "module" });
      const Circuit = wrap<typeof AxiomCircuit>(worker);
      workerApi.current = await new Circuit("https://eth-goerli.g.alchemy.com/v2/nYc8JJ48348qILd9VjKxRKLPlqE4rIP0");
      await workerApi.current.setup(window.navigator.hardwareConcurrency);
    }
    setupWorker();
  }, []);

  const generateAndSendQuery = async () => {
    if(!workerApi.current) throw new Error("Worker not ready");
    const res = await workerApi.current?.run(input);
    // console.log(res);
    if(!res) throw new Error("Failed to generate proof");
    const {proof, vk, dataQuery, resultLen} = res;

    const compute: AxiomV2ComputeQuery = {
      k: circuit.config.k,
      vkey: vk,
      computeProof: proof,
      resultLen,
    };

    const callback: AxiomV2Callback = {
      target,
      extraData,
    }

    const builtQuery = await buildSendQuery(providerUri, { compute, callback, dataQuery, address: address ?? "0x0" });

    const { hash } = await writeContract(builtQuery)

    console.log(`Sent query: https://goerli.etherscan.io/tx/${hash}`)
  }

  return (
    <div className="flex flex-col p-4 gap-2">
      <ConnectKitButton />
      <div className="flex gap-2">
        <button onClick={generateAndSendQuery} className="border py-2 px-4 rounded">
          Build and Send Query (on Goerli)
        </button>
      </div>
      <div className="flex flex-col">
        <label htmlFor="input" className="mr-2">Circuit inputs:</label>
        <textarea id="input" value={input} onChange={(e) => setInput(e.target.value)} className="px-1 border rounded" />
      </div>

      <div className="flex flex-col gap-2">
        <div className="flex flex-col"> 
          Callback Address:
          <a href={`https://goerli.etherscan.io/address/${target}`} target="_blank" >{target}</a>
         
        </div>
        <div className="flex flex-col" style={{display:'none'}}>
          <label htmlFor="extraData" className="mr-2">Callback Extra Data:</label>
          <textarea id="extraData" value={extraData} onChange={(e) => setExtraData(e.target.value)} className="px-1 border rounded" />
        </div>
      </div>

      <div className="semi-bold">
        Open Developer Console to see logs and outputs!
      </div>
    </div>
  )

}