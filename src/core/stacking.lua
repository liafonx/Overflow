function Overflow.TableMatches(tbl, func)
    for i, v in ipairs(tbl or {}) do
        if func(v, i) then
            return v, i
        end
    end
end

function Overflow.is_blacklisted(card)
    if not card then
        return false
    end
    return Overflow.blacklist[card.config.center.key]
        or Overflow.blacklist[card.config.center.set]
        or (card.playing_card and card.base and card.base.suit)
end

local function normalize_edition_key(card)
    local edition = card and card.edition
    if not edition then
        return 'e_base'
    end

    if edition.key and edition.key ~= '' then
        return string.sub(edition.key, 1, 2) == 'e_' and edition.key or ('e_' .. edition.key)
    end

    if edition.type and edition.type ~= '' then
        return string.sub(edition.type, 1, 2) == 'e_' and edition.type or ('e_' .. edition.type)
    end

    if edition.negative then return 'e_negative' end
    if edition.polychrome then return 'e_polychrome' end
    if edition.holo then return 'e_holo' end
    if edition.foil then return 'e_foil' end

    return 'e_base'
end

local function same_edition(a, b)
    return normalize_edition_key(a) == normalize_edition_key(b)
end

local function get_unit_sell_value(card)
    if not card then return nil end
    if card.sell_cost == nil and card.set_cost then
        pcall(function() card:set_cost() end)
    end
    if card.sell_cost == nil then
        return nil
    end

    local qty = to_big(card.qty or 1)
    if to_big(qty) <= to_big(0) then qty = 1 end
    return to_big(card.sell_cost or 0) / qty
end

local function same_sell_value(a, b)
    local a_val = get_unit_sell_value(a)
    local b_val = get_unit_sell_value(b)
    if a_val == nil or b_val == nil then
        return true
    end
    return not (to_big(a_val) > to_big(b_val) or to_big(a_val) < to_big(b_val))
end

local function is_negative(card)
    return normalize_edition_key(card) == 'e_negative'
end

function Overflow.is_negative_edition(card)
    return is_negative(card)
end

local function cards_can_stack(a, b, bypass, ignore_area)
    if not a or not b then return false end
    if a == b and not bypass then return false end

    if a:isInfinite() or b:isInfinite() then return false end
    if Overflow.is_card_dissolving(a) or Overflow.is_card_dissolving(b) then return false end
    if Overflow.is_blacklisted(a) or Overflow.is_blacklisted(b) then return false end

    if not ignore_area and (a.area ~= G.consumeables or b.area ~= G.consumeables) then
        return false
    end

    if a.config.center.set == "Joker" or b.config.center.set == "Joker" then
        return false
    end
    if a.config.center.key ~= b.config.center.key then
        return false
    end

    if Overflow.config.only_stack_negatives or (Overflow.in_multiplayer_lobby and Overflow.in_multiplayer_lobby()) then
        if not is_negative(a) or not is_negative(b) then
            return false
        end
    end

    if not same_edition(a, b) then
        return false
    end

    if Overflow.config.require_sellvalue and not same_sell_value(a, b) then
        return false
    end

    return true
end

local function resolve_merge_area(card, ignore_area)
    local area = G and G.consumeables
    if not area and ignore_area and card and card.area and card.area.cards then
        area = card.area
    end
    return area
end

function Overflow.scan_merge_targets(card, bypass, ignore_area)
    if not card then
        return nil, 0
    end

    local area = resolve_merge_area(card, ignore_area)
    if not area or not area.cards then
        return nil, 0
    end

    local first, count = nil, 0
    for _, v in ipairs(area.cards) do
        if cards_can_stack(v, card, bypass, ignore_area) then
            count = count + 1
            if not first then
                first = v
            end
        end
    end

    return first, count
end

function Overflow.can_merge(self, card, bypass, ignore_area)
    if not self then
        return false
    end

    if card then
        return cards_can_stack(self, card, bypass, ignore_area)
    end

    return Overflow.scan_merge_targets(self, bypass, ignore_area)
end

function Overflow.can_mass_use(set, area)
    if not area then return nil end
    if area == G.pack_cards or area == G.shop_jokers or area == G.shop_booster or area == G.shop_vouchers then
        return nil
    end

    local cards = area.cards or area
    local total = 0
    for _, v in pairs(cards) do
        if v.config.center.set == set and not v.config.center.ignore_allplanets then
            total = total + 1
        end
    end
    return total > 1 and total or nil
end

function Overflow.has_mass_use(set, area)
    if not area then return false end
    if area == G.pack_cards or area == G.shop_jokers or area == G.shop_booster or area == G.shop_vouchers then
        return false
    end

    local cards = area.cards or area
    local total = 0
    for _, v in pairs(cards) do
        if v.config.center.set == set and not v.config.center.ignore_allplanets then
            total = total + 1
            if total > 1 then
                return true
            end
        end
    end
    return false
end

function Overflow.unstack_non_negative_consumeables()
    if not (G and G.consumeables and G.consumeables.cards) then
        return
    end

    local targets = {}
    for _, card in ipairs(G.consumeables.cards) do
        if not Overflow.is_negative_edition(card) and to_big(card.qty or 1) > to_big(1) then
            targets[#targets + 1] = card
        end
    end

    for _, card in ipairs(targets) do
        if card and card.area == G.consumeables and not Overflow.is_card_dissolving(card) and to_big(card.qty or 1) > to_big(1) then
            local total_qty = to_number(card.qty or 1)
            Overflow.set_amount(card, 1, true)
            local copies = math.max(0, math.floor(total_qty - 1))
            for _ = 1, copies do
                local new_card = copy_card(card)
                new_card:add_to_deck()
                G.consumeables:emplace(new_card)
            end
        end
    end

    Overflow.sync_consumeable_card_count()
end

--- Quantity management ---

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
        selection = selection - to_number(v[1]) * 1000
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
