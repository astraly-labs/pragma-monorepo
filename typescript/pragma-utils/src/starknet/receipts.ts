import {
  type GetTransactionReceiptResponse,
  ProviderInterface,
  RPC,
  TransactionExecutionStatus,
  TransactionFinalityStatus,
} from "starknet";
export type AcceptedTransactionReceiptResponse =
  GetTransactionReceiptResponse & { transaction_hash: string };

// this might eventually be solved in starknet.js https://github.com/starknet-io/starknet.js/issues/796
export function isAcceptedTransactionReceiptResponse(
  receipt: GetTransactionReceiptResponse,
): receipt is AcceptedTransactionReceiptResponse {
  return "transaction_hash" in receipt;
}

export function isIncludedTransactionReceiptResponse(
  receipt: GetTransactionReceiptResponse,
): receipt is RPC.Receipt {
  return "block_number" in receipt;
}

export async function ensureSuccess(
  receipt: GetTransactionReceiptResponse,
  provider: ProviderInterface,
): Promise<RPC.Receipt> {
  const tx = await provider.waitForTransaction(receipt.transaction_hash, {
    successStates: [
      TransactionFinalityStatus.ACCEPTED_ON_L1,
      TransactionFinalityStatus.ACCEPTED_ON_L2,
    ],
  });

  if (tx.execution_status !== TransactionExecutionStatus.SUCCEEDED) {
    let errorMessage = `Transaction ${receipt.transaction_hash} REVERTED`;

    // Extract revert reason if available
    if ("revert_reason" in tx && tx.revert_reason) {
      errorMessage += `\nRevert reason: ${tx.revert_reason}`;
    }

    // Check for transaction_failure_reason
    if ("transaction_failure_reason" in tx && tx.transaction_failure_reason) {
      errorMessage += `\nFailure reason: ${JSON.stringify(tx.transaction_failure_reason)}`;
    }

    // Check for events that might contain error information
    if ("events" in tx && tx.events && tx.events.length > 0) {
      const errorEvent = tx.events.find(
        (event) => event.keys.includes("Error") || event.keys.includes("error"),
      );
      if (errorEvent) {
        errorMessage += `\nError event: ${JSON.stringify(errorEvent)}`;
      }
    }

    console.error(errorMessage);
    throw new Error(errorMessage);
  }

  return receipt as RPC.Receipt;
}

export async function ensureAccepted(
  receipt: GetTransactionReceiptResponse,
  provider: ProviderInterface,
): Promise<RPC.Receipt> {
  await provider.waitForTransaction(receipt.transaction_hash, {
    successStates: [
      TransactionFinalityStatus.ACCEPTED_ON_L1,
      TransactionFinalityStatus.ACCEPTED_ON_L2,
    ],
  });
  return receipt as RPC.Receipt;
}

export async function ensureIncluded(
  receipt: GetTransactionReceiptResponse,
  provider: ProviderInterface,
): Promise<RPC.Receipt> {
  const acceptedReceipt = await ensureAccepted(receipt, provider);
  if (!isIncludedTransactionReceiptResponse(acceptedReceipt)) {
    throw new Error(
      `Transaction was not included in a block: ${JSON.stringify(receipt, null, 2)}`,
    );
  }
  return acceptedReceipt;
}

export async function waitForInclusion(
  transactionHash: string,
  provider: ProviderInterface,
): Promise<RPC.Receipt> {
  let receipt;
  for (let i = 0; i < 10; i++) {
    receipt = await ensureAccepted(
      await provider.waitForTransaction(transactionHash),
      provider,
    );
    if (isIncludedTransactionReceiptResponse(receipt)) {
      return receipt;
    }
    await sleep(1000);
  }
  throw new Error(
    `Transaction was not included in a block after 10 tries: ${JSON.stringify(receipt, null, 2)}`,
  );
}

async function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
