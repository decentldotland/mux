import { connect, createSigner } from "@permaweb/aoconnect";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const WALLET_PATH = path.join(__dirname, "..", "darwin.json");
const AO_URL = "https://push.forward.computer";
const SCHEDULER = "n_XZJhUnmldNFo4dhajoPZWhBXuJk-OcQr5JQ49c4Zo";

export function loadWallet() {
  return JSON.parse(fs.readFileSync(WALLET_PATH, "utf-8"));
}

export function getAo() {
  const wallet = loadWallet();
  const signer = createSigner(wallet);

  const ao = connect({
    MODE: "mainnet",
    URL: AO_URL,
    SCHEDULER: SCHEDULER,
    signer,
  });

  return { ao, signer };
}

export function requireProcessId(value, name) {
  if (!value || value === "" || value.includes("_ID_HERE")) {
    throw new Error(`${name} is required`);
  }
}
