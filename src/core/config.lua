local DEFAULT_CONFIG = {
    only_stack_negatives = true,
    fix_slots = true,
    require_sellvalue = true,
    indicator_pos = 2,
    sorting_mode = 1,
}

local SORTING_MODE_MAP = {1, 2, 6, 7, 11}

local function is_supported_sort_mode(mode)
    for _, v in ipairs(SORTING_MODE_MAP) do
        if v == mode then
            return true
        end
    end
    return false
end

function Overflow.get_sorting_mode_map()
    return SORTING_MODE_MAP
end

function Overflow.save_config()
    local serialized = "return {"
        .. " only_stack_negatives = " .. tostring(Overflow.config.only_stack_negatives or false)
        .. ", fix_slots = " .. tostring(Overflow.config.fix_slots or false)
        .. ", require_sellvalue = " .. tostring(Overflow.config.require_sellvalue ~= false)
        .. ", indicator_pos = " .. tostring(Overflow.config.indicator_pos or 2)
        .. ", sorting_mode = " .. tostring(Overflow.config.sorting_mode or 1)
        .. "}"
    love.filesystem.write("config/Overflow.lua", serialized)
end

function Overflow.load_config()
    if love.filesystem.exists("config/Overflow.lua") then
        local str = ""
        for line in love.filesystem.lines("config/Overflow.lua") do
            str = str .. line
        end
        local ok, loaded = pcall(function()
            return loadstring(str)()
        end)
        if ok and type(loaded) == "table" then
            local config = {
                only_stack_negatives = loaded.only_stack_negatives,
                fix_slots = loaded.fix_slots,
                require_sellvalue = loaded.require_sellvalue,
                indicator_pos = loaded.indicator_pos,
                sorting_mode = loaded.sorting_mode,
            }
            if config.only_stack_negatives == nil then config.only_stack_negatives = DEFAULT_CONFIG.only_stack_negatives end
            if config.fix_slots == nil then config.fix_slots = DEFAULT_CONFIG.fix_slots end
            if config.require_sellvalue == nil then config.require_sellvalue = DEFAULT_CONFIG.require_sellvalue end
            if config.indicator_pos == nil then config.indicator_pos = DEFAULT_CONFIG.indicator_pos end
            if not is_supported_sort_mode(config.sorting_mode) then
                config.sorting_mode = DEFAULT_CONFIG.sorting_mode
            end
            return config
        end
    end

    return {
        only_stack_negatives = DEFAULT_CONFIG.only_stack_negatives,
        fix_slots = DEFAULT_CONFIG.fix_slots,
        require_sellvalue = DEFAULT_CONFIG.require_sellvalue,
        indicator_pos = DEFAULT_CONFIG.indicator_pos,
        sorting_mode = DEFAULT_CONFIG.sorting_mode,
    }
end

if not Overflow.config then
    Overflow.config = Overflow.load_config()
end

function Overflow.get_alignment(align)
    return ({
        'cm',
        'tm',
        'bm',
        'tr',
        'tl',
        'br',
        'bl',
    })[align]
end

function Overflow.sort(hands)
    local mode = Overflow.config.sorting_mode
    local tbl, levelled, other

    if mode == 2 then
        tbl = copy_table(hands)
        levelled = {}
        other = {}
        for _, v in pairs(tbl) do
            if to_big(G.GAME.hands[v].level) > to_big(1) then
                levelled[#levelled + 1] = v
            else
                other[#other + 1] = v
            end
        end
        table.sort(levelled, function(a, b)
            return to_big(G.GAME.hands[a].level) > to_big(G.GAME.hands[b].level)
        end)
        tbl = {}
        for _, v in ipairs(levelled) do tbl[#tbl + 1] = v end
        for _, v in ipairs(other) do
            if to_big(G.GAME.hands[v].level) <= to_big(1) then
                tbl[#tbl + 1] = v
            end
        end
        return tbl
    end

    if mode == 6 then
        tbl = copy_table(hands)
        levelled = {}
        other = {}
        for _, v in pairs(tbl) do
            if to_big(G.GAME.hands[v].played) > to_big(0) then
                levelled[#levelled + 1] = v
            else
                other[#other + 1] = v
            end
        end
        table.sort(levelled, function(a, b)
            return to_big(G.GAME.hands[a].played) > to_big(G.GAME.hands[b].played)
        end)
        tbl = {}
        for _, v in ipairs(levelled) do tbl[#tbl + 1] = v end
        for _, v in ipairs(other) do
            if to_big(G.GAME.hands[v].played) <= to_big(0) then
                tbl[#tbl + 1] = v
            end
        end
        return tbl
    end

    if mode == 7 then
        tbl = copy_table(hands)
        levelled = {}
        other = {}
        for _, v in pairs(tbl) do
            if to_big(G.GAME.hands[v].level) > to_big(1) then
                levelled[#levelled + 1] = v
            else
                other[#other + 1] = v
            end
        end
        table.sort(levelled, function(a, b)
            return to_big(G.GAME.hands[a].level) < to_big(G.GAME.hands[b].level)
        end)
        tbl = {}
        for _, v in ipairs(other) do
            if to_big(G.GAME.hands[v].level) <= to_big(1) then
                tbl[#tbl + 1] = v
            end
        end
        for _, v in ipairs(levelled) do tbl[#tbl + 1] = v end
        return tbl
    end

    if mode == 11 then
        tbl = copy_table(hands)
        levelled = {}
        other = {}
        for _, v in pairs(tbl) do
            if to_big(G.GAME.hands[v].played) > to_big(0) then
                levelled[#levelled + 1] = v
            else
                other[#other + 1] = v
            end
        end
        table.sort(levelled, function(a, b)
            return to_big(G.GAME.hands[a].played) < to_big(G.GAME.hands[b].played)
        end)
        tbl = {}
        for _, v in ipairs(other) do
            if to_big(G.GAME.hands[v].played) <= to_big(0) then
                tbl[#tbl + 1] = v
            end
        end
        for _, v in ipairs(levelled) do tbl[#tbl + 1] = v end
        return tbl
    end

    return hands
end

function Overflow.should_skip_animations(strict)
    if type(Talisman) == 'table'
        and type(Talisman.config_file) == 'table'
        and Talisman.config_file.disable_anims
    then
        return true
    end

    if type(Handy) == 'table'
        and type(Handy.animation_skip) == 'table'
        and type(Handy.animation_skip.get_value) == 'function'
    then
        local threshold = strict and 4 or 3
        local value = Handy.animation_skip.get_value()
        if type(value) == 'number' and value >= threshold then
            return true
        end
    end

    return false
end
