import { getAo, requireProcessId } from "./lib.js";

// const WALLET_PROCESS = "VkX6avkS4PlCKOTTPy04QkGqlFQFT_AiH1u_WdzMLII";
const WALLET_PROCESS = "PQaxNfVJg8klWnqZgfc7joyNzDK-o5auWETQS8bFvHk"
const WALLET_NAME = "mux-wallet";
const ADMINS_JSON = '["LgvXR-b31qXUT4QBwqoP8MJJcDiRYfGDODjD7FYnV6o","vZY2XY1RD9HIfWi8ift-1_DnHLDadZMWrufSh-_rKF0"]';
const THRESHOLD = "1";
const RENOUNCE = "false";

requireProcessId(WALLET_PROCESS, "WALLET_PROCESS");

const { ao, signer } = getAo();

try {
  const messageId = await ao.message({
    process: WALLET_PROCESS,
    signer,
    tags: [
      { name: "Action", value: "Configure" },
      { name: "Name", value: WALLET_NAME },
      { name: "Admins", value: ADMINS_JSON },
      { name: "Threshold", value: THRESHOLD },
      { name: "RenounceOwnership", value: RENOUNCE },
    ],
  });

  const result = await ao.result({ process: WALLET_PROCESS, message: messageId });
  console.log("Configure sent.", messageId);
  console.log("Result:", JSON.stringify(result, null, 2));
} catch (err) {
  console.error("Configure failed.");
  console.error(err);
  if (err && err.cause) {
    console.error("Cause:", err.cause);
  }
  process.exitCode = 1;
}
