-- Deluge v1.1.4
-- Klehrik

log.info("Successfully loaded ".._ENV["!guid"]..".")
mods.on_all_mods_loaded(function() for k, v in pairs(mods) do if type(v) == "table" and v.hfuncs then Helper = v end end end)

local initialized_diff = false

local enabled = false
local stored_time = 0
local current_char = 0
local credits_init = false
local run_start_init = false

local director = nil

local victory = {}
for i = 1, 16 do table.insert(victory, 0) end
local char_names = {"Commando", "Huntress", "Enforcer", "Bandit", "HAN-D", "Engineer", "Miner", "Sniper", "Acrid", "Mercenary", "Loader", "CHEF", "Pilot", "Artificer", "Drifter", "Robomando"}

local file_path = path.combine(paths.plugins_data(), "Klehrik-Deluge_sav2.txt")
local succeeded, from_file = pcall(toml.decodeFromFile, file_path)
if succeeded then
    victory = from_file.victory
end

local icon_path = _ENV["!plugins_mod_folder_path"].."/deluge.png"
local icon_path2x = _ENV["!plugins_mod_folder_path"].."/deluge2x.png"
local diff_icon = gm.sprite_add(icon_path, 5, false, false, 12, 9)
local diff_icon2x = gm.sprite_add(icon_path2x, 4, false, false, 25, 19)
if diff_gray ~= -1 and diff_color ~= -1 then log.info("Loaded difficulty icon sprites.")
else log.info("Failed to load difficulty icon sprites.") end

local diff_sfx = gm.audio_create_stream(_ENV["!plugins_mod_folder_path"].."/deluge.ogg")
if diff_sfx ~= -1 then log.info("Loaded difficulty sfx.")
else log.info("Failed to load difficulty sfx.") end

local diff_id = -2


-- Parameters
-- * Remember to update the description text below if modified
local point_scaling = 0.5
local speed_bonus = 0.25
local healing_reduction = 0.5



-- ========== Main ==========

gui.add_imgui(function()
    if ImGui.Begin("Deluge") then
        -- Description
        ImGui.Text("Adds a fourth difficulty option, for\nthose who have conquered Monsoon.")

        -- Victory display
        ImGui.Text("\n_____________________________________\n\n[Victory Counts]\n ")
        for i = 1, 15 do
            ImGui.Text(char_names[i]..":  "..victory[i])
        end
        if current_char == 15.0 or victory[16] > 0 then
            ImGui.Text(char_names[16]..":  "..victory[16])
        end
    end

    ImGui.End()
end)


gm.pre_script_hook(gm.constants.actor_heal_networked, function(self, other, result, args)
    -- Reduce player healing by 50%
    if enabled and args[1].value.object_index == gm.constants.oP then
        args[2].value = args[2].value * (1.0 - healing_reduction)
    end
end)


gm.pre_script_hook(gm.constants.step_actor, function(self, other, result, args)
    -- Apply speed bonus
    if enabled and self.team == 2.0 and self.deluge_speed_boost == nil then
        self.deluge_speed_boost = true

        if self.pHmax ~= nil then
            self.pHmax = self.pHmax * (1 + speed_bonus)
            self.pHmax_base = self.pHmax
        end
    end
end)


gm.pre_script_hook(gm.constants.__input_system_tick, function()
    -- Initialize difficulty
    if not initialized_diff then
        initialized_diff = true

        diff_id = gm.difficulty_create("klehrik", "deluge")   -- Namespace, Identifier
        local class_diff = gm.variable_global_get("class_difficulty")[diff_id + 1]
        local values = {
            "Deluge",       -- Name
            "For those who have conquered Monsoon.\nYou will be washed away in a flood of pain.\n\n<c_stack>Director credits     + 50%\nEnemy move speed    + 25%\nAll healing            - 50%",  -- Description
            diff_icon,      -- Sprite ID
            diff_icon2x,    -- Sprite Loadout ID
            7554098,        -- Primary Color
            diff_sfx,       -- Sound ID
            0.16,           -- diff_scale; Affects enemy stat scaling (health and damage)
                            --     0.06 (Drizzle), 0.12 (Rainstorm), 0.16 (Monsoon)
            3.0,            -- general_scale; Affects timer and chest price scaling
                            --     The text update and bell sound only update/play at the start of every minute
                            --     1.0 (Drizzle), 2.0 (Rainstorm), 3.0 (Monsoon)
            1.7 * (1 + point_scaling),  -- point_scale; Affects point scaling, with the increase at any minute being 2.0 + (this * minutesElapsed)
                            --                 e.g., with Monsoon's 1.7, at 5 minutes, the director gets 2.0 + (1.7 * 5) = 10.5 points per second
                            --                 1.0 (Drizzle), 1.0 (Rainstorm), 1.7 (Monsoon)
            true,           -- Either "is monsoon or higher" or "allow blight spawns"
            true            -- Whichever one the bool above isn't
        }
        for i = 2, 12 do gm.array_set(class_diff, i, values[i - 1]) end
    end


    -- Reset some variables on the character select screen
    local select_ = Helper.find_active_instance(gm.constants.oSelectMenu)
    if Helper.instance_exists(select_) then
        enabled = false
        current_char = select_.choice
        run_start_init = false
    end


    -- Check if Deluge is on
    if gm._mod_game_getDifficulty() == diff_id then
        enabled = true

        if Helper.instance_exists(director) then

            -- Reset variables when starting a new run
            if director.time_start <= 0 then
                if not run_start_init then
                    stored_time = 0
                    credits_init = false
                    run_start_init = true

                    -- Reduce player health regen
                    player = Helper.get_client_player()
                    if Helper.instance_exists(player) then
                        if player.hp_regen ~= nil then
                            player.hp_regen = player.hp_regen * (1.0 - healing_reduction)
                            player.hp_regen_base = player.hp_regen
                            player.hp_regen_level = player.hp_regen_level * (1.0 - healing_reduction)
                        end
                    end
                end
            else run_start_init = false
            end


            -- Run this every second
            if stored_time < director.time_start then
                stored_time = director.time_start

                -- Increase points by another 1 point per second
                -- This is because the 1.5x scaling from point_scale does not apply to the initial 2 pps
                director.points = director.points + (2 * point_scaling)
            end
        else director = Helper.find_active_instance(gm.constants.oDirectorControl)
        end
    end


    -- Save victory
    if enabled and Helper.find_active_instance(gm.constants.oCutscenePlayback2) and not credits_init then
        local results = Helper.find_active_instance(gm.constants.oResultsScreen)
        if Helper.instance_exists(results) then
            credits_init = true
            victory[current_char + 1] = victory[current_char + 1] + 1
            pcall(toml.encodeToFile, {victory = victory}, {file = file_path, overwrite = true})
        end
    end
end)