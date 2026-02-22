local DEFAULT_CONFIG = {
    only_stack_negatives = true,
    fix_slots = true,
    require_sellvalue = true,
    indicator_pos = 2,
    sorting_mode = 1,
}

local SORTING_MODE_MAP = {1, 2, 6, 7, 11}

function Overflow.get_sorting_mode_map()
    return SORTING_MODE_MAP
end

function Overflow.get_sorting_mode_index(mode)
    for i, v in ipairs(SORTING_MODE_MAP) do
        if v == mode then
            return i
        end
    end
    return nil
end

function Overflow.save_config()
    local parts = {}
    for k, _ in pairs(DEFAULT_CONFIG) do
        parts[#parts + 1] = k .. " = " .. tostring(Overflow.config[k])
    end
    love.filesystem.write("config/Overflow.lua", "return {" .. table.concat(parts, ", ") .. "}")
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
            local config = {}
            for k, default in pairs(DEFAULT_CONFIG) do
                if loaded[k] == nil then
                    config[k] = default
                else
                    config[k] = loaded[k]
                end
            end
            if not Overflow.get_sorting_mode_index(config.sorting_mode) then
                config.sorting_mode = DEFAULT_CONFIG.sorting_mode
            end
            return config
        end
    end

    local config = {}
    for k, v in pairs(DEFAULT_CONFIG) do
        config[k] = v
    end
    return config
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

local function partition_and_sort(hands, field, threshold, comparator, levelled_first)
    local tbl = copy_table(hands)
    local levelled = {}
    local other = {}
    for _, v in pairs(tbl) do
        if to_big(G.GAME.hands[v][field]) > to_big(threshold) then
            levelled[#levelled + 1] = v
        else
            other[#other + 1] = v
        end
    end
    table.sort(levelled, function(a, b)
        return comparator(G.GAME.hands[a][field], G.GAME.hands[b][field])
    end)
    tbl = {}
    if levelled_first then
        for _, v in ipairs(levelled) do tbl[#tbl + 1] = v end
        for _, v in ipairs(other) do tbl[#tbl + 1] = v end
    else
        for _, v in ipairs(other) do tbl[#tbl + 1] = v end
        for _, v in ipairs(levelled) do tbl[#tbl + 1] = v end
    end
    return tbl
end

local function desc(a, b) return to_big(a) > to_big(b) end
local function asc(a, b) return to_big(a) < to_big(b) end

function Overflow.sort(hands)
    local mode = Overflow.config.sorting_mode
    if mode == 2 then return partition_and_sort(hands, 'level', 1, desc, true) end
    if mode == 6 then return partition_and_sort(hands, 'played', 0, desc, true) end
    if mode == 7 then return partition_and_sort(hands, 'level', 1, asc, false) end
    if mode == 11 then return partition_and_sort(hands, 'played', 0, asc, false) end
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
