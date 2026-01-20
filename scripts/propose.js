  import { getAo, requireProcessId } from "./lib.js";

  const WALLET_PROCESS = "92vBrWgS3fzWj7Dv5tbFg6OKGHQWrglNSI1XSr-CaSY";
  const TOKEN_PROCESS = "9LlXbsC0xhk8v-piccUnK0Viik4sPADFBs0nAz5y2BM";
  const RECIPIENT = "vZY2XY1RD9HIfWi8ift-1_DnHLDadZMWrufSh-_rKF0";
  const QUANTITY = "1";

  requireProcessId(WALLET_PROCESS, "WALLET_PROCESS");
  requireProcessId(TOKEN_PROCESS, "TOKEN_PROCESS");
  requireProcessId(RECIPIENT, "RECIPIENT");

  const { ao, signer } = getAo();

  const proposal = {
    Target: TOKEN_PROCESS,
    Action: "Transfer",
    Tags: {
      Action: "Transfer",
      Recipient: RECIPIENT,
      Quantity: QUANTITY,
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
    console.log("Propose Transfer sent.", messageId);
    console.log("Result:", JSON.stringify(result, null, 2));
  } catch (err) {
    console.error("Propose Transfer failed.");
    console.error(err);
    if (err && err.cause) {
      console.error("Cause:", err.cause);
    }
    process.exitCode = 1;
  }
