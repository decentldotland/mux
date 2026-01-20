import { getAo, requireProcessId } from "./lib.js";

const WALLET_PROCESS = "VkX6avkS4PlCKOTTPy04QkGqlFQFT_AiH1u_WdzMLII";
const PROPOSAL_ID = "2pnS3LAUjQLVhPfle2AY1Gr-aSBFSgMVq68Mge00zZQ";

requireProcessId(WALLET_PROCESS, "WALLET_PROCESS");
requireProcessId(PROPOSAL_ID, "PROPOSAL_ID");

const { ao, signer } = getAo();

try {
  const messageId = await ao.message({
    process: WALLET_PROCESS,
    signer,
    tags: [
      { name: "Action", value: "Cancel" },
      { name: "ProposalId", value: PROPOSAL_ID },
    ],
  });

  const result = await ao.result({ process: WALLET_PROCESS, message: messageId });
  console.log("Cancel sent.", messageId);
  console.log("Result:", JSON.stringify(result, null, 2));
} catch (err) {
  console.error("Cancel failed.");
  console.error(err);
  if (err && err.cause) {
    console.error("Cause:", err.cause);
  }
  process.exitCode = 1;
}
