Overflow = Overflow or {}
Overflow.blacklist = Overflow.blacklist or {}
Overflow.mass_use_sets = Overflow.mass_use_sets or {
    Planet = true,
}
Overflow.bulk_use_caps = Overflow.bulk_use_caps or {}

to_big = to_big or function(num) return num or -1e300 end
is_number = is_number or function(num) return type(num) == 'number' end
to_number = to_number or function(num) return num or -1e300 end

function Overflow.is_card_dissolving(card)
    if not card then
        return false
    end

    if card.ability and card.ability.bypass_aleph then
        return true
    end

    local hidden = card.states and card.states.visible == false
    if not hidden then
        return false
    end

    local state = card.dissolve
    if state == nil then
        return true
    end

    if type(state) == 'number' then
        return state >= 0
    end

    if type(state) == 'boolean' then
        return state
    end

    return true
end

function Overflow.suppress_entr_twisted(fn)
    local mod = G.GAME.modifiers.entr_twisted
    G.GAME.modifiers.entr_twisted = nil
    fn()
    G.GAME.modifiers.entr_twisted = mod
end

require('overflow/core/config')
require('overflow/core/slots')
require('overflow/core/stacking')

require('overflow/integrations/overrides')

require('overflow/ui/config_tab')
require('overflow/hooks/card')
require('overflow/hooks/button_callbacks')
require('overflow/ui/actions')
