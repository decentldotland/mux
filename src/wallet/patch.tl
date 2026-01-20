require "shared.types"
require "wallet.types"
local shared_helpers = require "shared.helpers"
local getters = require "wallet.getters"

local mod = {}

local function emitAdminsPatch(): nil
    Send({
        device = "patch@1.0",
        ["admins-patch"] = Admins
    })
end

local function emitFullProposalsPatch(): nil
    Send({
        device = "patch@1.0",
        ["full-proposals-patch"] = Proposals
    })
end

local function emitPendingPatch(): nil

    local pendings: {Proposal} = {}

    for _, proposal in pairs(Proposals) do
        if proposal.status == "Pending" then
            table.insert(pendings, proposal)
        end
    end

    Send({
        device = "patch@1.0",
        ["pending-proposals-patch"] = pendings
    })
end

local function emitCancelledPatch(): nil

    local pendings: {Proposal} = {}

    for _, proposal in pairs(Proposals) do
        if proposal.status == "Cancelled" then
            table.insert(pendings, proposal)
        end
    end

    Send({
        device = "patch@1.0",
        ["cancelled-proposals-patch"] = pendings
    })
end

local function emitRejectedPatch(): nil

    local pendings: {Proposal} = {}

    for _, proposal in pairs(Proposals) do
        if proposal.status == "Rejected" then
            table.insert(pendings, proposal)
        end
    end

    Send({
        device = "patch@1.0",
        ["rejected-proposals-patch"] = pendings
    })
end

local function emitExecutedPatch(): nil
    Send({
        device = "patch@1.0",
        ["executed-proposals-patch"] = Executed
    })
end

local function emitMuxPatch(): nil
    Send({
        device = "patch@1.0",
        ["mux-state"] = {
            Threshold = Threshold,
            Nonce = Nonce,
            Name = Name,
            Variant = Variant,
            Configured = Configured,
            OwnershipRenounced = OwnershipRenounced
        }
    })
end

local function emitActiveExternalAuthority(): nil
    local authorities = ao.authorities or {}

    Send({
        device = "patch@1.0",
        ["active-external-authorities"] = authorities
    })
end


mod.emitAdminsPatch = emitAdminsPatch
mod.emitFullProposalsPatch = emitFullProposalsPatch
mod.emitPendingPatch = emitPendingPatch
mod.emitExecutedPatch = emitExecutedPatch
mod.emitCancelledPatch = emitCancelledPatch
mod.emitMuxPatch = emitMuxPatch
mod.emitActiveExternalAuthority = emitActiveExternalAuthority
mod.emitRejectedPatch = emitRejectedPatch

return mod
