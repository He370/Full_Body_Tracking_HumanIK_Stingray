require 'core/appkit/lua/class'
require 'core/appkit/lua/app'
local SimpleProject = require 'core/appkit/lua/simple_project'
local ComponentManager = require 'core/appkit/lua/component_manager'
local UnitController = require 'core/appkit/lua/unit_controller'
local UnitLink = require 'core/appkit/lua/unit_link'
local CameraWrapper = require 'core/appkit/lua/camera_wrapper'

Project.Player = Appkit.class(Project.Player)
local Player = Project.Player -- cache off for readability and speed

-- cache off for readability and speed
local Keyboard = stingray.Keyboard
local Vector3 = stingray.Vector3
local Quaternion = stingray.Quaternion
local Matrix4x4 = stingray.Matrix4x4
local Matrix4x4Box = stingray.Matrix4x4Box
local Unit = stingray.Unit
local World = stingray.World
local Level = stingray.Level

local free_cam_move_speed  = stingray.Vector3Box(Vector3(1,1,1))
local free_cam_yaw_speed   = 0.085
local free_cam_pitch_speed = 0.075

-- Player Spawn function
function Player.spawn_player(level, view_position, view_rotation, custom_input_mapper)
	if not level then
		print "ERROR: No current level - cannot spawn"
		return
	end

	local player = Player()
	if custom_input_mapper then
		player.input_mapper = custom_input_mapper
	end

	view_position = view_position or Vector3(0, 0, 0)
	view_rotation = view_rotation or Quaternion.identity()

	local world = Level.world(level)
	local unit = SimpleProject.camera_unit

	local player_camera = player.player_camera
	player_camera.unit = unit

	-- Camera
	local camera_wrapper = Appkit.CameraWrapper(player_camera, unit, 1)
	camera_wrapper:set_local_position(view_position)
	camera_wrapper:set_local_rotation(view_rotation)
	camera_wrapper:enable()

	-- Add camera input movement. Starts enabled.
	local controller = UnitController(player_camera, unit, player.input_mapper)
	controller:set_move_speed(free_cam_move_speed:unbox())
	controller:set_yaw_speed(free_cam_yaw_speed)
	controller:set_pitch_speed(free_cam_pitch_speed)

	-- Give free cam ability to attached to character for walking mode. Starts disabled.
	local unit_link = UnitLink(player_camera, level, unit, 1, nil, 1, false)

	-- allow appkit to manage update and shutdown
	Appkit.manage_level_object(level, Player, player)
end

function Player:init()
	self.player_camera = {}
	self.land_character = {}
	self.is_freecam_mode = true
	self.saved_freecam_pose = Matrix4x4Box(Matrix4x4.identity())
	self.input_mapper = Appkit.input_mapper
end

function Player.shutdown(self, level)
	local player_camera = self.player_camera
	if player_camera then
		local world = SimpleProject.world
		ComponentManager.remove_components(player_camera)
		player_camera.unit = nil
	end
end

function Player.update(self, dt)
end

return Player
