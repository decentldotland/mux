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
package.preload[ "wallet.main" ] = function( ... ) local arg = _G.arg;

end
end


