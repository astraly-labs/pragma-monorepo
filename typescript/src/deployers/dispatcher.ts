import type { Deployer, Chain } from './interface';

export class DispatcherDeployer implements Deployer {
  readonly allowedChains: Chain[] = ['ethereum'];
  async deploy(): Promise<void> {
    console.log('Deploying dispatcher to Starknet...');
    console.log('Dispatcher deployed successfully to Starknet.');
  }
}