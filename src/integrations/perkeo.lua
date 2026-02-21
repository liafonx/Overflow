function PerkeoOverride(self, orig_card, context)
    if context.ending_shop or context.forcetrigger then
        if not (G.consumeables and G.consumeables.cards and G.consumeables.cards[1]) then
            return
        end

        local card
        if to_big(G.consumeables:get_total_count()) < to_big(200) then
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
                cards[#cards + 1] = {to_big(v:getQty() or 1) / to_big(v.area:get_total_count()), v}
            end
            card = Overflow.weighted_random(cards, 'perkeo')
        end

        if card and card.config.center.set == 'Joker' then
            if not Overflow.should_skip_animations() then
                G.E_MANAGER:add_event(Event({
                    func = function()
                        local new_card = copy_card(card, nil)
                        new_card.qty = 1
                        new_card:set_edition('e_negative', true)
                        new_card:add_to_deck()
                        G.consumeables:emplace(new_card)
                        return true
                    end,
                }))
            else
                local new_card = copy_card(card, nil)
                new_card.qty = 1
                new_card:set_edition('e_negative', true)
                new_card:add_to_deck()
                G.consumeables:emplace(new_card)
            end
        elseif card and Overflow.can_merge(card, card, true) and not Overflow.is_blacklisted(card) then
            if card.qty then
                if not Overflow.should_skip_animations() then
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            play_sound('negative', 1.5, 0.4)
                            Overflow.set_amount(card, card.qty + 1, true)
                            card:juice_up()
                            return true
                        end,
                    }))
                else
                    Overflow.set_amount(card, card.qty + 1, true)
                end
            else
                local check
                for _, v in ipairs(G.consumeables.cards) do
                    if v.edition and v.edition.negative and v.config.center.key == card.config.center.key and v ~= card and not v.dissolve then
                        if not Overflow.should_skip_animations() then
                            G.E_MANAGER:add_event(Event({
                                func = function()
                                    play_sound('negative', 1.5, 0.4)
                                    v:juice_up()
                                    Overflow.set_amount(v, (v.qty or 1) + 1, true)
                                    return true
                                end,
                            }))
                        else
                            Overflow.set_amount(v, (v.qty or 1) + 1, true)
                        end
                        check = true
                    end
                end

                if not check then
                    if not Overflow.should_skip_animations() then
                        G.E_MANAGER:add_event(Event({
                            func = function()
                                local new_card = copy_card(card, nil)
                                new_card.qty = 1
                                new_card:set_edition('e_negative', true)
                                new_card:add_to_deck()
                                G.consumeables:emplace(new_card)
                                return true
                            end,
                        }))
                    else
                        local new_card = copy_card(card, nil)
                        new_card.qty = 1
                        new_card:set_edition('e_negative', true)
                        new_card:add_to_deck()
                        G.consumeables:emplace(new_card)
                    end
                end
            end
        elseif card then
            local new_card = copy_card(card, nil)
            new_card.qty = 1
            new_card:set_edition('e_negative', true)
            new_card:add_to_deck()
            G.consumeables:emplace(new_card)
        end

        if not Overflow.should_skip_animations() then
            card_eval_status_text(context.blueprint_card or orig_card, 'extra', nil, nil, nil, {message = localize('k_duplicated_ex')})
        end

        return {calculated = true}
    end
end
