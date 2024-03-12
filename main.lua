-- Deluge v1.0.5
-- Klehrik

log.info("Successfully loaded ".._ENV["!guid"]..".")
require("./helper")

local enabled = false

local director = nil
local player = nil

local stored_points = 0
local stored_time = 0
local point_increment = 0
local stored_health = 0
local stored_max_health = 0     -- Make sure the health gained from max hp increase isn't affected by "healing" reduction
local credits_init = false
local current_char = 0

local victory = {}
for i = 1, 16 do table.insert(victory, 0) end
local char_names = {"Commando", "Huntress", "Enforcer", "Bandit", "HAN-D", "Engineer", "Miner", "Sniper", "Acrid", "Mercenary", "Loader", "CHEF", "Pilot", "Artificer", "Drifter", "Robomando"}

local file_path = path.combine(paths.plugins_data(), "Klehrik-Deluge_sav2.txt")
local succeeded, from_file = pcall(toml.decodeFromFile, file_path)
if succeeded then
    enabled = from_file.enabled
    victory = from_file.victory
end

local icon_path = _ENV["!plugins_mod_folder_path"].."/deluge.png"
local diff_icon = gm.sprite_add(icon_path, 1, false, false, 25, 16)
if diff_icon ~= -1 then log.info("Loaded difficulty icon sprite.") end


-- Parameters
local director_bonus = 0.5
local speed_bonus = 0.25
local healing_reduction = 0.5



-- ========== Main ==========

local function dec_to_percent(value)
    local str = tostring(gm.round(value * 100))
    return gm.string_copy(str, 1, #str - 2)
end


local function save_to_file()
    pcall(toml.encodeToFile, {
        enabled = enabled,
        victory = victory
    }, {file = file_path, overwrite = true})
end


gui.add_imgui(function()
    if ImGui.Begin("Deluge") then
        -- Description
        ImGui.Text("A fourth difficulty option, for those\nwho have already conquered Monsoon.\n\nDirector credits:           + "..dec_to_percent(director_bonus).."%\nEnemy move speed:    + "..dec_to_percent(speed_bonus).."%\nAll healing:                   - "..dec_to_percent(healing_reduction).."%\n\nYou must select Monsoon as a base\ndifficulty for Deluge modifiers to apply.\n\n(Can only be toggled while on\nthe character select screen)\n ")

        -- Toggle status
        local status = "DISABLED"
        if enabled then status = "! ENABLED !" end
        local can_toggle = find_cinstance_type(gm.constants.oSelectMenu)
        if ImGui.Button("Status:  "..status) and can_toggle then
            enabled = not enabled
            save_to_file()
        end

        -- Victory display
        ImGui.Text("\n_____________________________________\n\n[Deluge Victory Counts]\n ")
        for i = 1, 15 do
            ImGui.Text(char_names[i]..":  "..victory[i])
        end
        if current_char == 15.0 or victory[16] > 0 then
            ImGui.Text(char_names[16]..":  "..victory[16])
        end
    end

    ImGui.End()
end)


gm.pre_script_hook(gm.constants.__input_system_tick, function()
    -- Reset when starting a new run (check for character select menu)
    local select_ = find_cinstance_type(gm.constants.oSelectMenu)
    if select_ then
        stored_points = 0
        stored_time = 0
        point_increment = 0
        stored_health = 0
        stored_max_health = 0
        credits_init = false
        current_char = select_.choice
    end


    if enabled then
        if director and gm._mod_instance_valid(director) == 1.0 then
            -- Run these every second
            if stored_time < director.time_start then

                -- Turn off if Monsoon is not actually on
                if find_cinstance_type(gm.constants.oStageControl) and gm._mod_game_getDifficulty() ~= 2.0 then
                    enabled = false
                    save_to_file()
                end


                -- Get the director's point increment and increment again by a portion
                stored_time = director.time_start
                local inc = director.points - stored_points
                if inc > 0 and stored_points > 0 then point_increment = inc * director_bonus end

                stored_points = director.points + point_increment
                director.points = director.points + point_increment


                -- Loop through all instances and look for enemies (on team 2.0)                
                for i = 1, #gm.CInstance.instances_active do
                    local inst = gm.CInstance.instances_active[i]
                    if inst.team == 2.0 and inst.init_diff_changes == nil then
                        inst.init_diff_changes = true

                        if inst.pHmax ~= nil then
                            inst.pHmax = inst.pHmax * (1 + speed_bonus)
                            inst.pHmax_base = inst.pHmax
                        end
                    end
                end

            end
        else director = find_cinstance_type(gm.constants.oDirectorControl)
        end


        -- Remove 50% of all healing
        if player and gm._mod_instance_valid(player) == 1.0 then
            if stored_health > 0 and player.hp > stored_health and stored_max_health >= player.maxhp then
                player.hp = player.hp - ((player.hp - stored_health) * healing_reduction)
            end
            stored_health = player.hp
            stored_max_health = player.maxhp

        else
            -- Using pref_name to identify which player is this client
            local pref_name = ""
            local init = find_cinstance_type(gm.constants.oInit)
            if init then pref_name = init.pref_name end

            -- Get the player that belongs to this client
            local players = find_all_cinstance_type(gm.constants.oP)
            if players then
                for i = 1, #players do
                    if players[i] then
                        if players[i].user_name == pref_name then
                            player = players[i]
                            break
                        end
                    end
                end
            end

        end


        -- Modify results screen a bit
        local results = find_cinstance_type(gm.constants.oResultsScreen)
        if results then

            -- Victory or Defeat screen
            -- (Doesn't actually work for the latter unfortunately)
            if not results.is_history_screen then
                results.diff_name = "Deluge"
                results.diff_sprite = diff_icon
            end

            -- Save victory
            if find_cinstance_type(gm.constants.oCredits) and (not credits_init) then
                credits_init = true
                victory[current_char + 1] = victory[current_char + 1] + 1
                save_to_file()
            end

        end
    end
end)