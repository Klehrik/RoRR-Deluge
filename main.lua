-- Deluge v1.1.5
-- Klehrik

log.info("Successfully loaded ".._ENV["!guid"]..".")
mods.on_all_mods_loaded(function() for _, m in pairs(mods) do if type(m) == "table" and m.RoRR_Modding_Toolkit then for _, c in ipairs(m.Classes) do if m[c] then _G[c] = m[c] end end end end end)

PATH = _ENV["!plugins_mod_folder_path"].."/"


-- Parameters
local point_scaling = 0.5
local speed_bonus = 0.25
local healing_reduction = 0.5



-- ========== Main ==========

local function add_extra_credits()
    -- Increase points by another 1 point per second
    -- This is because the 1.5x scaling from point_scale does not apply to the initial 2 pps
    if Difficulty.find("klehrik-deluge"):is_active() then
        local director = Instance.find(gm.constants.oDirectorControl)
        director.points = director.points + (2 * point_scaling)

        Alarm.create(add_extra_credits, 60)
    end
end


function __initialize()
    local diff = Difficulty.new("klehrik", "deluge")
    diff.sprite_id = Resources.sprite_load("klehrik", "delugeIcon", PATH.."deluge.png", 5, 12, 9)
    diff.sprite_loadout_id = Resources.sprite_load("klehrik", "delugeIcon2x", PATH.."deluge2x.png", 4, 25, 19)
    diff.primary_color = Color(0x324473)
    diff.sound_id = Resources.sfx_load("klehrik", "delugeSfx", PATH.."deluge.ogg")

    diff.diff_scale = 0.16
    diff.general_scale = 3.0
    diff.point_scale = 1.7 * (1 + point_scaling)
    diff.is_monsoon_or_higher = true
    diff.allow_blight_spawns = true

    diff:onRunStart(function()
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

        Alarm.create(add_extra_credits, 60)
    end)

    diff:onRunEnd(function()
        Actor.remove_callback("deluge-speedBoost")
    end)

    gm.pre_script_hook(gm.constants.actor_heal_networked, function(self, other, result, args)
        if diff:is_active() and args[1].value.object_index == gm.constants.oP then
            args[2].value = args[2].value * (1 - healing_reduction)
        end
    end)
end