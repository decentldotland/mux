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
   elseif resolution ~= nil and not resolution then
      Executed[proposal_id] = true
      proposal.status = "Rejected"
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
   local admin_label = shared_helpers.tagOrField(msg, "AdminLabel") or "notthatguy"
   local admin = {
      address = msg.From,
      label = admin_label,
      active = true,
      joined = msg.Timestamp,
      last_activity = msg.Timestamp,
   }

   if name ~= nil and name ~= "" then
      Name = name
   end

   Admins[msg.From] = admin
   Configured = true

   shared_helpers.respond(msg, {
      Action = "Configure-OK",
   })

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


mod.isActiveAdmin = isActiveAdmin
mod.requireActiveAdmin = requireActiveAdmin
mod.requireConfiguredWallet = requireConfiguredWallet
mod.requireValidThreshold = requireValidThreshold
mod.checkDoubleVoting = checkDoubleVoting
mod.doesMeetThreshold = doesMeetThreshold
mod.updateAdminLastActivity = updateAdminLastActivity

return mod
end
end

do
local _ENV = _ENV
package.preload[ "wallet.internal" ] = function( ... ) local arg = _G.arg;


require("shared.types")
require("wallet.types")
local shared_helpers = require("shared.helpers")

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
end

local function addAuthorityFor(msg)
   assert(msg.From == ao.id, "internal handler, invalid caller")
   local external_process_id = shared_helpers.tagOrField(msg, "ExternalProcessId")
   shared_helpers.validateArweaveAddress(external_process_id)

   shared_helpers.addAuthority(external_process_id)

   shared_helpers.respond(msg, {
      Action = "Add-Authority-OK",
   })
end

local function removeAuthorityFor(msg)
   assert(msg.From == ao.id, "internal handler, invalid caller")
   local external_process_id = shared_helpers.tagOrField(msg, "ExternalProcessId")
   shared_helpers.validateArweaveAddress(external_process_id)

   shared_helpers.removeAuthority(external_process_id)

   shared_helpers.respond(msg, {
      Action = "Remove-Authority-OK",
   })
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


