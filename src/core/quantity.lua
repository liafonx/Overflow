function Overflow.set_amount(card, amount, no_anims)
    if not card then
        return
    end

    local normalized = amount
    if to_big(normalized or 0) < to_big(1e100) then
        normalized = to_number(normalized)
    end

    if not normalized or to_big(normalized or 0) <= to_big(1) then
        card.qty = nil
        card.qty_text = nil
    else
        card.qty = normalized
        if to_big(card.qty) < to_big(1e100) then
            card.qty = to_number(card.qty)
        end
        card.qty_text = number_format(card.qty)
    end

    card:set_cost()
    if card.area == G.consumeables then
        Overflow.sync_consumeable_card_count()
    end

    card:create_overflow_ui()

    if not no_anims then
        G.E_MANAGER:add_event(Event({
            func = function()
                card.qty_used = nil
                return true
            end,
        }))
    else
        card.qty_used = nil
    end
end

function Overflow.weighted_random(pool, pseudoseed)
    local poolsize = 0
    for _, v in pairs(pool) do
        poolsize = poolsize + to_number(v[1]) * 1000
    end

    local selection = pseudorandom(pseudoseed) * (poolsize - 1) + 1
    for _, v in pairs(pool) do
        selection = selection - v[1] * 1000
        if to_big(selection) <= to_big(0) then
            return v[2]
        end
    end

    return pool[1][2]
end

function CardArea:get_total_count()
    local total = 0
    for _, v in ipairs(self.cards) do
        total = total + (v and (v.qty or 1) or 1)
    end
    return total
end
