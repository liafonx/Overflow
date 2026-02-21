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
        or (card.base and card.base.suit)
end

local function same_edition(a, b)
    if not a.edition and not b.edition then
        return true
    end
    if a.edition and b.edition and a.edition.key == b.edition.key then
        return true
    end
    return false
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
    return card and card.edition and card.edition.negative
end

function Overflow.is_negative_edition(card)
    return is_negative(card)
end

local function cards_can_stack(a, b, bypass, ignore_area)
    if not a or not b then return false end
    if a == b and not bypass then return false end

    if a:isInfinite() or b:isInfinite() then return false end
    if a.dissolve or b.dissolve then return false end
    if Overflow.is_blacklisted(a) or Overflow.is_blacklisted(b) then return false end

    if not ignore_area and (a.area ~= G.consumeables or b.area ~= G.consumeables) then
        return false
    end

    if a.config.center.set == "Joker" or b.config.center.set == "Joker" then return false end
    if a.config.center.key ~= b.config.center.key then return false end

    if Overflow.config.only_stack_negatives or (Overflow.in_multiplayer_lobby and Overflow.in_multiplayer_lobby()) then
        if not is_negative(a) or not is_negative(b) then
            return false
        end
    elseif not same_edition(a, b) then
        return false
    end

    if Overflow.config.require_sellvalue and not same_sell_value(a, b) then
        return false
    end

    return true
end

function Overflow.can_merge(self, card, bypass, ignore_area)
    if not self then
        return false
    end

    if card then
        return cards_can_stack(self, card, bypass, ignore_area)
    end

    local area = (ignore_area and (self.area or G.consumeables)) or G.consumeables
    if not area or not area.cards then
        return nil
    end

    return Overflow.TableMatches(area.cards, function(v)
        return cards_can_stack(v, self, bypass, ignore_area)
    end)
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
        if card and card.area == G.consumeables and not card.dissolve and to_big(card.qty or 1) > to_big(1) then
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
