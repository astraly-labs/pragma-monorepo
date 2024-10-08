import fs from "fs";
import { type DeclareContractPayload, ec, encode, json } from "starknet";

import {
  Account,
  type Calldata,
  type CompiledContract,
  Contract,
  hash,
  RpcProvider,
} from "starknet";

type projectName = "oracle" | "dispatcher";

export class BaseDeployer extends Account {
  constructor(
    public provider: RpcProvider,
    public account: Account,
    private alreadyDeclared: Record<string, string> = {},
  ) {
    super(provider, account.address, account.signer);
    this.account = account;
  }

  async loadContract(contractAddress: string) {
    const { abi } = await this.getClassAt(contractAddress);
    return new Contract(abi, contractAddress, this.provider);
  }

  async declareCached(projectName: projectName, contractName: string) {
    if (this.alreadyDeclared[contractName]) {
      return this.alreadyDeclared[contractName];
    }
    const { transaction_hash, class_hash } = await this.declareIfNot(
      readArtifacts(projectName, contractName),
    );
    if (transaction_hash != undefined && transaction_hash.length > 0) {
      await this.waitForTransaction(transaction_hash);
    }
    this.alreadyDeclared[contractName] = class_hash;
    return class_hash;
  }

  async declareCachedWithPayload(
    name: string,
    payload: DeclareContractPayload,
  ) {
    if (this.alreadyDeclared[name]) {
      return this.alreadyDeclared[name];
    }
    const { transaction_hash, class_hash } = await this.declareIfNot(payload);
    if (transaction_hash != undefined && transaction_hash.length > 0) {
      await this.waitForTransaction(transaction_hash);
    }
    this.alreadyDeclared[name] = class_hash;
    return class_hash;
  }

  async deferContract(
    projectName: projectName,
    contractName: string,
    constructorCalldata: Calldata = [],
    deterministic: boolean = false,
  ) {
    const payload = readArtifacts(projectName, contractName);
    const classHash = await this.declareCachedWithPayload(
      contractName,
      payload,
    );
    const salt = deterministic ? "0" : randomHex();
    const contractAddress = hash.calculateContractAddressFromHash(
      salt,
      classHash,
      constructorCalldata,
      0,
    );
    const { abi } = payload.contract as CompiledContract;
    const contract = new Contract(abi, contractAddress, this.account);
    const calls = this.buildUDCContractPayload({
      classHash,
      salt,
      constructorCalldata,
      unique: false,
    });
    return [contract, calls] as const;
  }
}

function getProjectBuildFolder(project: projectName): string {
  if (project === "oracle") {
    return "../../cairo/oracle/target/dev";
  } else if (project === "dispatcher") {
    return "../../cairo/dispatcher/target/dev";
  } else {
    throw new Error("Unsupported project");
  }
}

function readArtifacts(
  project: projectName,
  contract: string,
): DeclareContractPayload {
  return {
    contract: readArtifact(
      `${getProjectBuildFolder(project)}/${contract}.contract_class.json`,
    ),
    casm: readArtifact(
      `${getProjectBuildFolder(project)}/${contract}.compiled_contract_class.json`,
    ),
  };
}

function readArtifact(path: string) {
  return json.parse(fs.readFileSync(path).toString("ascii"));
}

export function randomHex() {
  return `0x${encode.buf2hex(ec.starkCurve.utils.randomPrivateKey())}`;
}

export class Deployer extends BaseDeployer {
  constructor(
    public provider: RpcProvider,
    account: Account,
  ) {
    super(provider, account);
  }
}
