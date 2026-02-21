Overflow = Overflow or {}
Overflow.blacklist = Overflow.blacklist or {}
Overflow.mass_use_sets = Overflow.mass_use_sets or {
    Planet = true,
}
Overflow.bulk_use_caps = Overflow.bulk_use_caps or {}

to_big = to_big or function(num) return num or -1e300 end
is_number = is_number or function(num) return type(num) == 'number' end
to_number = to_number or function(num) return num or -1e300 end

require('overflow/core/config')
require('overflow/core/slots')
require('overflow/core/merge')
require('overflow/core/quantity')

require('overflow/integrations/bulk_use')
require('overflow/integrations/perkeo')

require('overflow/ui/badge')
require('overflow/ui/config_tab')
require('overflow/hooks/cardarea')
require('overflow/hooks/card')
require('overflow/hooks/button_callbacks')
require('overflow/ui/actions')
