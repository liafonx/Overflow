local use_card_ref = G.FUNCS.use_card
G.FUNCS.use_card = function(e, mute, nosave, ...)
    local card = e.config.ref_table
    local mod = G.GAME.modifiers.entr_twisted
    G.GAME.modifiers.entr_twisted = nil

    if card.children then
        card:remove_overflow_ui()
    end

    if not card.ability.cry_multiuse or to_big(card.ability.cry_multiuse) <= to_big(1) then
        if card.qty and to_big(card.qty) > to_big(1) and card.area == G.consumeables then
            local new_card = copy_card(card)
            local amount = card.qty
            local remaining = to_big(amount) - to_big(1)
            local use_pending_slots = Overflow.should_enforce_consumeable_slots() and to_big(remaining) > to_big(0)

            if use_pending_slots then
                Overflow.add_pending_consumeable_slots(remaining)
                Overflow.sync_consumeable_card_count()
            end

            card.ability.bypass_aleph = true
            G.GAME.modifiers.entr_twisted = mod
            use_card_ref(e, mute, nosave, ...)

            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.3,
                func = function()
                    if use_pending_slots then
                        Overflow.add_pending_consumeable_slots(-remaining)
                    end
                    new_card:add_to_deck()
                    G.consumeables:emplace(new_card)
                    new_card.bypass = true
                    Overflow.set_amount(new_card, remaining, true)
                    new_card.bypass = nil
                    if use_pending_slots then
                        Overflow.sync_consumeable_card_count()
                    end
                    return true
                end,
            }))
        else
            local amount = card.qty
            card.ability.bypass_aleph = true
            G.GAME.modifiers.entr_twisted = mod
            use_card_ref(e, mute, nosave, ...)

            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.3,
                func = function()
                    Overflow.set_amount(card, to_big(amount or 1) - to_big(1))
                    G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        delay = 0.3,
                        func = function()
                            if to_big(card.qty or 0) > to_big(0) then
                                card:create_overflow_ui()
                            end
                            return true
                        end,
                    }))
                    return true
                end,
            }))
        end
    else
        local amount = card.qty
        card.ability.bypass_aleph = true
        G.GAME.modifiers.entr_twisted = mod
        use_card_ref(e, mute, nosave, ...)

        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.3,
            func = function()
                Overflow.set_amount(card, to_big(amount or 1) - to_big(1))
                if to_big(card.qty or 0) > to_big(0) then
                    card:create_overflow_ui()
                end
                return true
            end,
        }))
    end
end

local check_for_buy_space_ref = G.FUNCS.check_for_buy_space
G.FUNCS.check_for_buy_space = function(card)
    if card and card.ability and card.ability.consumeable and Overflow.should_enforce_consumeable_slots() then
        local merge_target = Overflow.can_merge(card, nil, nil, true)
        if not Overflow.can_accept_consumeable(card, card.qty or 1, merge_target, false) then
            alert_no_space(card, G.consumeables)
            return false
        end
        return true
    end

    return check_for_buy_space_ref(card)
end

local can_use_consumeable_ref = Card.can_use_consumeable
function Card:can_use_consumeable(any_state, skip_check)
    local can_use = can_use_consumeable_ref(self, any_state, skip_check)
    if not can_use then
        return false
    end

    if not Overflow.should_enforce_consumeable_slots() then
        return can_use
    end

    if self.ability and (
        self.ability.name == 'The Emperor'
        or self.ability.name == 'The High Priestess'
        or self.ability.name == 'The Fool'
    ) then
        if self.area ~= G.consumeables and not Overflow.has_consumeable_space(nil, false) then
            return false
        end
    end

    return can_use
end
