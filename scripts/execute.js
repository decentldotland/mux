import { getAo, requireProcessId } from "./lib.js";

const WALLET_PROCESS = "WALLET_PROCESS_ID_HERE";
const PROPOSAL_ID = "PROPOSAL_ID_HERE";

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
