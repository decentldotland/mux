do
local _ENV = _ENV
package.preload[ "shared.deps" ] = function( ... ) local arg = _G.arg;
local mod = {}

local bint = require(".bint")(256)
local json = require("json")

mod.bint = bint
mod.json = json

return mod
end
end

do
local _ENV = _ENV
package.preload[ "shared.helpers" ] = function( ... ) local arg = _G.arg;
require("utils.types")

local deps = require("utils.deps")
local bint = deps.bint

local mod = {}

function mod.isOwner(sender)
   return sender == Owner
end

function mod.addAuthority(id)
   local a = ao.authorities or {}
   for _, v in ipairs(a) do
      if v == id then return end
   end
   table.insert(a, id)
   ao.authorities = a
   if SyncState then
      SyncState(nil)
   end
end

function mod.removeAuthority(id)
   local a = ao.authorities or {}
   for i = #a, 1, -1 do
      if a[i] == id then
         table.remove(a, i)
      end
   end
   ao.authorities = a
   if SyncState then SyncState(nil) end
end

function mod.respond(msg, payload)
   if msg.reply then
      msg.reply(payload)
   else
      payload.Target = msg.From
      Send(payload)
   end
end

function mod.getMsgId(msg)
   return msg.Id
end

function mod.findTagValue(tags, name)
   if not tags then
      return nil
   end
   local lower = string.lower(name)
   if tags[1] then
      for _, tag in ipairs(tags) do
         local tagName = tag.name or tag.Name
         if tagName and string.lower(tagName) == lower then
            return tag.value or tag.Value
         end
      end
   end
   if tags[name] ~= nil then
      return tags[name]
   end
   for k, v in pairs(tags) do
      if type(k) == "string" and string.lower(k) == lower then
         return v
      end
   end
   return nil
end

function mod.tagOrField(msg, name)
   local value = mod.findTagValue(msg.Tags, name) or findTagValue(msg.TagArray, name)
   if value ~= nil then
      return value
   end
   return msg[name]
end

function mod.validateArweaveAddress(address)
   assert(address ~= nil and address ~= "", "token address must be valid ao process id")
end

function mod.requirePositive(quantity, name)
   assert(quantity, name .. " is required")
   assert(bint.__lt(0, bint(quantity)), name .. " must be greater than 0")
end

return mod
end
end

do
local _ENV = _ENV
package.preload[ "shared.types" ] = function( ... ) local arg = _G.arg;
Payload = {}
ReplyFn = {}


Tag = {}






Msg = {}
end
end

do
local _ENV = _ENV
package.preload[ "wallet.codec" ] = function( ... ) local arg = _G.arg;
require("shared.types")
local deps = require("shared.deps")
local json = deps.json

local mod = {}

local function decodeProposalPayload(msg)
   local payload = msg.Data or ""
   local ok, decoded = pcall(json.decode, payload)
   assert(ok and type(decoded) == "table", "invalid proposal data payload")
   return decoded
end

mod.decodeProposalPayload = decodeProposalPayload

return mod
end
end

do
local _ENV = _ENV
package.preload[ "wallet.getters" ] = function( ... ) local arg = _G.arg;
require("shared.types")
require("wallet.types")

local mod = {}

local function getActiveAdmins()
   local admins_clone = {}
   for _, admin in pairs(Admins) do
      if admin.active then
         table.insert(admins_clone, admin)
      end
   end

   return admins_clone
end

local function getActiveAdminsCount()
   local actives_count = 0

   for _, admin in pairs(Admins) do
      if admin.active then
         actives_count = actives_count + 1
      end
   end

   return actives_count
end


mod.getActiveAdmins = getActiveAdmins
mod.getActiveAdminsCount = getActiveAdminsCount

return mod
end
end

do
local _ENV = _ENV
package.preload[ "wallet.handlers" ] = function( ... ) local arg = _G.arg;
require("shared.types")
require("wallet.types")
local shared_helpers = require("shared.helpers")
local helpers = require("wallet.helpers")
local codec = require("wallet.codec")
local deps = require("shared.deps")
local patch = require("wallet.patch")

local mod = {}


local function addProposal(msg)
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

   local proposer_decision = { admin = msg.From, approved = true }
   local proposal_status = "Pending"
   local proposal_nonce = Nonce
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
      created_at = msg.Timestamp or "",
   }

   helpers.updateAdminLastActivity(msg, Admins[msg.From])

   shared_helpers.respond(msg, {
      Action = "Propose-OK",
      ProposalId = proposal_id,
      Status = proposal_status,
   })

   patch.emitPendingPatch()
   patch.emitMuxPatch()
end
local function voteProposal(msg)
   helpers.requireActiveAdmin(msg.From)
   local proposal_id = shared_helpers.tagOrField(msg, "ProposalId")
   local decision_tag = shared_helpers.tagOrField(msg, "Decision")
   local proposal_decision = decision_tag == "true"
   assert(proposal_id and proposal_id ~= "", "proposal id missing")
   assert(Proposals[proposal_id] and Proposals[proposal_id].status == "Pending", "proposal do not exist")
   assert(not Executed[proposal_id], "proposal aleady executed")
   helpers.checkDoubleVoting(msg.From, Proposals[proposal_id])

   local decision = {
      admin = msg.From,
      approved = proposal_decision,
      voted = true,
      timestamp = msg.Timestamp or "",
   }

   table.insert(Proposals[proposal_id].decisions, decision)
   helpers.updateAdminLastActivity(msg, Admins[msg.From])

   shared_helpers.respond(msg, {
      Target = msg.From,
      Action = "Vote-OK",
      Decision = proposal_decision,
   })

   patch.emitPendingPatch()
end

local function cancelProposal(msg)
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
      Action = "Cancel-Proposal-OK",
   })

   patch.emitCancelledPatch()
   patch.emitExecutedPatch()
   patch.emitPendingPatch()
end

local function tryExecuteProposal(msg)
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
      Status = proposal.status,
   })
end

local function configure(msg)
   assert(not Configured, "wallet already configured")
   assert(shared_helpers.isOwner(msg.From), "unauthed caller")
   local name = shared_helpers.tagOrField(msg, "Name")
   local renounce_ownership = shared_helpers.tagOrField(msg, "RenounceOwnership")

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
         last_activity = ts,
      }
   end

   helpers.requireValidThreshold(threshold_raw)
   Threshold = tonumber(threshold_raw)

   if renounce_ownership ~= nil and renounce_ownership == "true" then
      helpers.renounceOwnership(msg)
   end

   Configured = true

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
end
end

do
local _ENV = _ENV
package.preload[ "wallet.helpers" ] = function( ... ) local arg = _G.arg;
require("shared.types")
require("wallet.types")
local shared_helpers = require("shared.helpers")
local getters = require("wallet.getters")

local mod = {}

local function isActiveAdmin(address)
   return (Admins[address] and Admins[address].active)
end

local function requireActiveAdmin(address)
   assert(isActiveAdmin(address), "active not found or removed")
end

local function requireConfiguredWallet()
   assert(Configured, "smart wallet not configured yet")
end

local function updateAdminLastActivity(msg, admin)
   admin.last_activity = msg.Timestamp or ""
end

local function requireValidThreshold(threshold)
   shared_helpers.requirePositive(threshold, "new smart wallet threshold value")
   assert(tonumber(threshold) <= getters.getActiveAdminsCount(), "threshold exceeds active admins")
end

local function checkDoubleVoting(voter, proposal)
   for _, d in pairs(proposal.decisions) do
      assert(d.admin ~= voter, "admin already voted on this proposal")
   end
end


local function doesMeetThreshold(proposal)
   local yay_count = 0
   local nay_count = 0

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

local function renounceOwnership(msg)
   if Owner ~= nil then
      assert(shared_helpers.isOwner(msg.From), "unauthed caller")
      Owner = nil
      shared_helpers.respond(msg, {
         Action = "RenounceOwnership-OK",
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
end
end

do
local _ENV = _ENV
package.preload[ "wallet.internal" ] = function( ... ) local arg = _G.arg;


require("shared.types")
require("wallet.types")
local shared_helpers = require("shared.helpers")
local patch = require("wallet.patch")

local mod = {}

local function addAdmin(msg)
   assert(msg.From == ao.id, "internal handler, invalid caller")
   local new_admin = shared_helpers.tagOrField(msg, "AdminAddress")
   local admin_label = shared_helpers.tagOrField(msg, "AdminLabel") or "freshman"
   shared_helpers.validateArweaveAddress(new_admin)

   if Admins[new_admin] then

      assert(not Admins[new_admin].active, "admin is active")
   else

      assert(not Admins[new_admin], "admin already exist")
   end

   local ts = msg.Timestamp

   local admin = {
      address = new_admin,
      label = admin_label,
      active = true,
      joined = ts,
      last_activity = ts,
   }

   Admins[new_admin] = admin

   shared_helpers.respond(msg, {
      Action = "AddAdmin-OK",
   })

   patch.emitAdminsPatch()
   patch.emitMuxPatch()
end

local function deactivateAdmin(msg)
   assert(msg.From == ao.id, "internal handler, invalid caller")
   local admin_address = shared_helpers.tagOrField(msg, "AdminAddress")
   shared_helpers.validateArweaveAddress(admin_address)

   assert(Admins[admin_address] and Admins[admin_address].active, "admin not found or already deactivated")

   Admins[admin_address].active = false
   Admins[admin_address].last_activity = msg.Timestamp

   shared_helpers.respond(msg, {
      Action = "DeactivateAdmin-OK",
   })

   patch.emitAdminsPatch()
   patch.emitMuxPatch()
end

local function addAuthorityFor(msg)
   assert(msg.From == ao.id, "internal handler, invalid caller")
   local external_process_id = shared_helpers.tagOrField(msg, "ExternalProcessId")
   shared_helpers.validateArweaveAddress(external_process_id)

   shared_helpers.addAuthority(external_process_id)

   shared_helpers.respond(msg, {
      Action = "Add-Authority-OK",
   })

   patch.emitActiveExternalAuthority()
end

local function removeAuthorityFor(msg)
   assert(msg.From == ao.id, "internal handler, invalid caller")
   local external_process_id = shared_helpers.tagOrField(msg, "ExternalProcessId")
   shared_helpers.validateArweaveAddress(external_process_id)

   shared_helpers.removeAuthority(external_process_id)

   shared_helpers.respond(msg, {
      Action = "Remove-Authority-OK",
   })

   patch.emitActiveExternalAuthority()
end

mod.addAdmin = addAdmin
mod.deactivateAdmin = deactivateAdmin
mod.addAuthorityFor = addAuthorityFor
mod.removeAuthorityFor = removeAuthorityFor

return mod
end
end

do
local _ENV = _ENV
package.preload[ "wallet.main" ] = function( ... ) local arg = _G.arg;
require("shared.types")
require("wallet.types")

local handlers = require("wallet.handlers")
local internal = require("wallet.internal")
local helpers = require("wallet.helpers")



Handlers.add(
"wallet.configure",
Handlers.utils.hasMatchingTag("Action", "Configure"),
handlers.configure)


Handlers.add(
"wallet.propose",
Handlers.utils.hasMatchingTag("Action", "Propose"),
handlers.addProposal)


Handlers.add(
"wallet.vote",
Handlers.utils.hasMatchingTag("Action", "Vote"),
handlers.voteProposal)


Handlers.add(
"wallet.execute",
Handlers.utils.hasMatchingTag("Action", "Execute"),
handlers.tryExecuteProposal)


Handlers.add(
"wallet.cancel",
Handlers.utils.hasMatchingTag("Action", "Cancel"),
handlers.cancelProposal)



Handlers.add(
"wallet.renounce",
Handlers.utils.hasMatchingTag("Action", "RenounceOwnership"),
helpers.renounceOwnership)



Handlers.add(
"wallet.add_admin",
Handlers.utils.hasMatchingTag("Action", "AddAdmin"),
internal.addAdmin)


Handlers.add(
"wallet.deactivate_admin",
Handlers.utils.hasMatchingTag("Action", "DeactivateAdmin"),
internal.deactivateAdmin)


Handlers.add(
"wallet.add_authority",
Handlers.utils.hasMatchingTag("Action", "AddAuthorityFor"),
internal.addAuthorityFor)


Handlers.add(
"wallet.remove_authority",
Handlers.utils.hasMatchingTag("Action", "RemoveAuthorityFor"),
internal.removeAuthorityFor)
end
end

do
local _ENV = _ENV
package.preload[ "wallet.patch" ] = function( ... ) local arg = _G.arg;
require("shared.types")
require("wallet.types")
local shared_helpers = require("shared.helpers")
local getters = require("wallet.getters")

local mod = {}

local function emitAdminsPatch()
   Send({
      device = "patch@1.0",
      ["admins-patch"] = Admins,
   })
end

local function emitFullProposalsPatch()
   Send({
      device = "patch@1.0",
      ["full-proposals-patch"] = Proposals,
   })
end

local function emitPendingPatch()

   local pendings = {}

   for _, proposal in pairs(Proposals) do
      if proposal.status == "Pending" then
         table.insert(pendings, proposal)
      end
   end

   Send({
      device = "patch@1.0",
      ["pending-proposals-patch"] = pendings,
   })
end

local function emitCancelledPatch()

   local pendings = {}

   for _, proposal in pairs(Proposals) do
      if proposal.status == "Cancelled" then
         table.insert(pendings, proposal)
      end
   end

   Send({
      device = "patch@1.0",
      ["cancelled-proposals-patch"] = pendings,
   })
end

local function emitRejectedPatch()

   local pendings = {}

   for _, proposal in pairs(Proposals) do
      if proposal.status == "Rejected" then
         table.insert(pendings, proposal)
      end
   end

   Send({
      device = "patch@1.0",
      ["rejected-proposals-patch"] = pendings,
   })
end

local function emitExecutedPatch()
   Send({
      device = "patch@1.0",
      ["executed-patch"] = Executed,
   })
end

local function emitMuxPatch()
   Send({
      device = "patch@1.0",
      ["mux-state"] = {
         Threshold = Threshold,
         Nonce = Nonce,
         Name = Name,
         Variant = Variant,
         Configured = Configured,
         OwnershipRenounced = OwnershipRenounced,
      },
   })
end

local function emitActiveExternalAuthority()
   local authorities = ao.authorities or {}

   Send({
      device = "patch@1.0",
      ["active-external-authorities"] = authorities,
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
end
end

do
local _ENV = _ENV
package.preload[ "wallet.types" ] = function( ... ) local arg = _G.arg;
require("shared.types")

Nonce = Nonce or 0
Threshold = Threshold or 1
Variant = Variant or "0.1.0"
Name = Name or "mux.ao-multisig"
Configured = Configured or false
OwnershipRenounced = OwnershipRenounced or false

Status = {}

Admin = {}







Decision = {}






Proposal = {}












Resolution = {}




Admins = Admins or {}
Proposals = Proposals or {}

Executed = Executed or {}
end
end

require("shared.types")
require("wallet.types")

local handlers = require("wallet.handlers")
local internal = require("wallet.internal")
local helpers = require("wallet.helpers")



Handlers.add(
"wallet.configure",
Handlers.utils.hasMatchingTag("Action", "Configure"),
handlers.configure)


Handlers.add(
"wallet.propose",
Handlers.utils.hasMatchingTag("Action", "Propose"),
handlers.addProposal)


Handlers.add(
"wallet.vote",
Handlers.utils.hasMatchingTag("Action", "Vote"),
handlers.voteProposal)


Handlers.add(
"wallet.execute",
Handlers.utils.hasMatchingTag("Action", "Execute"),
handlers.tryExecuteProposal)


Handlers.add(
"wallet.cancel",
Handlers.utils.hasMatchingTag("Action", "Cancel"),
handlers.cancelProposal)



Handlers.add(
"wallet.renounce",
Handlers.utils.hasMatchingTag("Action", "RenounceOwnership"),
helpers.renounceOwnership)



Handlers.add(
"wallet.add_admin",
Handlers.utils.hasMatchingTag("Action", "AddAdmin"),
internal.addAdmin)


Handlers.add(
"wallet.deactivate_admin",
Handlers.utils.hasMatchingTag("Action", "DeactivateAdmin"),
internal.deactivateAdmin)


Handlers.add(
"wallet.add_authority",
Handlers.utils.hasMatchingTag("Action", "AddAuthorityFor"),
internal.addAuthorityFor)


Handlers.add(
"wallet.remove_authority",
Handlers.utils.hasMatchingTag("Action", "RemoveAuthorityFor"),
internal.removeAuthorityFor)
