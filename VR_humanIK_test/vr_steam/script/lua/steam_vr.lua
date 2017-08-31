require 'core/appkit/lua/class'
require 'core/appkit/lua/unit_link'

SteamVRSystem = SteamVRSystem or Appkit.class(SteamVRSystem)

local Application        = stingray.Application
local Window             = stingray.Window
local Viewport           = stingray.Viewport
local World              = stingray.World
local Unit               = stingray.Unit
local Vector3            = stingray.Vector3
local Quaternion         = stingray.Quaternion
local Matrix4x4          = stingray.Matrix4x4
local Camera             = stingray.Camera
local ShadingEnvironment = stingray.ShadingEnvironment
local SteamVR            = stingray.SteamVR

function SteamVRSystem:init(world)
	if not SteamVR then return end

	self._world          = world
	self._enabled        = false
	self._is_initialized = false
end

function SteamVRSystem:initialize(near, far, hmd_rt, hud_rt)
	if not SteamVR then return end
	if not self then return end

	-- Create main vr camera
	self._vr_main_camera_unit = World.spawn_unit(self._world, "core/units/camera")
	self._vr_main_camera = Unit.camera(self._vr_main_camera_unit, "camera")
	Camera.set_near_range(self._vr_main_camera, near)
	Camera.set_far_range(self._vr_main_camera, far)

	-- Initialize VR system
	self._is_initialized = SteamVR.initialize(hmd_rt, self._vr_main_camera, self._world)

	-- Bail if there was an error on initialization
	if not self._is_initialized then
		World.destroy_unit(self._world, self._vr_main_camera_unit)
		return
	end

	-- Create other vr cameras for blit and hud passes
	self._vr_blit_camera_unit = World.spawn_unit(self._world, "core/units/camera")
	self._vr_hud_camera_unit = World.spawn_unit(self._world, "core/units/camera")
	self._vr_blit_camera = Unit.camera(self._vr_blit_camera_unit, "camera")
	self._vr_hud_camera = Unit.camera(self._vr_hud_camera_unit, "camera")
	
	-- Create viewports
	self._vr_viewport_main = Application.create_viewport(self._world, "vr_main" )
	self._vr_viewport_blit = Application.create_viewport(self._world, "vr_blit" )
	self._vr_viewport_hud  = Application.create_viewport(self._world, "vr_hud" )

	-- Create VR window
	local size_x, size_y = Application.render_setting("vr_hmd_resolution")
	local scale          = Application.render_setting("vr_target_scale")

	-- When running in SLI mode, each eye is processed by each GPU and thus only half the size of the full width is needed.
	if Application.render_setting("nv_vr_sli_enabled") then
		size_x = size_x / 2
	end

  self._vr_window      = Window.open{visible = false, width = (size_x * scale), height = (size_y * scale), frameless = true}

	-- Create VR controllers
	self._controller1_unit = World.spawn_unit(self._world, "vr_steam/models/controller/vr_controller_vive_1_5")
	Unit.set_data(self._controller1_unit, "controller_index", "1")
	Unit.flow_event(self._controller1_unit, "link_controller")
	
	self._controller2_unit = World.spawn_unit(self._world, "vr_steam/models/controller/vr_controller_vive_1_5")
	Unit.set_data(self._controller2_unit, "controller_index", "2")
	Unit.flow_event(self._controller2_unit, "link_controller")

	-- spawn collision for hmd and attach to hmd -- for use in triggers as a "character"
	self.hmd_collision = World.spawn_unit(self._world, "vr_steam/models/hmd/hmd_char_collision", pose)
	SteamVR.link_node_to_tracker(self.hmd_collision, 1, self._world, SteamVR.LINK_HMD)

	-- Setup SteamVR HUD layer 0.5m away from HMD
	SteamVR.create_layer("hud_layer", hud_rt);
	SteamVR.set_layer_pose(
	    "hud_layer",
	    Matrix4x4.from_quaternion_position(Quaternion.identity(), Vector3(0, 0.5, 0)),
	    true
	)

	Camera.set_mode(self._vr_blit_camera, Camera.STEREO)
	Camera.set_vertical_fov(self._vr_blit_camera, Camera.vertical_fov(self._vr_blit_camera, 1), 2);

	Window.set_focus()
end

--[[
	Enable VR rendering
]]--
function SteamVRSystem:enable()
	if not SteamVR then return end
	if not self or not self._is_initialized then return end

	self._enabled = true
	Application.set_render_setting("vr_enabled", "true")
	Application.set_render_setting("vr_mask_enabled", "true")
end

--[[
	Disable VR rendering
--]]
function SteamVRSystem:disable()
	if not SteamVR then return end
	if not self or not self._is_initialized then return end

	self._enabled = false
	Application.set_render_setting("vr_enabled", "false")
	Application.set_render_setting("vr_mask_enabled", "false")
end

--[[
	Returns if VR rendering currently enabled
]]--
function SteamVRSystem:is_enabled()
	if not SteamVR then return end
	if not self then return false end

	return self._enabled
end

--[[
	Returns if VR System is initialzed
]]--
function SteamVRSystem:is_initialized()
	if not SteamVR then return end
	if not self then return false end

	return self._is_initialized
end

--[[
	Returns if HMD is currently being tracked
]]--
function SteamVRSystem:is_hmd_tracked()
	if not SteamVR then return false end
	if not self or not self._is_initialized then return false end

	return SteamVR.is_hmd_tracked()
end

--[[
	Returns if specified controller is currently being tracked 
]]--
function SteamVRSystem:is_controller_tracked(index)
	if not SteamVR then return false end
	if not self or not self._is_initialized then return false end

	return SteamVR.is_controller_tracked(index)
end

--[[
	Shutdown VR system
--]]
function SteamVRSystem:shutdown()
	if not SteamVR then return end
	if not self then return end

	if self._vr_window then
		Window.close(self._vr_window)
		self._vr_window = nil
	end

	if not self._is_initialized then return end

	SteamVRSystem.disable(self)
	SteamVR.shutdown()

	World.destroy_unit(self._world, self._vr_main_camera_unit)
	World.destroy_unit(self._world, self._vr_blit_camera_unit)
	World.destroy_unit(self._world, self._vr_hud_camera_unit)

	Application.destroy_viewport(self._world, self._vr_viewport_main)
	Application.destroy_viewport(self._world, self._vr_viewport_blit)
	Application.destroy_viewport(self._world, self._vr_viewport_hud)

	World.destroy_unit(self._world, self._controller1_unit)
	World.destroy_unit(self._world, self._controller2_unit)

	self._is_initialized = false
end

--[[
	Returns HMD forward vector and local eye poses
--]]
function SteamVRSystem:hmd_local_pose()
	if not SteamVR then return nil end
	if not self or not self._is_initialized then return nil end

	head, left, right = SteamVR.hmd_local_pose()
	return {
		forward   = Matrix4x4.forward(head),
		left_eye  = left,
		right_eye = right
	}
end

--[[
	Returns HMD forward vector and world eye poses
--]]
function SteamVRSystem:hmd_world_pose()
	if not SteamVR then return nil end
	if not self or not self._is_initialized then return nil end

	head, left, right = SteamVR.hmd_world_pose()
	return {
		forward   = Matrix4x4.forward(head),
		left_eye  = left,
		right_eye = right
	}
end

--[[
	Returns the specified controller local pose.
--]]
function SteamVRSystem:controller_local_pose(index)
	if not SteamVR then return nil end
	if not self or not self._is_initialized then return nil end

	return SteamVR.controller_local_pose(index)
end

--[[
	Returns the specified controller world pose.
--]]
function SteamVRSystem:controller_world_pose(index)
	if not SteamVR then return nil end
	if not self or not self._is_initialized then return nil end

	return SteamVR.controller_world_pose(index)
end

--[[
	Returns true/false if specified button is pressed
--]]
function SteamVRSystem:controller_pressed(index, button)
	if not SteamVR then return false end
	if not self or not self._is_initialized then return false end
	
	return SteamVR.controller_pressed(index, button)
end

--[[
	Returns true/false if specified button is held
--]]
function SteamVRSystem:controller_held(index, button)
	if not SteamVR then return false end
	if not self or not self._is_initialized then return false end
	
	return SteamVR.controller_held(index, button)
end

--[[
	Returns true/false if specified button is released
--]]
function SteamVRSystem:controller_released(index, button)
	if not SteamVR then return false end
	if not self or not self._is_initialized then return false end

	return SteamVR.controller_released(index, button)
end

--[[
	Returns true/false if specified button is touched
--]]
function SteamVRSystem:controller_touched(index, button)
	if not SteamVR then return false end
	if not self or not self._is_initialized then return false end

	return SteamVR.controller_touched(index, button)
end

--[[
	Returns true/false if specified button is untouched
--]]
function SteamVRSystem:controller_untouched(index, button)
	if not SteamVR then return false end
	if not self or not self._is_initialized then return false end

    return SteamVR.controller_untouched(index, button)
end

--[[
	Get controller button analog values
--]]
function SteamVRSystem:controller_value(index, button)
	if not SteamVR then return nil end
	if not self or not self._is_initialized then return nil end

	local v1, v2 = SteamVR.controller_value(index, button)
	return {
	    x = v1,
	    y = v2
	}
end

--[[
	Trigger feedback on the specified controller
--]]
function SteamVRSystem:trigger_controller_feedback(index, seconds)
	if not SteamVR then return end
	if not self or not self._is_initialized then return end

	SteamVR.controller_pulse(index, seconds)
end

--[[
	Render in VR mode
]]--
function SteamVRSystem:render(shading_environment)
	if not SteamVR then return end
	if not self or not self._enabled then return end

	-- Render HUD
	Application.render_world(self._world, self._vr_hud_camera, self._vr_viewport_hud, shading_environment, self._vr_window)

	-- Render world in instanced stereo
	Application.render_world(self._world, self._vr_main_camera, self._vr_viewport_main, shading_environment, self._vr_window)
	
	-- Blit result to application window
	Application.render_world(self._world, self._vr_blit_camera, self._vr_viewport_blit, shading_environment)
end

return SteamVRSystem
