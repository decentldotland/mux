import { connect, createSigner } from "@permaweb/aoconnect";
import fs from "fs";

const WALLET_PATH = "./wallet.json";
const AO_URL = "https://push.forward.computer";
const SCHEDULER = "n_XZJhUnmldNFo4dhajoPZWhBXuJk-OcQr5JQ49c4Zo";

const TOKEN_PROCESS = "9LlXbsC0xhk8v-piccUnK0Viik4sPADFBs0nAz5y2BM";
const WALLET_PROCESS = "92vBrWgS3fzWj7Dv5tbFg6OKGHQWrglNSI1XSr-CaSY";
const QUANTITY = "1000";

const wallet = JSON.parse(fs.readFileSync(WALLET_PATH, "utf-8"));
const signer = createSigner(wallet);

const ao = connect({
  MODE: "mainnet",
  URL: AO_URL,
  SCHEDULER,
  signer,
});

try {
  const messageId = await ao.message({
    process: TOKEN_PROCESS,
    signer,
    tags: [
      { name: "Action", value: "Transfer" },
      { name: "Recipient", value: WALLET_PROCESS },
      { name: "Quantity", value: QUANTITY },
    ],
  });

  const result = await ao.result({ process: TOKEN_PROCESS, message: messageId });
  console.log("Transfer sent.");
  console.log("Result:", JSON.stringify(result, null, 2));
} catch (err) {
  console.error("Transfer failed.");
  console.error(err);
  if (err && err.cause) {
    console.error("Cause:", err.cause);
  }
  process.exitCode = 1;
}
