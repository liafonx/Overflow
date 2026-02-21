local emplace_ref = CardArea.emplace

local function dissolve_incoming_card(card)
    card.states.visible = false
    card.ability.bypass_aleph = true
    card:start_dissolve()
end

function CardArea:emplace(card, ...)
    if self ~= G.consumeables
        or not G.consumeables
        or card.config.center.set == 'Joker'
        or card.ability.split
        or Overflow.is_blacklisted(card)
    then
        emplace_ref(self, card, ...)
        if card.children and card.children.overflow_ui then
            card.children.overflow_ui:remove()
            card.children.overflow_ui = nil
        end
        return
    end

    local incoming_qty = card.qty or 1
    local merge_target = Overflow.can_merge(card, nil, nil, true)

    if merge_target then
        if Overflow.should_enforce_consumeable_slots()
            and not Overflow.can_accept_consumeable(card, incoming_qty, merge_target, false)
        then
            dissolve_incoming_card(card)
            Overflow.sync_consumeable_card_count()
            return
        end

        Overflow.set_amount(merge_target, to_big(merge_target.qty or 1) + to_big(incoming_qty), true)
        dissolve_incoming_card(card)
        Overflow.sync_consumeable_card_count()
        return
    end

    if Overflow.should_enforce_consumeable_slots()
        and not Overflow.can_accept_consumeable(card, incoming_qty, nil, false)
    then
        dissolve_incoming_card(card)
        Overflow.sync_consumeable_card_count()
        return
    end

    emplace_ref(self, card, ...)
    Overflow.sync_consumeable_card_count()
end

local handle_card_limit_ref = CardArea.handle_card_limit
if handle_card_limit_ref then
    function CardArea:handle_card_limit(...)
        local ret = handle_card_limit_ref(self, ...)
        if self == G.consumeables then
            self.config.card_count = Overflow.get_consumeable_count(false)
        end
        return ret
    end
end
