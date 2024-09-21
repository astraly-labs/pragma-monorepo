import type { Deployer, Chain } from './interface';

export class OracleDeployer implements Deployer {
    readonly allowedChains: Chain[] = ['starknet'];
    async deploy(): Promise<void> {
        console.log('Oracle deployment is not yet implemented. Exiting.');
        process.exit(0);
    }
}
