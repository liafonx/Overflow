function Card:create_overflow_ui()
    if self.qty and self.qty <= 1 then
        self.qty = nil
    end

    if self.qty and self.qty_text ~= '' and (self.area ~= G.jokers or self.bypass) then
        if self.children.overflow_ui then
            self.children.overflow_ui:remove()
            self.children.overflow_ui = nil
        end

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
        if self.children.overflow_ui then
            self.children.overflow_ui:remove()
            self.children.overflow_ui = nil
        end
        self.qty = nil
    end
end
