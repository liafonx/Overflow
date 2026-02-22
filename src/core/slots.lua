local function in_multiplayer_lobby()
    return type(MP) == 'table'
        and type(MP.LOBBY) == 'table'
        and MP.LOBBY.code
end

Overflow.in_multiplayer_lobby = in_multiplayer_lobby

function Overflow.should_enforce_consumeable_slots()
    return Overflow.config.fix_slots or in_multiplayer_lobby()
end

function Overflow.get_consumeable_limit(card)
    if not G or not G.consumeables or not G.consumeables.config then
        return 0
    end

    local limit = G.consumeables.config.card_limit
    if card and card.ability then
        local ability = card.ability
        local extra_limit = ability.card_limit or ((card.edition and card.edition.negative) and 1 or 0)
        limit = limit + (extra_limit or 0) - (ability.extra_slots_used or 0)
    end
    return limit
end

local function get_card_slot_cost(card, qty_override, enforce_slots)
    if not card then
        return 0
    end

    if enforce_slots == nil then
        enforce_slots = Overflow.should_enforce_consumeable_slots()
    end

    if not enforce_slots then
        return 1
    end

    if card.edition and card.edition.card_limit then
        return 1
    end

    local qty = qty_override
    if qty == nil then
        qty = card.qty or 1
    end

    if to_big(qty or 0) <= to_big(0) then
        return 0
    end

    if to_big(qty) >= to_big(1e100) then
        return 1e100
    end

    return to_number(qty)
end

local function compute_consumeable_count()
    local enforce_slots = Overflow.should_enforce_consumeable_slots()
    local total = 0
    if enforce_slots then
        for _, v in ipairs(G.consumeables.cards) do
            total = to_big(total) + to_big(get_card_slot_cost(v, nil, enforce_slots))
        end
    else
        total = #G.consumeables.cards
    end
    return total
end

function Overflow.get_consumeable_count(include_buffer, force_recalc)
    if not G or not G.consumeables or not G.consumeables.cards then
        return 0
    end

    local enforce_slots = Overflow.should_enforce_consumeable_slots()
    local total = compute_consumeable_count()
    if enforce_slots and G.consumeables.config then
        G.consumeables.config.card_count = to_number(total)
    end

    if enforce_slots and G and G.GAME then
        total = to_big(total) + to_big(G.GAME.overflow_pending_consumeable_slots or 0)
    end

    if include_buffer then
        total = to_big(total) + to_big((G.GAME and G.GAME.consumeable_buffer) or 0)
    end

    if to_big(total) >= to_big(1e100) then
        return 1e100
    end
    return to_number(total)
end

function Overflow.add_pending_consumeable_slots(delta)
    if not (G and G.GAME) then
        return
    end

    local next_value = to_big(G.GAME.overflow_pending_consumeable_slots or 0) + to_big(delta or 0)
    if to_big(next_value) <= to_big(0) then
        G.GAME.overflow_pending_consumeable_slots = nil
        return
    end

    if to_big(next_value) >= to_big(1e100) then
        G.GAME.overflow_pending_consumeable_slots = 1e100
        return
    end

    G.GAME.overflow_pending_consumeable_slots = to_number(next_value)
end

function Overflow.get_consumeable_slots_remaining(card, include_buffer)
    local limit = Overflow.get_consumeable_limit(card)
    local used = Overflow.get_consumeable_count(include_buffer)
    local remaining = to_big(limit) - to_big(used)
    if to_big(remaining) <= to_big(0) then
        return 0
    end
    if to_big(remaining) >= to_big(1e100) then
        return 1e100
    end
    return math.floor(to_number(remaining))
end

function Overflow.has_consumeable_space(card, include_buffer)
    return to_big(Overflow.get_consumeable_count(include_buffer)) < to_big(Overflow.get_consumeable_limit(card))
end

function Overflow.can_accept_consumeable(card, incoming_qty, merge_target, include_buffer, used_count)
    if not Overflow.should_enforce_consumeable_slots() then
        return true
    end

    local used = used_count
    if used == nil then
        used = Overflow.get_consumeable_count(include_buffer)
    end
    local limit = Overflow.get_consumeable_limit(card)
    local incoming = incoming_qty or (card and card.qty) or 1

    local delta = 0
    if merge_target then
        local before = get_card_slot_cost(merge_target, nil, true)
        local after = get_card_slot_cost(merge_target, to_big(merge_target.qty or 1) + to_big(incoming), true)
        delta = to_big(after) - to_big(before)
    else
        delta = get_card_slot_cost(card, incoming, true)
    end

    return to_big(used) + to_big(delta) <= to_big(limit)
end

function Overflow.sync_consumeable_card_count()
    if G and G.consumeables and G.consumeables.config then
        G.consumeables.config.card_count = Overflow.get_consumeable_count(false, true)
    end
end
