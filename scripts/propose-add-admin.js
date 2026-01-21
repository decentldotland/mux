import { getAo, requireProcessId } from "./lib.js";

const WALLET_PROCESS = "PQaxNfVJg8klWnqZgfc7joyNzDK-o5auWETQS8bFvHk";
const NEW_ADMIN = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
const ADMIN_LABEL = "admin-aaaaa";

requireProcessId(WALLET_PROCESS, "WALLET_PROCESS");
requireProcessId(NEW_ADMIN, "NEW_ADMIN");

const { ao, signer } = getAo();

const proposal = {
  Target: WALLET_PROCESS,
  Action: "AddAdmin",
  Tags: {
    AdminAddress: NEW_ADMIN,
    AdminLabel: ADMIN_LABEL,
  },
  Data: "",
};

try {
  const messageId = await ao.message({
    process: WALLET_PROCESS,
    signer,
    tags: [{ name: "Action", value: "Propose" }],
    data: JSON.stringify(proposal),
  });

  const result = await ao.result({ process: WALLET_PROCESS, message: messageId });
  console.log("Propose AddAdmin sent.", messageId);
  console.log("Result:", JSON.stringify(result, null, 2));
} catch (err) {
  console.error("Propose AddAdmin failed.");
  console.error(err);
  if (err && err.cause) {
    console.error("Cause:", err.cause);
  }
  process.exitCode = 1;
}
