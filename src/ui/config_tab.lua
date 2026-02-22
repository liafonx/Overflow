Overflow.overflowConfigTab = function()
    local sorting_mode_map = Overflow.get_sorting_mode_map()
    local sorting_mode_options = {
        localize('sorting_default'),
        localize('sorting_lh'),
        localize('sorting_ph'),
        localize('sorting_ll'),
        localize('sorting_pl'),
    }

    local sorting_option = Overflow.get_sorting_mode_index(Overflow.config.sorting_mode) or 1

    local ovrf_nodes = {}
    local left_settings = {n = G.UIT.C, config = {align = 'tl', padding = 0.05}, nodes = {}}
    local right_settings = {n = G.UIT.C, config = {align = 'tl', padding = 0.05}, nodes = {}}
    local config = {n = G.UIT.R, config = {align = 'tm', padding = 0}, nodes = {left_settings, right_settings}}

    ovrf_nodes[#ovrf_nodes + 1] = config
    local in_mp_lobby = Overflow.in_multiplayer_lobby and Overflow.in_multiplayer_lobby()

    ovrf_nodes[#ovrf_nodes + 1] = create_toggle({
        label = in_mp_lobby and localize('k_only_stack_negatives_mp') or localize('k_only_stack_negatives'),
        active_colour = HEX('40c76d'),
        ref_table = Overflow.config,
        ref_value = 'only_stack_negatives',
        callback = function()
            if Overflow.config.only_stack_negatives then
                Overflow.unstack_non_negative_consumeables()
            end
            Overflow.save_config()
        end,
    })

    ovrf_nodes[#ovrf_nodes + 1] = create_toggle({
        label = in_mp_lobby and localize('k_fix_slots_mp') or localize('k_fix_slots'),
        active_colour = HEX('40c76d'),
        ref_table = Overflow.config,
        ref_value = 'fix_slots',
        callback = function() Overflow.save_config() end,
    })

    ovrf_nodes[#ovrf_nodes + 1] = create_toggle({
        label = localize('k_require_sell_values'),
        active_colour = HEX('40c76d'),
        ref_table = Overflow.config,
        ref_value = 'require_sellvalue',
        callback = function() Overflow.save_config() end,
    })

    ovrf_nodes[#ovrf_nodes + 1] = create_option_cycle({
        label = localize('k_indicator_pos'),
        scale = 0.7,
        w = 7,
        options = {
            localize('k_center'),
            localize('k_top_center'),
            localize('k_bottom_center'),
            localize('k_top_right'),
            localize('k_top_left'),
            localize('k_bottom_right'),
            localize('k_bottom_left'),
        },
        opt_callback = 'overflow_update_alignment',
        current_option = Overflow.config.indicator_pos,
    })

    ovrf_nodes[#ovrf_nodes + 1] = create_option_cycle({
        label = localize('sorting_mode'),
        scale = 0.8,
        w = 8,
        options = sorting_mode_options,
        opt_callback = 'update_sorting_mode',
        current_option = sorting_option,
    })

    return {
        n = G.UIT.ROOT,
        config = {
            emboss = 0.05,
            minh = 6,
            r = 0.1,
            minw = 10,
            align = 'cm',
            padding = 0.2,
            colour = G.C.BLACK,
        },
        nodes = ovrf_nodes,
    }
end

G.FUNCS.overflow_update_alignment = function(e)
    Overflow.config.indicator_pos = e.to_key
    Overflow.save_config()
    if G.consumeables then
        for _, v in pairs(G.consumeables.cards) do
            v:create_overflow_ui()
        end
    end
end

G.FUNCS.update_sorting_mode = function(e)
    local sorting_mode_map = Overflow.get_sorting_mode_map()
    Overflow.config.sorting_mode = sorting_mode_map[e.to_key] or 1
    Overflow.save_config()
end
