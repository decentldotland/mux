require "shared.types"
require "wallet.types"

local handlers = require "wallet.handlers"
local internal = require "wallet.internal"
local helpers = require "wallet.helpers"

-- external handlers

Handlers.add(
  "wallet.configure",
  Handlers.utils.hasMatchingTag("Action", "Configure"),
  handlers.configure
)

Handlers.add(
  "wallet.propose",
  Handlers.utils.hasMatchingTag("Action", "Propose"),
  handlers.addProposal
)

Handlers.add(
  "wallet.vote",
  Handlers.utils.hasMatchingTag("Action", "Vote"),
  handlers.voteProposal
)

Handlers.add(
  "wallet.execute",
  Handlers.utils.hasMatchingTag("Action", "Execute"),
  handlers.tryExecuteProposal
)

Handlers.add(
  "wallet.cancel",
  Handlers.utils.hasMatchingTag("Action", "Cancel"),
  handlers.cancelProposal
)

-- internal handler (msg.From == Owner)
Handlers.add(
  "wallet.renounce",
  Handlers.utils.hasMatchingTag("Action", "RenounceOwnership"),
  helpers.renounceOwnership
)

-- internal handlers (msg.From == ao.id)
Handlers.add(
  "wallet.add_admin",
  Handlers.utils.hasMatchingTag("Action", "AddAdmin"),
  internal.addAdmin
)

Handlers.add(
  "wallet.deactivate_admin",
  Handlers.utils.hasMatchingTag("Action", "DeactivateAdmin"),
  internal.deactivateAdmin
)

Handlers.add(
  "wallet.add_authority",
  Handlers.utils.hasMatchingTag("Action", "AddAuthorityFor"),
  internal.addAuthorityFor
)

Handlers.add(
  "wallet.remove_authority",
  Handlers.utils.hasMatchingTag("Action", "RemoveAuthorityFor"),
  internal.removeAuthorityFor
)
