export type Chain = 'starknet' | 'ethereum';

/// Main interface called when deploying a contract
export interface Deployer {
    readonly allowedChains: Chain[];
    deploy(chain?: string): Promise<void>;
}
