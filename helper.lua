-- Helper functions

function find_cinstance_type(obj_constant)
    -- Returns the first instance of an object found
    local obj = nil
    for i = 1, #gm.CInstance.instances_active do
        local inst = gm.CInstance.instances_active[i]
        if inst.object_index == obj_constant then
            obj = inst
            break
        end
    end
    return obj
end

function find_all_cinstance_type(obj_constant)
    -- Returns all instances of an object
    local objs = {}
    for i = 1, #gm.CInstance.instances_active do
        local inst = gm.CInstance.instances_active[i]
        if inst.object_index == obj_constant then
            table.insert(objs, inst)
        end
    end
    if #objs > 0 then return objs end
    return nil
end