import { getAo, requireProcessId } from "./lib.js";

const TOKEN_PROCESS = "-J0MsAvcVvuxSIjCu0MKny_VFQOogYH_vMpnDauZ_B4";

requireProcessId(TOKEN_PROCESS, "TOKEN_PROCESS");

const { ao, signer } = getAo();

try {
  const messageId = await ao.message({
    process: TOKEN_PROCESS,
    signer,
    tags: [{ name: "Action", value: "Balances" }],
    data: "",
  });

  const result = await ao.result({ process: TOKEN_PROCESS, message: messageId });
  console.log("Balances request sent.", messageId);
  const data = result?.Messages?.[0]?.Data;
  if (typeof data === "string" && data.length > 0) {
    try {
      const balances = JSON.parse(data);
      console.log("Balances:", JSON.stringify(balances, null, 2));
    //   return;
    } catch {
      console.log("Raw balances data:", data);
    //   return;
    }
  }
  console.log("Result:", JSON.stringify(result, null, 2));
} catch (err) {
  console.error("Balances request failed.");
  console.error(err);
  if (err && err.cause) {
    console.error("Cause:", err.cause);
  }
  process.exitCode = 1;
}
