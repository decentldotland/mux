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

    helpers.updateAdminLastActivity(msg, Admins[msg.From])

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
    helpers.updateAdminLastActivity(msg, Admins[msg.From])

	shared_helpers.respond(msg, {
		Target = msg.From,
		Action = "Vote-OK",
		Decision = proposal_decision
	})
end

local function cancelProposal(msg: Msg)
	helpers.requireActiveAdmin(msg.From)
	local proposal_id = shared_helpers.tagOrField(msg, "ProposalId")
	shared_helpers.validateArweaveAddress(proposal_id)
	assert(Proposals[proposal_id] and Proposals[proposal_id].status == "Pending", "proposal do not exist")
    assert(not Executed[proposal_id], "proposal already executed")
	local proposal = Proposals[proposal_id]

	assert(#proposal.decisions == 1 and proposal.decisions[1].admin == msg.From, "only proposal proposer can cancel it if there are no other decisions")

	proposal.status = "Cancelled"
	Executed[proposal_id] = true

	helpers.updateAdminLastActivity(msg, Admins[msg.From])

	shared_helpers.respond(msg, {
		Target = msg.From,
		Action = "Cancel-Proposal-OK"
	})
end

local function tryExecuteProposal(msg: Msg)
	local proposal_id = shared_helpers.tagOrField(msg, "ProposalId")
	shared_helpers.validateArweaveAddress(proposal_id)
	helpers.requireActiveAdmin(msg.From)
	local proposal = Proposals[proposal_id]
    local resolution = nil
	assert(proposal, "proposal not found")
	assert(not Executed[proposal_id], "proposal already executed")

    local is_executable = helpers.doesMeetThreshold(proposal)
    if is_executable.resolved then
        resolution = is_executable.result
    end

	if resolution ~= nil and resolution then
		local msg = {
			Target = proposal.target,
			Action = proposal.action,
			Tags = proposal.tags,
			Data = proposal.data,
		}

		ao.send(msg)

		Executed[proposal_id] = true
		proposal.status = "Executed"
	elseif resolution ~= nil and not resolution then
		Executed[proposal_id] = true
		proposal.status = "Rejected"
	end

	helpers.updateAdminLastActivity(msg, Admins[msg.From])

	shared_helpers.respond(msg, {
		Target = msg.From,
		Action = "Execute-Proposal-OK",
		Status = proposal.status
	})
end

local function configure(msg: Msg): nil
    assert(not Configured, "wallet already configured")
    assert(shared_helpers.isOwner(msg.From), "unauthed caller")
    local name = shared_helpers.tagOrField(msg, "Name")
    local admin_label = shared_helpers.tagOrField(msg, "AdminLabel") or "notthatguy"
    local admin: Admin = {
        address = msg.From,
        label = admin_label,
        active = true,
        joined = msg.Timestamp,
        last_activity = msg.Timestamp
    }

    if name ~= nil and name ~= "" then
        Name = name
    end

    Admins[msg.From] = admin
    Configured = true

	shared_helpers.respond(msg, {
		Action = "Configure-OK"
	})

end


mod.addProposal = addProposal
mod.voteProposal = voteProposal
mod.tryExecuteProposal = tryExecuteProposal
mod.cancelProposal = cancelProposal
mod.configure = configure

return mod
