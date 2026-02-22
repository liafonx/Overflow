local ACTION_CHILDREN = {
    'bulk_use',
    'mass_use',
    'split_one',
    'split_half',
    'merge',
    'merge_all',
}
local ACTION_Y_START = 0.35
local ACTION_Y_STEP = 0.5

local function remove_action_children(card)
    for _, child in ipairs(ACTION_CHILDREN) do
        if card.children[child] then
            card.children[child]:remove()
            card.children[child] = nil
        end
    end
end

local function add_action_button(card, child_key, label_key, button, func, y)
    card.children[child_key] = UIBox({
        definition = {
            n = G.UIT.ROOT,
            config = {
                minh = 0.3,
                maxh = 0.5,
                minw = 0.4,
                maxw = 4,
                r = 0.08,
                padding = 0.1,
                align = 'cm',
                colour = G.C.DARK_EDITION,
                shadow = true,
                button = button,
                func = func,
                ref_table = card,
            },
            nodes = {
                {
                    n = G.UIT.T,
                    config = {
                        text = localize(label_key),
                        scale = 0.3,
                        colour = G.C.UI.TEXT_LIGHT,
                    },
                },
            },
        },
        config = {
            align = 'bmi',
            offset = {x = 0, y = y},
            bond = 'Strong',
            parent = card,
        },
    })
end

local function get_merge_scan(card)
    return Overflow.scan_merge_targets(card, nil, nil)
end

local highlight_ref = Card.highlight
function Card:highlight(is_highlighted)
    remove_action_children(self)

    if is_highlighted and self.area == G.consumeables and self.config.center.set ~= 'Joker' then
        local y = ACTION_Y_START
        local qty = self.qty or 1
        local merge_target, merge_count = get_merge_scan(self)

        if Overflow.can_bulk_use(self) and to_big(qty) > to_big(1) then
            add_action_button(self, 'bulk_use', 'k_bulk_use', 'bulk_use', 'can_bulk_use', y)
            y = y + ACTION_Y_STEP
        end

        if Overflow.mass_use_sets[self.config.center.set]
            and Overflow.has_mass_use(self.config.center.set, self.area)
        then
            add_action_button(self, 'mass_use', 'k_mass_use', 'mass_use', 'can_mass_use', y)
            y = y + ACTION_Y_STEP
        end

        if not self:isInfinite() and to_big(qty) > to_big(1) then
            add_action_button(self, 'split_one', 'k_split_one', 'split_one', 'can_split_one', y)
            y = y + ACTION_Y_STEP
            add_action_button(self, 'split_half', 'k_split_half', 'split_half', 'can_split_half', y)
            y = y + ACTION_Y_STEP
        end

        if merge_target then
            add_action_button(self, 'merge', 'k_merge', 'merge', 'can_merge', y)
            y = y + ACTION_Y_STEP
            if merge_count > 1 then
                add_action_button(self, 'merge_all', 'k_merge_all', 'merge_all', 'can_merge_all', y)
            end
        end
    end

    return highlight_ref(self, is_highlighted)
end

G.FUNCS.can_bulk_use = function(e)
    local card = e.config.ref_table
    if (card.config.center.bulk_use or Overflow.bulk_use_functions[card.config.center.key])
        and (not card.config.center.can_bulk_use or Overflow.can_bulk_use(card))
        and to_big(card.qty or 0) > to_big(1)
    then
        e.config.colour = G.C.SECONDARY_SET[card.config.center.set]
        e.config.button = 'bulk_use'
        e.states.visible = true
    else
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
        e.states.visible = false
    end
end

G.FUNCS.bulk_use = function(e)
    local card = e.config.ref_table
    card.qty_used = card:getQty()
    Overflow.set_amount(card, nil)
    card.ability.bypass_aleph = true
    card:remove_overflow_ui()
    G.FUNCS.use_card(e, false, true)
end

G.FUNCS.can_split_one = function(e)
    local card = e.config.ref_table
    if to_big(card.qty or 0) > to_big(1) then
        e.config.colour = G.C.SECONDARY_SET[card.config.center.set]
        e.config.button = 'split_one'
        e.states.visible = true
    else
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
        e.states.visible = false
    end
end

G.FUNCS.split_one = function(e)
    Overflow.suppress_entr_twisted(function()
        local card = e.config.ref_table
        local new_card = copy_card(card)

        Overflow.set_amount(new_card, nil)
        Overflow.set_amount(card, (card.qty or 1) - 1)

        new_card:add_to_deck()
        new_card.ability.split = true
        G.E_MANAGER:add_event(Event({func = function()
            new_card.ability.split = nil
            return true
        end}))

        G.consumeables:emplace(new_card)
    end)
end

G.FUNCS.can_merge = function(e)
    local card = e.config.ref_table
    local merge_target = get_merge_scan(card)
    if merge_target then
        e.config.colour = G.C.SECONDARY_SET[card.config.center.set]
        e.config.button = 'merge'
        e.states.visible = true
    else
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
        e.states.visible = false
    end
end

G.FUNCS.merge = function(e)
    local card = e.config.ref_table
    local v = get_merge_scan(card)
    if v then
        Overflow.set_amount(v, (v.qty or 1) + (card.qty or 1))
        card.ability.bypass_aleph = true
        card:start_dissolve()
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            func = function()
                v:create_overflow_ui()
                card:create_overflow_ui()
                return true
            end,
        }))
    end
end

G.FUNCS.can_split_half = function(e)
    local card = e.config.ref_table
    if to_big(card.qty or 0) > to_big(1) then
        e.config.colour = G.C.SECONDARY_SET[card.config.center.set]
        e.config.button = 'split_half'
        e.states.visible = true
    else
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
        e.states.visible = false
    end
end

G.FUNCS.split_half = function(e)
    Overflow.suppress_entr_twisted(function()
        local card = e.config.ref_table
        if not card.qty or to_big(card.qty) <= to_big(1) then
            return
        end

        local new_card = copy_card(card)
        local top_half = math.floor(card.qty / 2)
        local bottom_half = card.qty - top_half

        new_card.bypass = true
        card.bypass = true

        Overflow.set_amount(new_card, bottom_half)
        Overflow.set_amount(card, top_half)

        new_card:add_to_deck()
        new_card.ability.split = true
        G.E_MANAGER:add_event(Event({func = function()
            new_card.ability.split = nil
            return true
        end}))

        G.consumeables:emplace(new_card)

        new_card:create_overflow_ui()
        card:create_overflow_ui()
        new_card.bypass = nil
        card.bypass = nil
    end)
end

G.FUNCS.can_merge_all = function(e)
    local card = e.config.ref_table
    local _, merge_count = get_merge_scan(card)
    if merge_count > 1 then
        e.config.colour = G.C.SECONDARY_SET[card.config.center.set]
        e.config.button = 'merge_all'
        e.states.visible = true
    else
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
        e.states.visible = false
    end
end

G.FUNCS.merge_all = function(e)
    local card = e.config.ref_table
    for _, v in ipairs(G.consumeables.cards) do
        if v ~= card and Overflow.can_merge(v, card) then
            v.ability.bypass_aleph = true
            v:start_dissolve()
            Overflow.set_amount(card, (v.qty or 1) + (card.qty or 1))
        end
    end

    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        func = function()
            card:create_overflow_ui()
            return true
        end,
    }))
end

G.FUNCS.can_mass_use = function(e)
    local card = e.config.ref_table
    if card.area == G.hand or card.area == G.consumeables then
        e.config.colour = G.C.SECONDARY_SET[card.config.center.set]
        e.config.button = 'mass_use'
        if e.states then e.states.visible = true end
        return true
    end

    e.config.colour = G.C.UI.BACKGROUND_INACTIVE
    e.config.button = nil
    if e.states then e.states.visible = false end
    return nil
end

G.FUNCS.mass_use = function(e)
    local card = e.config.ref_table
    card.mass_use = true
    card.qty = card.qty or 1
    G.FUNCS.bulk_use(e)
end

local use_cardref = G.FUNCS.use_card
G.FUNCS.use_card = function(e, ...)
    local card = e.config.ref_table
    local area = card.area

    use_cardref(e, ...)

    if card.mass_use then
        card.mass_use = nil
        local c
        for _, v in ipairs(area.cards) do
            if v.config.center.set == card.config.center.set then
                c = v
            end
        end

        if c then
            c.mass_use = true
            c.qty = c.qty or 1
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                func = function()
                    G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        func = function()
                            G.FUNCS.bulk_use({config = {ref_table = c}})
                            return true
                        end,
                    }))
                    return true
                end,
            }))
        end
    end
end
