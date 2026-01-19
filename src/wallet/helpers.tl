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

local function requireValidThreshold(threshold: string): nil
    shared_helpers.requirePositive(threshold, "new smart wallet threshold value")
    assert(tonumber(threshold) <= getters.getActiveAdminsCount(), "threshold exceeds active admins")
end


mod.isActiveAdmin = isActiveAdmin
mod.requireActiveAdmin = requireActiveAdmin
mod.requireConfiguredWallet = requireConfiguredWallet
mod.requireValidThreshold = requireValidThreshold

return mod