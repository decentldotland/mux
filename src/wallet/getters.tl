require "shared.types"
require "wallet.types"

local mod = {}

local function getActiveAdmins(): {Admin}
	local admins_clone: {Admin} = {}
	for _, admin in pairs(Admins) do
		if admin.active then
			table.insert(admins_clone, admin)
		end
	end

	return admins_clone
end

local function getActiveAdminsCount(): number
    local actives_count: number = 0

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
