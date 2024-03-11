-- Deluge v1.0.0
-- Klehrik

log.info("Successfully loaded ".._ENV["!guid"]..".")
require("./helper")

local enabled = false

local stored_points = 0
local stored_time = 0
local point_increment = 0
local stored_health = 0

local file_path = path.combine(paths.plugins_data(), "Klehrik-Deluge.txt")
local succeeded, from_file = pcall(toml.decodeFromFile, file_path)
if succeeded then
    enabled = from_file.enabled
end



-- ========== Main ==========

gui.add_imgui(function()
    if ImGui.Begin("Deluge") then
        ImGui.Text("A fourth difficulty option, for those\nwho have already conquered Monsoon.\n\nDirector credits:           + 50%\nEnemy move speed:    + 25%\nAll healing:                   - 50%\n\nYou must select Monsoon as a base\ndifficulty for Deluge modifiers to apply.\n\n(Cannot be toggled during a run)\n ")

        local can_toggle = not find_cinstance_type(gm.constants.oStageControl)

        local status = "DISABLED"
        if enabled then status = "! ENABLED !" end
        if ImGui.Button("Status:  "..status) and can_toggle then
            enabled = not enabled
            pcall(toml.encodeToFile, {enabled = enabled}, {file = file_path, overwrite = true})
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
    end

    -- Turn off if Monsoon is not actually on
    if find_cinstance_type(gm.constants.oStageControl) and gm._mod_game_getDifficulty() ~= 2.0 then enabled = false end


    if enabled then
        local director = find_cinstance_type(gm.constants.oDirectorControl)
        if director then

            -- Every frame, get the point increment and increment again
            if stored_time < director.time_start then
                stored_time = director.time_start
                local inc = director.points - stored_points
                if inc > 0 and stored_points > 0 then point_increment = inc * 0.5 end

                stored_points = director.points + point_increment
                director.points = director.points + point_increment
            end
        end


        -- Loop through all instances and look for actors (with an hp variable)
        for i = 1, #gm.CInstance.instances_active do
            local inst = gm.CInstance.instances_active[i]
            if inst.hp ~= nil then
                if inst.init_diff_changes == nil then
                    inst.init_diff_changes = true

                    -- Apply speed boost to non-players
                    if inst.object_index ~= gm.constants.oP then
                        if inst.pHmax ~= nil then
                            inst.pHmax = inst.pHmax * 1.25
                        end
                    end
                end
            end
        end


        -- Using pref_name to identify which player is this client
        local pref_name = ""
        local init = find_cinstance_type(gm.constants.oInit)
        if init then pref_name = init.pref_name end

        -- Get the player that belongs to this client
        local player = nil
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

        -- Remove 50% of all healing
        if player then
            if stored_health > 0 and player.hp > stored_health then
                player.hp = player.hp - ((player.hp - stored_health) * 0.5)
            end
            stored_health = player.hp
        end
    end
end)