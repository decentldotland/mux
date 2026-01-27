require "shared.types"

global Nonce: number = Nonce or 0
global Threshold: number = Threshold or 1
global Variant: string = Variant or "0.1.2"
global Name: string = Name or "mux.ao-multisig"
global Configured: boolean = Configured or false
global OwnershipRenounced: boolean = OwnershipRenounced or false
global Deployer: string = Deployer or ""
global MuxLastActivity: string = MuxLastActivity or ""

global type Status = string

global record Admin
    address: string
    label: string | nil
    active: boolean
    joined: string
    last_activity: string
end

global record Decision
    admin: string
    approved: boolean
    voted: boolean
    timestamp: string
end

global record Proposal
    proposer: string
    id: string
    decisions: {Decision}
    target: string
    action: string
    data: string
    tags: {Tag} | nil
    status: Status
    nonce: number
    created_at: string
end

global record Resolution
    resolved: boolean
    result: boolean | nil
end

global record ExecutedEntry
    is_executed: boolean
    executed_at: string | nil
    outcome: Status
end

global Admins: {string: Admin} = Admins or {}
global Proposals: {string: Proposal} = Proposals or {}
-- proposal id -> ExecutedEntry
global Executed: {string: ExecutedEntry} = Executed or {}
