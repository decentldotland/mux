import { getAo, requireProcessId } from "./lib.js";

const DEFAULT_WALLET_PROCESS = "92vBrWgS3fzWj7Dv5tbFg6OKGHQWrglNSI1XSr-CaSY";
const DEFAULT_PROPOSAL_ID = "OUWsZyCRPHAGxerfvoNWRYbChGiLb8JEBUV6M0QWsjk";

const [walletArg, proposalArg] = process.argv.slice(2);
const WALLET_PROCESS = walletArg || DEFAULT_WALLET_PROCESS;
const PROPOSAL_ID = proposalArg || DEFAULT_PROPOSAL_ID;

requireProcessId(WALLET_PROCESS, "WALLET_PROCESS");
requireProcessId(PROPOSAL_ID, "PROPOSAL_ID");

const { ao, signer } = getAo();

try {
  const messageId = await ao.message({
    process: WALLET_PROCESS,
    signer,
    tags: [
      { name: "Action", value: "Execute" },
      { name: "ProposalId", value: PROPOSAL_ID },
    ],
  });

  const result = await ao.result({ process: WALLET_PROCESS, message: messageId });
  console.log("Execute sent.", messageId);
  console.log("Result:", JSON.stringify(result, null, 2));
} catch (err) {
  console.error("Execute failed.");
  console.error(err);
  if (err && err.cause) {
    console.error("Cause:", err.cause);
  }
  process.exitCode = 1;
}
