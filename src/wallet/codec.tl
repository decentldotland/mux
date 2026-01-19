require "shared.types"
local deps = require "shared.deps"
local json = deps.json

local mod = {}

local function decodeProposalPayload(msg: Msg): {string: any}
	local payload = msg.Data or ""
	local ok, decoded = pcall(json.decode, payload)
	assert(ok and type(decoded) == "table", "invalid proposal data payload")
	return decoded
end

mod.decodeProposalPayload = decodeProposalPayload

return mod