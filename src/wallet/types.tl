require "shared.types"

global Nonce: number = Nonce or 0
global Threshold: number = Threshold or 1
global Variant: string = Variant or "0.1.0"
global Name: string = Name or "treasury.ao-multisig"
global Configured: boolean = Configured or false

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
end

global record Proposal
    proposer: string
    id: string
    decisions: {Decision} | {}
    target: string
    data: string
    tags: {Tag} | nil
    status: Status
end


global Admins: {string: Admin} = Admins or {}
global Proposals: {string: Proposal} = Proposals or {}
-- proposal id -> executed bool
global Executed: {string: boolean} = Executed or {}

