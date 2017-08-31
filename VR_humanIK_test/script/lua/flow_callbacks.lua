ProjectFlowCallbacks = ProjectFlowCallbacks or {}

-- Example custom project flow node callback. Prints a message.
-- The parameter t contains the node inputs, and node outputs can
-- be set on t. See documentation for details.
local Unit = stingray.Unit
local Matrix4x4 = stingray.Matrix4x4
local Quaternion = stingray.Quaternion
local Vector3 = stingray.Vector3

function ProjectFlowCallbacks.example(t)
	local message = t.Text or ""
	print("Example Node Message: " .. message)
end

function ProjectFlowCallbacks.update_look_at_constraint(t)
    local unit = t.unit

	if not Unit.has_data(unit, "saved_rotation") then
		print ("no saved_rotation")
		return
	end
	if not Unit.has_data(unit, "grab_location") then
		print ("no grab_location")
		return
	end

	local saved_rotation = Unit.get_data(unit, "saved_rotation")
	local grab_location = Unit.get_data(unit, "grab_location")

	-- Rotate around this up axis
	local up_axis = Vector3(0, 1, 0)
    
	local target_unit = unit
    local world_target_pos = t.world_look_at_position
	local node_to_rotate = t.node_to_rotate
	local rotate_id = Unit.node(unit, node_to_rotate)
    local parent = Unit.scene_graph_parent(unit, rotate_id)
    local parent_pose = Unit.world_pose(unit, parent)
    local inverse_parent_pose = Matrix4x4.inverse(parent_pose)

    local local_target_pos = Matrix4x4.transform(inverse_parent_pose, world_target_pos)
    local target_angle = math.atan2(local_target_pos.x, local_target_pos.z) / (2 * math.pi)

	local local_grab_pos = Matrix4x4.transform(inverse_parent_pose, grab_location)
	local grab_angle = math.atan2(local_grab_pos.x, local_grab_pos.z) / (2 * math.pi)

	local delta = target_angle - grab_angle
	delta = delta % 1.0
	if delta > 0.5 then delta = delta - 1 end

    local delta_rotation = Quaternion.axis_angle(up_axis, delta * (math.pi * 2))
	local rotation = Quaternion.multiply(saved_rotation, delta_rotation)
    Unit.set_local_rotation(unit, rotate_id, rotation)
end