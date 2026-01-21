-- internal handlers that can be called by msg.Target == ao.id only

require "shared.types"
require "wallet.types"
local shared_helpers = require "shared.helpers"
local patch = require "wallet.patch"

local mod = {}

local function addAdmin(msg: Msg): nil
    assert(msg.From == ao.id, "internal handler, invalid caller")
    local new_admin = shared_helpers.tagOrField(msg, "AdminAddress")
    local admin_label = shared_helpers.tagOrField(msg, "AdminLabel") or "freshman"
    shared_helpers.validateArweaveAddress(new_admin)

    if Admins[new_admin] then
        -- admin exist but is disactivated 
        assert(not Admins[new_admin].active, "admin is active")
    else
        -- admin do not exist
        assert(not Admins[new_admin], "admin already exist")
    end

    local ts = msg.Timestamp

    local admin: Admin = {
        address = new_admin,
        label = admin_label,
        active = true,
        joined = ts,
        last_activity = ts
    }

    Admins[new_admin] = admin

	shared_helpers.respond(msg, {
		Action = "AddAdmin-OK"
	})

	patch.emitAdminsPatch()
	patch.emitMuxPatch(msg)
end

local function deactivateAdmin(msg: Msg): nil
    assert(msg.From == ao.id, "internal handler, invalid caller")
    local admin_address = shared_helpers.tagOrField(msg, "AdminAddress")
    shared_helpers.validateArweaveAddress(admin_address)

    assert(Admins[admin_address] and Admins[admin_address].active, "admin not found or already deactivated")

    local active_count = getters.getActiveAdminsCount()
    assert(Threshold <= active_count - 1, "threshold exceeds active admins")

    Admins[admin_address].active = false
    Admins[admin_address].last_activity = msg.Timestamp

	shared_helpers.respond(msg, {
		Action = "DeactivateAdmin-OK"
	})

	patch.emitAdminsPatch()
	patch.emitMuxPatch(msg)
end

local function addAuthorityFor(msg: Msg)
    assert(msg.From == ao.id, "internal handler, invalid caller")
    local external_process_id = shared_helpers.tagOrField(msg, "ExternalProcessId")
    shared_helpers.validateArweaveAddress(external_process_id)

    shared_helpers.addAuthority(external_process_id)

	shared_helpers.respond(msg, {
		Action = "Add-Authority-OK"
	})

	patch.emitActiveExternalAuthority()
end

local function removeAuthorityFor(msg: Msg)
    assert(msg.From == ao.id, "internal handler, invalid caller")
    local external_process_id = shared_helpers.tagOrField(msg, "ExternalProcessId")
    shared_helpers.validateArweaveAddress(external_process_id)

    shared_helpers.removeAuthority(external_process_id)

	shared_helpers.respond(msg, {
		Action = "Remove-Authority-OK"
	})

	patch.emitActiveExternalAuthority()
end

mod.addAdmin = addAdmin
mod.deactivateAdmin = deactivateAdmin
mod.addAuthorityFor = addAuthorityFor
mod.removeAuthorityFor = removeAuthorityFor

return mod