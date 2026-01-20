  import { getAo, requireProcessId } from "./lib.js";

  const WALLET_PROCESS = "VkX6avkS4PlCKOTTPy04QkGqlFQFT_AiH1u_WdzMLII";
  const TOKEN_PROCESS = "9N0mCvF4Q_jJs7XVuj34E5x6aYQGP9iTWpz955BHmLA";
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
