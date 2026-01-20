require "shared.types"
require "wallet.types"
local shared_helpers = require "shared.helpers"
local getters = require "wallet.getters"

local mod = {}

local function isActiveAdmin(address: string): boolean
    return (Admins[address] and Admins[address].active)
end

local function requireActiveAdmin(address: string): nil
    assert(isActiveAdmin(address), "active not found or removed")
end

local function requireConfiguredWallet(): nil
    assert(Configured, "smart wallet not configured yet")
end

local function updateAdminLastActivity(msg: Msg, admin: Admin)
    admin.last_activity = msg.Timestamp or ""
end 

local function requireValidThreshold(threshold: string): nil
    shared_helpers.requirePositive(threshold, "new smart wallet threshold value")
    assert(tonumber(threshold) <= getters.getActiveAdminsCount(), "threshold exceeds active admins")
end

local function checkDoubleVoting(voter: string, proposal: Proposal): nil
    for _, d in pairs(proposal.decisions) do 
        assert(d.admin ~= voter, "admin already voted on this proposal")
    end
end

-- resolution logic: first past threshold
local function doesMeetThreshold(proposal: Proposal): Resolution
	local yay_count: number = 0
	local nay_count: number = 0

	for _, decision in pairs(proposal.decisions) do
		if decision.approved then
			yay_count = yay_count + 1
			if yay_count >= Threshold then
				return { resolved = true, result = true }
			end
		else
			nay_count = nay_count + 1
			if nay_count >= Threshold then
				return { resolved = true, result = false }
			end
		end
	end

	return { resolved = false, result = nil }
end

local function renounceOwnership(msg: Msg): nil
    if Owner ~= nil then
        assert(shared_helpers.isOwner(msg.From), "unauthed caller")
        Owner = nil
        shared_helpers.respond(msg, {
            Action = "RenounceOwnership-OK"
        })
        return
    end
    return
end


mod.isActiveAdmin = isActiveAdmin
mod.requireActiveAdmin = requireActiveAdmin
mod.requireConfiguredWallet = requireConfiguredWallet
mod.requireValidThreshold = requireValidThreshold
mod.checkDoubleVoting = checkDoubleVoting
mod.doesMeetThreshold = doesMeetThreshold
mod.updateAdminLastActivity = updateAdminLastActivity
mod.renounceOwnership = renounceOwnership

return mod
