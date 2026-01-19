require "shared.types"
require "wallet.types"
local shared_helpers = require "shared.helpers"
local helpers = require "wallet.helpers"
local codec = require "wallet.codec"

local mod = {}


local function addProposal(msg: Msg)
	helpers.requireActiveAdmin(msg.From)
	local proposal_id = shared_helpers.getMsgId(msg)
	assert(proposal_id and proposal_id ~= "", "proposal id missing")
	assert(not Proposals[proposal_id], "proposal already exists")

	local payload = codec.decodeProposalPayload(msg)
	local target = payload.Target
	local action = payload.Action
	local tags = payload.Tags
	local data = payload.Data or ""

	assert(target and target ~= "", "proposal target required")
	assert(action and action ~= "", "proposal action required")
	shared_helpers.validateArweaveAddress(target)

	local proposer_decision: Decision = { admin = msg.From, approved = true }
	local proposal_status: Status = "Pending"
	local proposal_nonce: number = Nonce
	Nonce = Nonce + 1

	Proposals[proposal_id] = {
		proposer = msg.From,
		id = proposal_id,
		decisions = { proposer_decision },
		target = target,
		action = action,
		data = data,
		tags = tags,
		status = proposal_status,
		nonce = proposal_nonce,
		created_at = msg.Timestamp or ""
	}

	shared_helpers.respond(msg, {
		Action = "Propose-OK",
		ProposalId = proposal_id,
		Status = proposal_status
	})
end

local function voteProposal(msg: Msg)
    helpers.requireActiveAdmin(msg.From)
    local proposal_id = shared_helpers.tagOrField(msg, "ProposalId")
    local decision_tag = shared_helpers.tagOrField(msg, "Decision")
    local proposal_decision = decision_tag == "true"
	assert(proposal_id and proposal_id ~= "", "proposal id missing")
	assert(Proposals[proposal_id] and Proposals[proposal_id].status == "Pending", "proposal do not exist")
    assert(not Executed[proposal_id], "proposal aleady executed")
    helpers.checkDoubleVoting(msg.From, Proposals[proposal_id])
    
    local decision: Decision = {
        admin = msg.From,
        approved = proposal_decision,
        voted = true,
        timestamp = msg.Timestamp or ""
    }

    table.insert(Proposals[proposal_id].decisions, decision)

    local is_executable = helpers.doesMeetThreshold(Proposals[proposal_id])

    if is_executable.resolved then
        executeProposal(proposal_id, is_executable.result)
    end
end

local function executeProposal(proposal_id: string, resolution: boolean)
	local proposal = Proposals[proposal_id]
	assert(proposal, "proposal not found")
	assert(not Executed[proposal_id], "proposal already executed")

	if resolution then
		local msg = {
		Target = proposal.target,
		Action = proposal.action,
		Tags = proposal.tags,
		Data = proposal.data,
	}


	ao.send(msg)

		Executed[proposal_id] = true
		proposal.status = "Executed"
	else
		Executed[proposal_id] = true
		proposal.status = "Rejected"
	end
end




mod.addProposal = addProposal
mod.voteProposal = voteProposal
mod.executeProposal = executeProposal

return mod
