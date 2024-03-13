-- Deluge v1.1.0
-- Klehrik

log.info("Successfully loaded ".._ENV["!guid"]..".")
require("./helper")

local enabled = false
local stored_time = 0
local stored_stages = 0
local stored_health = 0
local stored_max_health = 0     -- Make sure the health gained from max hp increase isn't affected by "healing" reduction
local credits_init = false
local current_char = 0

local director = nil
local player = nil

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


-- Parameters
-- * Remember to update the description text below if modified
local point_scaling = 0.5
local speed_bonus = 0.25
local healing_reduction = 0.5


-- Initialize difficulty
local diff_id = gm.difficulty_create("klehrik", "deluge")   -- namespace, identifier
local class_diff = gm.variable_global_get("class_difficulty")[diff_id + 1]
local values = {
    "Deluge",       -- Name
    "For those who have conquered Monsoon.\nYou will be washed away in a flood of pain.\n\n<c_stack>Director credits     + 50%\nEnemy move speed    + 25%\nAll healing            - 50%",  -- Description
    diff_icon,      -- Sprite ID
    diff_icon2x,    -- Sprite Loadout ID
    7554098,        -- Primary Color
    gm.constants.wUI_Select,    -- Sound ID
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



-- ========== Main ==========

local function does_instance_exist(inst)
    return inst and gm._mod_instance_valid(inst) == 1.0
end


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


gm.pre_script_hook(gm.constants.__input_system_tick, function()

    -- Reset some variables on the character select screen
    local select_ = find_cinstance_type(gm.constants.oSelectMenu)
    if select_ then
        enabled = false
        current_char = select_.choice
    end


    -- Check if Deluge is on
    if gm._mod_game_getDifficulty() == diff_id then
        enabled = true

        if does_instance_exist(director) then

            -- Reset variables when starting a new run
            if director.time_start <= 0 then
                stored_time = 0
                stored_stages = 0
                stored_health = 0
                stored_max_health = 0
                credits_init = false
            end


            -- Run this every second
            if stored_time < director.time_start then
                stored_time = director.time_start

                -- Increase points by another 1 point per second
                -- This is because the 1.5x scaling from point_scale does not apply to the initial 2 pps
                director.points = director.points + (2 * point_scaling)

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
        if does_instance_exist(player) then
            -- Make sure the "healing" is not from stage transition
            local stage_check = true
            if does_instance_exist(director) and stored_stages < director.stages_passed then
                stage_check = false
                stored_stages = director.stages_passed
            end

            if stored_health > 0 and player.hp > stored_health and stored_max_health >= player.maxhp and stage_check then
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
    end


    -- Save victory
    if enabled and find_cinstance_type(gm.constants.oCutscenePlayback2) and not credits_init then
        local results = find_cinstance_type(gm.constants.oResultsScreen)
        if results then
            credits_init = true
            victory[current_char + 1] = victory[current_char + 1] + 1
            pcall(toml.encodeToFile, {victory = victory}, {file = file_path, overwrite = true})
        end
    end
end)