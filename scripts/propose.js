import { getAo, requireProcessId } from "./lib.js";

const WALLET_PROCESS = "WALLET_PROCESS_ID_HERE";
const TARGET = "TARGET_PROCESS_ID_HERE";
const ACTION = "Transfer";
const TAGS_JSON = '{"Recipient":"RECIPIENT_ID","Quantity":"1000"}';
const DATA = "";

requireProcessId(WALLET_PROCESS, "WALLET_PROCESS");
requireProcessId(TARGET, "TARGET");

const { ao, signer } = getAo();

let tags = {};
try {
  tags = JSON.parse(TAGS_JSON);
} catch {
  console.error("Invalid TAGS JSON.");
  process.exit(1);
}

const proposal = {
  Target: TARGET,
  Action: ACTION,
  Tags: tags,
  Data: DATA,
};

try {
  const messageId = await ao.message({
    process: WALLET_PROCESS,
    signer,
    tags: [{ name: "Action", value: "Propose" }],
    data: JSON.stringify(proposal),
  });

  const result = await ao.result({ process: WALLET_PROCESS, message: messageId });
  console.log("Propose sent.", messageId);
  console.log("Result:", JSON.stringify(result, null, 2));
} catch (err) {
  console.error("Propose failed.");
  console.error(err);
  if (err && err.cause) {
    console.error("Cause:", err.cause);
  }
  process.exitCode = 1;
}
