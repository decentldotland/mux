require "shared.types"
require "wallet.types"
local shared_helpers = require "shared.helpers"
local constants = require "shared.constants"
local helpers = require "wallet.helpers"
local codec = require "wallet.codec"
local getters = require "wallet.getters"
local deps = require "shared.deps"
local patch = require "wallet.patch"

local mod = {}

local function buildTagArray(action: string, tags: {Tag} | {string: string} | nil): {Tag}
	local tag_array: {Tag} = {
		{ name = "Action", value = action }
	}
	if tags then
		if tags[1] then
			for _, tag in ipairs(tags) do
				local tag_name = tag.name or tag.Name
				local tag_value = tag.value or tag.Value
				if tag_name ~= nil and string.lower(tag_name) ~= "action" then
					table.insert(tag_array, { name = tag_name, value = tostring(tag_value) })
				end
			end
		else
			for k, v in pairs(tags) do
				if string.lower(k) ~= "action" then
					table.insert(tag_array, { name = k, value = tostring(v) })
				end
			end
		end
	end
	return tag_array
end

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

	patch.emitPendingPatch()
	patch.emitMuxPatch()
end
local function voteProposal(msg: Msg)
    helpers.requireActiveAdmin(msg.From)
    local proposal_id = shared_helpers.tagOrField(msg, "ProposalId")
    local decision_tag = shared_helpers.tagOrField(msg, "Decision")
    assert(decision_tag == "true" or decision_tag == "false", "Decision must be true or false")
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

	patch.emitPendingPatch()
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

	patch.emitCancelledPatch()
	patch.emitExecutedPatch()
	patch.emitPendingPatch()
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
		local outgoing_tags: {Tag} | {string: string} | nil = nil
		if proposal.tags and proposal.tags[1] == nil then
			outgoing_tags = proposal.tags
			if outgoing_tags["Action"] == nil and outgoing_tags["action"] == nil then
				outgoing_tags["Action"] = proposal.action
			end
		else
			outgoing_tags = buildTagArray(proposal.action, proposal.tags)
		end

		local mux_msg = {
			Target = proposal.target,
			Tags = outgoing_tags,
			Data = proposal.data,
		}

		ao.send(mux_msg)

		Executed[proposal_id] = true
		proposal.status = "Executed"
		patch.emitExecutedPatch()
		patch.emitPendingPatch()
	elseif resolution ~= nil and not resolution then
		Executed[proposal_id] = true
		proposal.status = "Rejected"
		patch.emitRejectedPatch()
		patch.emitExecutedPatch()
		patch.emitPendingPatch()
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
	local renounce_ownership = shared_helpers.tagOrField(msg, "RenounceOwnership")
	-- Admins = '["addr1","addr2"]' or '[{"address":"addr1","label":"alice"}]'
    local admins_raw = shared_helpers.tagOrField(msg, "Admins")
    local threshold_raw = shared_helpers.tagOrField(msg, "Threshold")
	local ts = msg.Timestamp or ""

    if name ~= nil and name ~= "" then
        Name = name
    end

	assert(admins_raw and admins_raw ~= "", "Admins list required")
	assert(threshold_raw and threshold_raw ~= "", "Threshold required")

    Admins = {}
	local ok, decoded = pcall(deps.json.decode, admins_raw)
	assert(ok and type(decoded) == "table", "Admins must be a JSON array")
	for _, admin_entry in ipairs(decoded) do
		local admin_address = admin_entry
		local admin_label = "admin"
		if type(admin_entry) == "table" then
			admin_address = admin_entry.address
			admin_label = admin_entry.label or "admin"
		end
		shared_helpers.validateArweaveAddress(admin_address)
		assert(not Admins[admin_address], "duplicate admin address")
		Admins[admin_address] = {
			address = admin_address,
			label = admin_label,
			active = true,
			joined = ts,
			last_activity = ts
		}
	end

	helpers.requireValidThreshold(threshold_raw)
	Threshold = tonumber(threshold_raw)

	if renounce_ownership ~= nil and renounce_ownership == "true" then
		helpers.renounceOwnership(msg)
	end

    Configured = true

	shared_helpers.addAuthority(ao.id)
	shared_helpers.addAuthority(constants.PUSH_NODE_AUTHORITY_ADDR)

	shared_helpers.respond(msg, {
		Action = "Configure-OK",
		OwnershipRenounced = OwnershipRenounced,
		Threshold = Threshold,
		AdminsCount = getters.getActiveAdminsCount(),
	})

	patch.emitAdminsPatch()
	patch.emitMuxPatch()
end


mod.addProposal = addProposal
mod.voteProposal = voteProposal
mod.tryExecuteProposal = tryExecuteProposal
mod.cancelProposal = cancelProposal
mod.configure = configure

return mod
