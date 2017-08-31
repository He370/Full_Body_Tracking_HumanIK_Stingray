require 'core/appkit/lua/util'
require 'core/appkit/lua/class'

SteamVRInputMapper = SteamVRInputMapper or Appkit.class(SteamVRInputMapper)

local World        = stingray.World
local Unit 		   = stingray.Unit
local Keyboard     = stingray.Keyboard
local Vector3      = stingray.Vector3
local Vector3Box   = stingray.Vector3Box
local Matrix4x4    = stingray.Matrix4x4
local Matrix4x4Box = stingray.Matrix4x4Box
local Quaternion   = stingray.Quaternion
local SteamVR      = stingray.SteamVR
local LineObject   = stingray.LineObject
local Color        = stingray.Color

require 'vr_steam/script/lua/steam_vr'
require 'vr_steam/script/lua/steam_vr_flow_callbacks'
require 'script/lua/flow_callbacks'

local degrees_90 = 0.5 * math.pi

function SteamVRInputMapper:init(vr_system, world)
	self.input = {
		pan       = Vector3Box(Vector3.zero()),
		move      = Vector3Box(Vector3.zero()),
		forward   = Vector3Box(Vector3.zero()),
		left_eye  = Matrix4x4Box(Matrix4x4.identity()),
		right_eye = Matrix4x4Box(Matrix4x4.identity()),
	}
	self.vr_system = vr_system
	self.world     = world
end

function SteamVRInputMapper:get_motion_input()
	local input = self.input
	return {move = input.move:unbox(), pan = input.pan:unbox()}
end

function SteamVRInputMapper:get_forward()
	return self.input.forward:unbox()
end

function SteamVRInputMapper:get_poses()
	local input = self.input
	return {
		left_eye  = input.left_eye:unbox(),
		right_eye = input.right_eye:unbox()
	}
end

local function update_input(self)
	if not Appkit.Util.is_pc() then return end

	local move  = Vector3.zero()
	local pan   = Vector3.zero()
	local input = self.input

	if not SteamVRSystem.is_enabled(self.vr_system) then
		-- If VR disabled use mouse and keyboard
		pan = stingray.Mouse.axis(stingray.Mouse.axis_id("mouse"))
		move = Vector3(
			Keyboard.button(Keyboard.button_id("d")) - Keyboard.button(Keyboard.button_id("a")),
			Keyboard.button(Keyboard.button_id("w")) - Keyboard.button(Keyboard.button_id("s")),
			0
			)
	else
		-- Otherwise, use hmd forward vector and controller pad
		local hmd_pose = SteamVRSystem.hmd_world_pose(self.vr_system)
		local forward_without_pitch = Vector3(hmd_pose.forward.x, hmd_pose.forward.y, 0)

		-- Move character using keyboard
		move = Vector3.multiply(
			forward_without_pitch,
			Keyboard.button(Keyboard.button_id("w")) - Keyboard.button(Keyboard.button_id("s"))
			)

		local strafe = Keyboard.button(Keyboard.button_id("a")) - Keyboard.button(Keyboard.button_id("d"))
		if strafe ~= 0 then
			local rotated_forward = Quaternion.rotate(
				Quaternion.axis_angle(Vector3(0, 0, 1), degrees_90 * strafe),
				forward_without_pitch
				)
			move = move + rotated_forward
		end

		-- Store Hmd pose data for later use
		input.forward:store(hmd_pose.forward)
		input.left_eye:store(hmd_pose.left_eye)
		input.right_eye:store(hmd_pose.right_eye)
	end

	input.move:store(Vector3.normalize(move))
	input.pan:store(pan)
end

-- Updates the cached input state
function SteamVRInputMapper:update(dt)
	update_input(self)
end

return SteamVRInputMapper
