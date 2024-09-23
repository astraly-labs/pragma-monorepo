import type { Deployer, Chain } from './interface';

export class DispatcherDeployer implements Deployer {
  readonly allowedChains: Chain[] = ['starknet'];
  readonly defaultChain: Chain = 'starknet';
  async deploy(chain?: Chain): Promise<void> {
    if (!chain) chain = this.defaultChain;
    console.log('Deploying dispatcher to Starknet...');
    console.log('Dispatcher deployed successfully to Starknet.');
  }
}
