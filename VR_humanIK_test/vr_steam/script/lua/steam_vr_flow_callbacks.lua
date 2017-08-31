
SteamVRFlowCallbacks = SteamVRFlowCallbacks or {}

require 'vr_steam/script/lua/steam_vr'

local Unit      = stingray.Unit
local World      = stingray.World
local Matrix4x4  = stingray.Matrix4x4
local Matrix4x4Box  = stingray.Matrix4x4Box
local Vector3    = stingray.Vector3
local Vector3Box = stingray.Vector3Box
local Color      = stingray.Color
local SteamVR    = stingray.SteamVR
local LineObject = stingray.LineObject
local Quaternion = stingray.Quaternion
local Actor = stingray.Actor
local Material = stingray.Material
local Mesh = stingray.Mesh

local _selection_mask_counter = 0

local button_map = {
    System     = SteamVR.BUTTON_SYSTEM,
    Menu       = SteamVR.BUTTON_MENU,
    Grip       = SteamVR.BUTTON_GRIP,
    Touch      = SteamVR.BUTTON_TOUCH,
    Trigger    = SteamVR.BUTTON_TRIGGER,
    TouchUp    = SteamVR.BUTTON_TOUCH_UP,
    TouchDown  = SteamVR.BUTTON_TOUCH_DOWN,
    TouchLeft  = SteamVR.BUTTON_TOUCH_LEFT,
    TouchRight = SteamVR.BUTTON_TOUCH_RIGHT
}

local eye_map = {
    LeftEye  = SteamVR.EYE_LEFT,
    RightEye = SteamVR.EYE_RIGHT
}

local controller_map = {
    Controller1 = 0,
    Controller2 = 1,
    Controller3 = 2,
    Controller4 = 3
}

local function is_world(space)
    return (space == "World")
end

function SteamVRFlowCallbacks.is_enabled(t)
    if SteamVR and SteamVRSystem and Project.vr_system then
        t.value = SteamVRSystem.is_enabled(Project.vr_system)
    end

    return t
end

function SteamVRFlowCallbacks.button_events(t)
    if not SteamVR then return t end

    local index = t.controllerIndex - 1
    local btn   = button_map[t.buttonName]

    local value, _ = SteamVR.controller_value(index, btn)

    t.value    = value
    t.pressed  = SteamVR.controller_pressed(index, btn)
    t.held     = SteamVR.controller_held(index, btn)
    t.released = SteamVR.controller_released(index, btn)

    return t
end

function SteamVRFlowCallbacks.touch_events(t)
	if not SteamVR then return t end

    local index = t.controllerIndex - 1
    local btn   = button_map[t.buttonName]

    t.x, t.y    = SteamVR.controller_value(index, btn)
    t.pressed   = SteamVR.controller_pressed(index, btn)
    t.held      = SteamVR.controller_held(index, btn)
    t.released  = SteamVR.controller_released(index, btn)
    t.touched   = SteamVR.controller_touched(index, btn)
    t.untouched = SteamVR.controller_untouched(index, btn)

    return t
end

function SteamVRFlowCallbacks.controller_pose(t)
    if not SteamVR then return t end

    local pose
    if is_world(t.space) then
        pose = SteamVR.controller_world_pose(t.controllerIndex - 1)
    else
        pose = SteamVR.controller_local_pose(t.controllerIndex - 1)
    end
    --print(pose)
    --print(Matrix4x4.translation(pose))
    t.position = Matrix4x4.translation(pose)
    t.rotation = Matrix4x4.rotation(pose)

    return t
end

function SteamVRFlowCallbacks.hmd_pose(t)
    if not SteamVR then return t end

    local head, left, right
    if is_world(t.space) then
        head, left, right = SteamVR.hmd_world_pose()
    else
        head, left, right = SteamVR.hmd_local_pose()
    end

    t.headPosition     = Matrix4x4.translation(head)
    t.headRotation     = Matrix4x4.rotation(head)
    t.leftEyePosition  = Matrix4x4.translation(left)
    t.leftEyeRotation  = Matrix4x4.rotation(left)
    t.rightEyePosition = Matrix4x4.translation(right)
    t.rightEyeRotation = Matrix4x4.rotation(right)

    return t
end

function SteamVRFlowCallbacks.is_tracked(t)
    if not SteamVR then return t end

    if t.deviceName == "HMD" then
        t.value = SteamVR.is_hmd_tracked()
    else
        t.value = SteamVR.is_controller_tracked(controller_map[t.deviceName])
    end

    return t
end

function SteamVRFlowCallbacks.controller_feedback(t)
    if not SteamVR then return t end

    SteamVR.controller_pulse(t.controllerIndex - 1, t.seconds or 0.2)

    return t
end

function SteamVRFlowCallbacks.set_tracking_space(t)
    if not SteamVR then return t end

    local space = SteamVR.tracking_space_pose()
    local position = t.position or Matrix4x4.translation(space)
    local rotation = t.rotation or Matrix4x4.rotation(space)

    local pose = Matrix4x4.from_quaternion_position(rotation, position)
    local scale = t.scale or Vector3(1, 1, 1)
    Matrix4x4.set_scale(pose, scale)
    SteamVR.set_tracking_space(position, rotation, scale)

    return t
end

function SteamVRFlowCallbacks.get_tracking_space(t)
    if not SteamVR then return t end

    local pose = stingray.SteamVR.tracking_space_pose()  
    t.position = Matrix4x4.translation(pose)
    t.rotation = Matrix4x4.rotation(pose)
    t.scale = Matrix4x4.scale(pose)

    return t
end

function SteamVRFlowCallbacks.tracking_space_size(t)
    if not SteamVR then return t end

    t.width, t.depth = SteamVR.tracking_space_size()

    return t
end

function SteamVRFlowCallbacks.tracking_space_rectangle(t)
    if not SteamVR then return t end

    if is_world(t.space) then
        t.corner1, t.corner2, t.corner3, t.corner4 = SteamVR.tracking_space_world_rectangle()
    else
        t.corner1, t.corner2, t.corner3, t.corner4 = SteamVR.tracking_space_local_rectangle()
    end

    return t
end

function SteamVRFlowCallbacks.fade_in(t)
    if not SteamVR then return t end

    SteamVR.fade_to_color(Color(255, t.color[1], t.color[2], t.color[3]), t.seconds)
end

function SteamVRFlowCallbacks.fade_out(t)
    if not SteamVR then return t end

    SteamVR.fade_to_color(Color(0, t.color[1], t.color[2], t.color[3]), t.seconds)
end

function SteamVRFlowCallbacks.caculateRotationOffset(t)
    local inverse_parent_rot = Quaternion.inverse(t.parent_rotation)
    --local unit_rot = Unit.world_rotation(unit,unit_node)
    t.offset_rotation = Quaternion.multiply(inverse_parent_rot, t.child_rotation)
    return t
end

function SteamVRFlowCallbacks.caculatePositionOffset(t)
    local parent_node = Unit.node(t.parent_unit, t.parent_object)
    local child_node = Unit.node(t.child_unit, t.child_object)
    local parent_transform = Matrix4x4.inverse(Unit.world_pose(t.parent_unit, parent_node))
    local unit_pos = Unit.world_position(t.child_unit, child_node)
    t.position = Matrix4x4.transform(parent_transform, unit_pos)
    return t
end

function SteamVRFlowCallbacks.set_kinematic(t)
    local actor = t.Actor
    local bool = t.Bool
    if actor ~= nil then
        stingray.Actor.set_kinematic(actor, bool)
    end
end

function get_mesh_by_name_or_all(unit, mesh_name)
    local meshes = {}
    if mesh_name and Unit.has_mesh(unit, mesh_name) then
        table.insert(meshes, Unit.mesh(unit, mesh_name))
    elseif mesh_name == nil or mesh_name == "" then
        local num_meshes = Unit.num_meshes(unit)
        for i=1, num_meshes do
            local mesh = Unit.mesh(unit, i)
            table.insert(meshes, mesh)
        end
    end
    return meshes
end

function get_material_by_slot_or_all(mesh, slot_name)
    local materials = {}
    if slot_name and Mesh.has_material(mesh, slot_name) then
        table.insert(materials, Mesh.material(mesh, slot_name))
    elseif slot_name == nil or slot_name == "" then
        local num_materials = Mesh.num_materials(mesh)
        for i=1, num_materials do
            local material = Mesh.material(mesh, i)
            table.insert(materials, material)
        end
    end
    return materials
end

function SteamVRFlowCallbacks.setUnitHighlight(t)
    -- the selection_mask for a unit or mesh should usually not be 0.
    -- if it is zero, it means no outlines will be rendered for that mesh at all.
    -- it should loop between 1-255, never go above 255
    -- what matters is that the mask is fairly unique between meshes/units
    -- if 2 meshes are both selected and overlapping each other and they both have the same mask,
    -- their outlines will merge as if they are one mesh.
    -- nothing bad will happen if two units by pure chance get the same mask
    -- value other then what is mentioned above.
    _selection_mask_counter = _selection_mask_counter + 1
    local _selection_mask = t.Mask ~= nil and t.Mask % 255 or _selection_mask_counter % 255 + 1

    -- You can supply both a selection color RGB as well as an alpha.
    -- The alpha value will render a highlight over the object with the alpha amount
    local input_color = t.Color or Vector3(67, 255, 163)
    local alpha = t.Alpha or 16

    local unit = t.Unit or nil
    local value = t.Enable

    if value == nil then
        value = true
    end

    if unit then
        local color = Color(alpha, input_color[1], input_color[2], input_color[3])
        local meshes = get_mesh_by_name_or_all(unit, t.Mesh)
        if next(meshes) == nil then
            print_warning("Warning: setUnitHighlight: No mesh found for "..Unit.debug_name(unit).." named "..tostring(t.Mesh))
            return
        end
        local _match_found = false
        for i=1, #meshes do
            local mesh = meshes[i]
            local materials = get_material_by_slot_or_all(mesh, t.MaterialSlot)
            if next(materials) == nil and t.MaterialSlot and t.Mesh then
                print_warning("Warning: setUnitHighlight: No material slot found for "..Unit.debug_name(unit).." named "..tostring(t.MaterialSlot).." for mesh " .. tostring(t.Mesh))
                return
            end

            for j=1, #materials do
                _match_found = true
                local material = materials[j]
                Material.set_color(material, "dev_selection_color", color)
                Material.set_scalar(material, "dev_selection_mask", (_selection_mask/255))
                Material.set_shader_pass_flag(material, "dev_selection", value)
            end
        end
        if not _match_found then
            print_warning("Warning: setUnitHighlight: No material slot found for "..Unit.debug_name(unit).." named "..tostring(t.MaterialSlot))
        end
    end
end

function SteamVRFlowCallbacks.look_at(t)
    local unit = t.unit
    local pos = t.look_at_position
    local up = t.up_vector
    local index = Unit.node(unit, t.node_name)
    local rot = Quaternion.look(pos, up)
    local x, y, z = Quaternion.to_euler_angles_xyz(rot)
    local bool = t.constrain_x_y
    if bool ~= nil and t.constrain_x_y == true then
        x = 0
        y = 0
        Unit.set_local_rotation(unit, index, Quaternion.from_euler_angles_xyz(x, y, z))
    else
        Unit.set_local_rotation(unit, index, Quaternion.from_euler_angles_xyz(x, y, z))
    end
end

function SteamVRFlowCallbacks.link_node_to_tracker(t)
    if not SteamVR then return t end

    local node  = Unit.node(t.unit, t.node_name)
    local world = stingray.Application.flow_callback_context_world()

	local link_pose
    if t.link_to == "HMD" then
        SteamVR.link_node_to_tracker(t.unit, node, world, SteamVR.LINK_HMD)

        local hmd, _, _ = SteamVR.hmd_world_pose()
        link_pose = hmd
    elseif eye_map[t.link_to] ~= nil then
        local eye = eye_map[t.link_to]
        SteamVR.link_node_to_tracker(t.unit, node, world, SteamVR.LINK_HMD, eye)

        local _, left, right = SteamVR.hmd_world_pose()
        link_pose = eye == SteamVR.EYE_LEFT and left or right
    else
        SteamVR.link_node_to_tracker(t.unit, node, world, SteamVR.LINK_CONTROLLER, controller_map[t.link_to])
        link_pose = SteamVR.controller_world_pose(controller_map[t.link_to])
    end


    if t.preserve_world_pose then
        -- Calculate position offset
        local inv_link_pose = Matrix4x4.inverse(link_pose)
        local unit_pos = Unit.world_position(t.unit, node)
        local offset_pos = Matrix4x4.transform(inv_link_pose, unit_pos)
        --Calculate rotation offset
        local inv_link_rot = Quaternion.inverse(Matrix4x4.rotation(link_pose))
        local offset_rot = Quaternion.multiply(inv_link_rot, Unit.world_rotation(t.unit, node))
        --Set unit local position to retain offset from tracker
        Unit.set_local_position(t.unit, node, offset_pos)
        Unit.set_local_rotation(t.unit, node, offset_rot)
    end

end

function SteamVRFlowCallbacks.unlink_node_from_tracker(t)
    if not SteamVR then return t end

    SteamVR.unlink_node_from_tracker(t.unit, stingray.Unit.node(t.unit, t.node_name))
end

function SteamVRFlowCallbacks.clear_links(t)
    if not SteamVR then return t end

    SteamVR.clear_all_tracker_node_links()
end
