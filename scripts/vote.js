import { getAo, requireProcessId } from "./lib.js";

const DEFAULT_WALLET_PROCESS = "PQaxNfVJg8klWnqZgfc7joyNzDK-o5auWETQS8bFvHk";
const DEFAULT_PROPOSAL_ID = "-qwvvx_SOV6HY2I2dLc8H4F8loytzcloYfYV4bTxhsE";
const DEFAULT_DECISION = "true";

const [walletArg, proposalArg, decisionArg] = process.argv.slice(2);
const WALLET_PROCESS = walletArg || DEFAULT_WALLET_PROCESS;
const PROPOSAL_ID = proposalArg || DEFAULT_PROPOSAL_ID;
const DECISION = decisionArg || DEFAULT_DECISION;

requireProcessId(WALLET_PROCESS, "WALLET_PROCESS");
requireProcessId(PROPOSAL_ID, "PROPOSAL_ID");
if (DECISION !== "true" && DECISION !== "false") {
  throw new Error('DECISION must be "true" or "false".');
}

const { ao, signer } = getAo();

try {
  const messageId = await ao.message({
    process: WALLET_PROCESS,
    signer,
    tags: [
      { name: "Action", value: "Vote" },
      { name: "ProposalId", value: PROPOSAL_ID },
      { name: "Decision", value: DECISION },
    ],
  });

  const result = await ao.result({ process: WALLET_PROCESS, message: messageId });
  console.log("Vote sent.", messageId);
  console.log("Result:", JSON.stringify(result, null, 2));
} catch (err) {
  console.error("Vote failed.");
  console.error(err);
  if (err && err.cause) {
    console.error("Cause:", err.cause);
  }
  process.exitCode = 1;
}
