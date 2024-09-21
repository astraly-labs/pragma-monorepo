import { Command } from 'commander';
import deploymentManager from './manager';

const program = new Command();

program
  .description('CLI to deploy Pragma contracts')
  .arguments('<contract>')
  .option('-c, --chain <chain>', 'Specify the chain for pragma deployments')
  .action(async (contract: string, options) => {
    try {
      await deploymentManager.deploy(contract.toLocaleLowerCase(), options.chain);
    } catch (error) {
      console.error('Deployment failed:', (error as Error).message);
      process.exit(1);
    }
  });

program.parse(process.argv);
