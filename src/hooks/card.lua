--- Badge UI methods (Card methods used by hooks below) ---

function Card:remove_overflow_ui()
    if self.children.overflow_ui then
        self.children.overflow_ui:remove()
        self.children.overflow_ui = nil
    end
end

function Card:create_overflow_ui()
    if self.qty and to_big(self.qty) <= to_big(1) then
        self.qty = nil
    end

    if self.qty and self.qty_text ~= '' and (self.area ~= G.jokers or self.bypass) then
        self:remove_overflow_ui()

        self.qty_text = self.qty_text or number_format(self.qty)
        if self:isInfinite() then self:setInfinite(true) end

        self.children.overflow_ui = UIBox({
            definition = {n = G.UIT.C, config = {align = 'tm'}, nodes = {
                {n = G.UIT.C, config = {ref_table = self, align = 'tm', maxw = 1.5, padding = 0.1, r = 0.08, minw = 0.45, minh = 0.45, hover = true, shadow = true, colour = G.C.UI.BACKGROUND_INACTIVE}, nodes = {
                    {n = G.UIT.T, config = {text = 'x', colour = G.C.RED, scale = 0.35, shadow = true}},
                    {n = G.UIT.T, config = {ref_table = self, ref_value = 'qty_text', colour = G.C.WHITE, scale = 0.35, shadow = true}},
                }},
            }},
            config = {
                align = Overflow.get_alignment(Overflow.config.indicator_pos) or 'tm',
                bond = 'Strong',
                parent = self,
            },
            states = {
                collide = {can = false},
                drag = {can = true},
            },
        })
    else
        self:remove_overflow_ui()
        self.qty = nil
    end
end

--- Card method hooks ---

local set_edition_ref = Card.set_edition
function Card:set_edition(edition, ...)
    set_edition_ref(self, edition, ...)

    if self.area ~= G.consumeables
        or self.config.center.set == 'Joker'
        or self.ability.split
        or Overflow.is_blacklisted(self)
        or not G.consumeables
    then
        return
    end

    local merge_target = Overflow.can_merge(self, nil, nil, true)
    if merge_target then
        local incoming_qty = self.qty or 1
        if Overflow.should_enforce_consumeable_slots()
            and not Overflow.can_accept_consumeable(self, incoming_qty, merge_target, false)
        then
            Overflow.sync_consumeable_card_count()
            return
        end

        Overflow.set_amount(merge_target, to_big(merge_target.qty or 1) + to_big(incoming_qty), true)
        self.states.visible = false
        self.ability.bypass_aleph = true
        self:start_dissolve()
        Overflow.sync_consumeable_card_count()
    end
end

local copy_card_ref = copy_card
function copy_card(other, new_card, card_scale, playing_card, strip_edition, dont_reset_qty)
    local new_card2 = copy_card_ref(other, new_card, card_scale, playing_card, strip_edition)

    if other.area == G.consumeables
        and other.config.center.set ~= 'Joker'
        and Overflow.can_merge(other, new_card2, nil, dont_reset_qty)
        and not Overflow.is_blacklisted(other)
    then
        if not dont_reset_qty then
            new_card2.ability.split = nil
            new_card2.qty = nil
            new_card2.qty_text = nil
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                func = function()
                    new_card2:create_overflow_ui()
                    other:create_overflow_ui()
                    return true
                end,
            }))
            return new_card2
        end

        Overflow.set_amount(other, to_big(other.qty or 1) * to_big(2))
        new_card2.qty = 0
        new_card2.ability.bypass_aleph = true
        new_card2:start_dissolve()
        return new_card2
    end

    new_card2.qty = nil
    new_card2.qty_text = nil
    return new_card2
end

local set_cost_ref = Card.set_cost
function Card:set_cost(...)
    local cost = set_cost_ref(self, ...)
    if self.qty and to_big(self.qty) > to_big(0) and self.ability.consumeable then
        local merged_cost = self.sell_cost * (self.qty or 1)
        if to_big(merged_cost) > to_big(0) or to_big(merged_cost) < to_big(0) then
            self.sell_cost = merged_cost
        end
        self.sell_cost_label = self.facing == 'back' and '?' or number_format(self.sell_cost)
    end
    return cost
end

local card_load_ref = Card.load
function Card:load(cardTable, other_card)
    card_load_ref(self, cardTable, other_card)
    if not self.ability then
        return
    end

    self.qty = cardTable.overflow_amount
    if cardTable.overflow_infinite then
        self.overflow_infinite = true
    end

    if self.qty then
        self.bypass = true
        self:create_overflow_ui()
        self.bypass = nil
    end
end

local card_save_ref = Card.save
function Card:save()
    local tbl = card_save_ref(self)
    tbl.overflow_amount = self and self.qty
    tbl.overflow_infinite = self and self:isInfinite()
    return tbl
end

--- Card API methods ---

function Card:getQty()
    if self:isInfinite() then return 1 end
    return self.qty or 1
end

function Card:setQty(q)
    Overflow.set_amount(self, q)
end

function Card:set_stack_display()
    self:create_overflow_ui()
end

function Card:getInfinite()
    return self.overflow_infinite
end
Card.isInfinite = Card.getInfinite

function Card:setInfinite(no_ui)
    self.overflow_infinite = true
    self.qty_text = 'Infinity'
    if not no_ui then
        self:create_overflow_ui()
    end
end

function Card:toggleInfinite(no_ui)
    self.overflow_infinite = not self.overflow_infinite
    if not no_ui then
        self.qty_text = nil
        self:create_overflow_ui()
    end
end

function Card:addQty(q)
    Overflow.set_amount(self, to_big(self.qty or 1) + to_big(q))
end

function Card:getEvalQty()
    return self.qty_used or 1
end

--- CardArea hooks ---

local emplace_ref = CardArea.emplace

local function dissolve_incoming_card(card)
    card.states.visible = false
    card.ability.bypass_aleph = true
    card:start_dissolve()
end

function CardArea:emplace(card, ...)
    local card_set = card and card.config and card.config.center and card.config.center.set
    if self ~= G.consumeables
        or not G.consumeables
        or card_set == 'Joker'
        or card.ability.split
        or Overflow.is_blacklisted(card)
    then
        emplace_ref(self, card, ...)
        if card.children then
            card:remove_overflow_ui()
        end
        return
    end

    local incoming_qty = card.qty or 1
    local enforce_slots = Overflow.should_enforce_consumeable_slots()
    local used_slots = enforce_slots and Overflow.get_consumeable_count(false) or nil
    local merge_target = Overflow.can_merge(card, nil, nil, true)

    if merge_target then
        if enforce_slots
            and not Overflow.can_accept_consumeable(card, incoming_qty, merge_target, false, used_slots)
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

    if enforce_slots
        and not Overflow.can_accept_consumeable(card, incoming_qty, nil, false, used_slots)
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
