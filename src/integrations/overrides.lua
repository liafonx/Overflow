Overflow.bulk_use_functions = {
    c_black_hole = function(self, _, _, amount)
        update_hand_text({sound = 'button', volume = 0.7, pitch = 0.8, delay = 0.3}, {handname = localize('k_all_hands'), chips = '...', mult = '...', level = ''})
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.2, func = function()
            play_sound('tarot1')
            self:juice_up(0.8, 0.5)
            G.TAROT_INTERRUPT_PULSE = true
            return true
        end}))
        update_hand_text({delay = 0}, {mult = '+', StatusText = true})
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.9, func = function()
            play_sound('tarot1')
            self:juice_up(0.8, 0.5)
            return true
        end}))
        update_hand_text({delay = 0}, {chips = '+', StatusText = true})
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.9, func = function()
            play_sound('tarot1')
            self:juice_up(0.8, 0.5)
            G.TAROT_INTERRUPT_PULSE = nil
            return true
        end}))
        update_hand_text({sound = 'button', volume = 0.7, pitch = 0.9, delay = 0}, {level = '+' .. (amount or 1)})
        delay(1.3)
        for k, _ in pairs(G.GAME.hands) do
            level_up_hand(self, k, true, amount or 1)
        end
        update_hand_text({sound = 'button', volume = 0.7, pitch = 1.1, delay = 0}, {mult = 0, chips = 0, handname = '', level = ''})
    end,
    c_temperance = function(self, _, _, amount)
        local used_tarot = self
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
            play_sound('timpani')
            used_tarot:juice_up(0.3, 0.5)
            ease_dollars(self.ability.money * (amount or 1), true)
            return true
        end}))
        delay(0.6)
    end,
    c_hermit = function(self, _, _, amount)
        local used_tarot = self
        local num = to_big(2) ^ to_big(amount)
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
            play_sound('timpani')
            used_tarot:juice_up(0.3, 0.5)
            ease_dollars(math.max(0, math.min(G.GAME.dollars * num, self.ability.extra * num)), true)
            return true
        end}))
        delay(0.6)
    end,
}

function Overflow.bulk_use(card, area, amount)
    if card.config.center.bulk_use then
        card.config.center:bulk_use(card, area, nil, amount)
    elseif Overflow.bulk_use_functions[card.config.center.key] then
        Overflow.bulk_use_functions[card.config.center.key](card, area, nil, amount)
    end
end

function Overflow.can_bulk_use(card)
    if card:isInfinite() then return false end
    if type(card.config.center.can_bulk_use) == 'boolean' then return card.config.center.can_bulk_use end
    if type(card.config.center.can_bulk_use) == 'function' then return card.config.center:can_bulk_use(card) end
    return card.config.center.can_bulk_use or Overflow.bulk_use_functions[card.config.center.key] or card.config.center.bulk_use
end

local init_prototypes_ref = Game.init_item_prototypes
function Game:init_item_prototypes()
    init_prototypes_ref(self)
    for _, v in pairs(G.P_CENTERS) do
        if v.set == 'Planet' and not v.original_mod then
            Overflow.bulk_use_functions[v.key] = function(self, area, _, amount)
                update_hand_text({sound = 'button', volume = 0.7, pitch = 0.8, delay = 0.3}, {
                    handname = localize(self.ability.consumeable.hand_type, 'poker_hands'),
                    chips = G.GAME.hands[self.ability.consumeable.hand_type].chips,
                    mult = G.GAME.hands[self.ability.consumeable.hand_type].mult,
                    level = G.GAME.hands[self.ability.consumeable.hand_type].level,
                })
                level_up_hand(self, self.ability.consumeable.hand_type, nil, amount or 1)
                update_hand_text({sound = 'button', volume = 0.7, pitch = 1.1, delay = 0}, {mult = 0, chips = 0, handname = '', level = ''})
            end
        end
    end
end

--- Perkeo Override ---

function PerkeoOverride(self, orig_card, context)
    if context.ending_shop or context.forcetrigger then
        if not (G.consumeables and G.consumeables.cards and G.consumeables.cards[1]) then
            return
        end

        local skip_anims = Overflow.should_skip_animations()
        local consumeable_total = to_big(G.consumeables:get_total_count())
        local card
        if consumeable_total < to_big(200) then
            local cards = {}
            for _, v in ipairs(G.consumeables.cards) do
                for _ = 1, (v:getQty() or 1) do
                    cards[#cards + 1] = v
                end
            end
            card = pseudorandom_element(cards, pseudoseed('perkeo'))
        else
            local cards = {}
            for _, v in ipairs(G.consumeables.cards) do
                cards[#cards + 1] = {to_big(v:getQty() or 1) / consumeable_total, v}
            end
            card = Overflow.weighted_random(cards, 'perkeo')
        end

        local function create_negative_copy(base_card)
            local new_card = copy_card(base_card, nil)
            new_card.qty = 1
            new_card:set_edition('e_negative', true)
            new_card:add_to_deck()
            G.consumeables:emplace(new_card)
        end

        local function find_negative_target(base_card)
            if not base_card then
                return nil
            end

            for _, v in ipairs(G.consumeables.cards) do
                if v.config.center.key == base_card.config.center.key
                    and not Overflow.is_card_dissolving(v)
                    and Overflow.is_negative_edition(v)
                then
                    return v
                end
            end
            return nil
        end

        if card and card.config.center.set == 'Joker' then
            if not skip_anims then
                G.E_MANAGER:add_event(Event({
                    func = function()
                        create_negative_copy(card)
                        return true
                    end,
                }))
            else
                create_negative_copy(card)
            end
        elseif card and not Overflow.is_blacklisted(card) and card.config.center.set ~= 'Joker' then
            local target = find_negative_target(card)
            if target then
                if not skip_anims then
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            play_sound('negative', 1.5, 0.4)
                            target:juice_up()
                            Overflow.set_amount(target, (target.qty or 1) + 1, true)
                            return true
                        end,
                    }))
                else
                    Overflow.set_amount(target, (target.qty or 1) + 1, true)
                end
            elseif not skip_anims then
                G.E_MANAGER:add_event(Event({
                    func = function()
                        create_negative_copy(card)
                        return true
                    end,
                }))
            else
                create_negative_copy(card)
            end
        elseif card then
            create_negative_copy(card)
        end

        if not skip_anims then
            card_eval_status_text(context.blueprint_card or orig_card, 'extra', nil, nil, nil, {message = localize('k_duplicated_ex')})
        end

        return {calculated = true}
    end
end
