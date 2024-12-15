-- Deluge
-- Klehrik

log.info("Successfully loaded ".._ENV["!guid"]..".")
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto(true)

PATH = _ENV["!plugins_mod_folder_path"].."/"

local diff_active = false


-- Parameters
local point_scaling = 0.5
local speed_bonus = 0.25
local healing_reduction = 0.5



-- ========== Main ==========

local function add_extra_credits()
    -- Increase points by another 1 point per second
    -- This is because the 1.5x scaling from point_scale does not apply to the initial 2 pps
    if diff_active then
        local director = Instance.find(gm.constants.oDirectorControl)
        if director:exists() then director.points = director.points + (2 * point_scaling) end

        Alarm.create(add_extra_credits, 60)
    end
end


Initialize(function()
    local diff = Difficulty.new("klehrik", "deluge")
    diff:set_sprite(
        Resources.sprite_load("klehrik", "delugeIcon", PATH.."deluge.png", 5, 12, 9),
        Resources.sprite_load("klehrik", "delugeIcon2x", PATH.."deluge2x.png", 4, 25, 19)
    )
    diff:set_primary_color(Color(0x324473))
    diff:set_sound(Resources.sfx_load("klehrik", "delugeSfx", PATH.."deluge.ogg"))

    diff:set_scaling(
        0.16,
        3.0,
        1.7 * (1 + point_scaling)
    )
    diff:set_monsoon_or_higher(true)
    diff:set_allow_blight_spawns(true)

    diff:onActive(function()
        diff_active = true

        Actor:onPostStatRecalc("deluge-statChanges", function(actor)
            if not actor.team then return end
            
            -- Player hp regen reduction
            if actor.team == 1.0 then
                actor.hp_regen = actor.hp_regen * (1 - healing_reduction)

            -- Enemy movement speed buff
            else
                actor.pHmax = actor.pHmax * (1 + speed_bonus)

            end
        end)

        Actor:onHeal("deluge-healReduction", function(actor, heal_amount)
            if not actor.team or actor.team ~= 1.0 then return end
            return heal_amount * (1 - healing_reduction)
        end)

        Alarm.create(add_extra_credits, 60)
    end)

    diff:onInactive(function()
        diff_active = false
        Actor.remove_callback("deluge-statChanges")
        Actor.remove_callback("deluge-healReduction")
    end)
end)