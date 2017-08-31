-----------------------------------------------------------------------------------
-- This implementation uses the default SimpleProject and the Project extensions are
-- used to extend the SimpleProject behavior.

-- This is the global table name used by Appkit Basic project to extend behavior
Project = Project or {}

require 'script/lua/flow_callbacks'
require 'script/lua/project_utils'

Project.level_names = {
	default_level = "content/levels/vr_learning"
}
-- AppKit
SimpleProject = SimpleProject or require 'core/appkit/lua/simple_project'
InputMapper = InputMapper or require 'core/appkit/lua/input_mapper'

-- SteamVR
require 'vr_steam/script/lua/steam_vr'
require 'vr_steam/script/lua/steam_vr_input_mapper'
require 'vr_steam/script/lua/steam_vr_flow_callbacks'
require 'script/lua/humanIK_vr'

Project.vr_system       = Project.vr_system or nil
Project.vr_input_mapper = Project.vr_input_mapper or nil

-- Custom config for the basic project.
SimpleProject.config = {
	standalone_init_level_name = Project.level_names.default_level,
	camera_unit = "core/appkit/units/camera/camera",
	camera_index = 1,
	shading_environment = nil, -- Will override levels that have env set in editor.
	create_free_cam_player = true, -- Project will provide its own player.
	exit_standalone_with_esc_key = true
	-- Loading screen disabled until 2D gui VR is fully supported.
	-- loading_screen_materials = {"core/appkit/materials/loading_screen"},
	-- loading_screen_start_package = "loading_screen",
	-- loading_screen_end_package = "main",
	-- loading_screen_shading_env = "core/stingray_renderer/environments/midday/midday" -- Controls the shading environment used by default by the loading screen.
}

-- check to see if there are player starts in the level, if not return world 0
local function get_player_start_pose()
	local player_starts = stingray.World.units_by_resource(SimpleProject.world, "tools/player_start")
	if #player_starts > 0 then
		local index = stingray.Math.random(1, #player_starts)
		local pose = stingray.Unit.world_pose(player_starts[index], 1)
		local scale = stingray.Unit.local_scale(player_starts[index], 1)
		stingray.Matrix4x4.set_scale(pose, scale)
		return pose
	else
		return stingray.Matrix4x4.identity()
	end
end

-- SimpleProject function extensions
function Project.on_init_complete()
	local level_name = SimpleProject.level_name
	local managed_world = Appkit.managed_world

	-- Initialize VR
	Project.vr_system = SteamVRSystem(managed_world.world)
	SteamVRSystem.initialize(Project.vr_system, 0.01, 1000.0, "vr_target", "vr_hud")

	if SteamVRSystem.is_initialized(Project.vr_system) then
		if stingray.SteamVR then
			local pose = get_player_start_pose()
			stingray.SteamVR.set_tracking_space(stingray.Matrix4x4.translation(pose), stingray.Matrix4x4.rotation(pose), stingray.Matrix4x4.scale(pose))
		end
		Project.vr_input_mapper = SteamVRInputMapper(Project.vr_system, managed_world.world)

		SteamVRSystem.enable(Project.vr_system)
	else
		-- level_name is nil if this is an unsaved Test Level.
		local view_position = Appkit.get_editor_view_position() or stingray.Vector3(0, 0, 0)
		local view_rotation = Appkit.get_editor_view_rotation() or stingray.Quaternion.identity()
		local Player = require 'script/lua/player'
		Player.spawn_player(SimpleProject.level, view_position, view_rotation)
	end
	
	Project.humanIK_vr = HIK_VR(SimpleProject.world)
end

function Project.shutdown()
	SteamVRSystem.shutdown(Project.vr_system)
end

function Project.update(dt)
	if not SteamVRSystem.is_enabled(Project.vr_system) then
		return
	end

	-- Update VR input
	SteamVRInputMapper.update(Project.vr_input_mapper, dt)
	
	Project.humanIK_vr:enable_character("robot2",1.0)
	Project.humanIK_vr:update()
	
end

function Project.render()
	local managed_world = Appkit.managed_world
	if SteamVRSystem.is_enabled(Project.vr_system) and managed_world then
		SteamVRSystem.render(Project.vr_system, managed_world.shading_env)
		return true -- Override the regular SimpleProject rendering with VR rendering
	end
end

return Project
