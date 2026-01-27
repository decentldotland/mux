import { getAo, requireProcessId } from "./lib.js";

const TOKEN_PROCESS = "-J0MsAvcVvuxSIjCu0MKny_VFQOogYH_vMpnDauZ_B4";
const ACCOUNT = "ENlsWruVNCZRCW5asmzkNgigeyKhVzu5jAo3HpRpn7k";

requireProcessId(TOKEN_PROCESS, "TOKEN_PROCESS");
requireProcessId(ACCOUNT, "ACCOUNT");

const { ao, signer } = getAo();

try {
  const messageId = await ao.message({
    process: TOKEN_PROCESS,
    signer,
    tags: [
      { name: "Action", value: "Balance" },
      { name: "Recipient", value: ACCOUNT },
    ],
    data: "",
  });

  const result = await ao.result({ process: TOKEN_PROCESS, message: messageId });
  const message = result?.Messages?.[0] || {};
  const balance = message.Balance ?? message.Data ?? "";
  const account = message.Account ?? ACCOUNT;

  console.log("Balance request sent.", messageId);
  console.log("Account:", account);
  console.log("Balance:", balance);
} catch (err) {
  console.error("Balance request failed.");
  console.error(err);
  if (err && err.cause) {
    console.error("Cause:", err.cause);
  }
  process.exitCode = 1;
}
