require 'core/appkit/lua/class'
require 'core/appkit/lua/app'

local SimpleProject = require 'core/appkit/lua/simple_project'
local ComponentManager = require 'core/appkit/lua/component_manager'
local UnitController = require 'core/appkit/lua/unit_controller'
local UnitLink = require 'core/appkit/lua/unit_link'

local Matrix4x4 = stingray.Matrix4x4
local HumanIK = stingray.HumanIK
local Quaternion = stingray.Quaternion

HIK_VR = Appkit.class(HIK_VR)

function HIK_VR:get_poses()
    self.start_point_pose = stingray.Unit.local_pose(self.start_point,1)
	self.hmd_pose = stingray.SteamVR.hmd_local_pose()
	self.left_controller_pose = stingray.SteamVR.controller_local_pose(0)
	self.right_controller_pose = stingray.SteamVR.controller_local_pose(1)
	self.mid_tracker_pose = stingray.SteamVR.generic_tracker_local_pose(1)
	self.left_tracker_pose = stingray.SteamVR.generic_tracker_local_pose(0)
	self.right_tracker_pose = stingray.SteamVR.generic_tracker_local_pose(2)
end

function HIK_VR:init(world)
    self.world = world
    self.start_point = stingray.World.unit_by_name(self.world,"player_start")
    self.scale = 1.0
    self.HIK_enable = false
    self.HIK_debug_enable = true
    
end

function HIK_VR:enable_character(m_name,scale)
    self.character_unit = stingray.World.unit_by_name(SimpleProject.world,m_name)
    self.scale = scale
end

function HIK_VR:enable_disable_debug()
    if stingray.SteamVR.controller_pressed(0,stingray.SteamVR.BUTTON_TRIGGER) then
        if self.HIK_debug_enable == true then
            self.HIK_debug_enable = false
        else
            self.HIK_debug_enable = true
        end
    end
end

function HIK_VR:enable_disable_HIK()
    if stingray.SteamVR.controller_pressed(1,stingray.SteamVR.BUTTON_TRIGGER) then
        if self.HIK_enable == true then
            self.HIK_enable = false
        else
            self.HIK_enable = true
        end
    end
end

function HIK_VR:get_euler_angles(quaternion)
    local pitch,roll,yaw = stingray.Quaternion.to_euler_angles_xyz(quaternion)
    --return stingray.Vector3(pitch,roll,yaw)
    return stingray.Vector3(pitch,roll,yaw)
end

function HIK_VR:HIK_debug()
    
    local unit_pose = stingray.Unit.local_pose(self.character_unit,1)
    local test_head = stingray.World.unit_by_name(SimpleProject.world,"test_sphere_red")
	local test_hand_l = stingray.World.unit_by_name(SimpleProject.world,"test_cube_green")
	local test_hand_r = stingray.World.unit_by_name(SimpleProject.world,"test_cube_blue")
	local test_hip = stingray.World.unit_by_name(SimpleProject.world,"test_cone")
	local test_foot_l = stingray.World.unit_by_name(SimpleProject.world,"test_cone_green")
	local test_foot_r = stingray.World.unit_by_name(SimpleProject.world,"test_cone_blue") 
	
	if self.HIK_debug_enable == false then
	    stingray.Unit.set_unit_visibility(test_head,false)
	    stingray.Unit.set_unit_visibility(test_hand_l,false)
	    stingray.Unit.set_unit_visibility(test_hand_r,false)
	    stingray.Unit.set_unit_visibility(test_hip,false)
	    stingray.Unit.set_unit_visibility(test_foot_l,false)
	    stingray.Unit.set_unit_visibility(test_foot_r,false)
	    return
	else
	    stingray.Unit.set_unit_visibility(test_head,true)
	    stingray.Unit.set_unit_visibility(test_hand_l,true)
	    stingray.Unit.set_unit_visibility(test_hand_r,true)
	    stingray.Unit.set_unit_visibility(test_hip,true)
	    stingray.Unit.set_unit_visibility(test_foot_l,true)
	    stingray.Unit.set_unit_visibility(test_foot_r,true)
	end
	
	stingray.Unit.set_local_pose(test_hand_l,1,Matrix4x4.multiply(self.left_controller_pose,unit_pose))
	stingray.Unit.set_local_pose(test_hand_r,1,Matrix4x4.multiply(self.right_controller_pose,unit_pose))
	stingray.Unit.set_local_pose(test_head,1,Matrix4x4.multiply(self.hmd_pose,unit_pose))
	stingray.Unit.set_local_pose(test_hip,1,Matrix4x4.multiply(self.mid_tracker_pose,unit_pose))
	stingray.Unit.set_local_pose(test_foot_l,1,Matrix4x4.multiply(self.left_tracker_pose,unit_pose))
	stingray.Unit.set_local_pose(test_foot_r,1,Matrix4x4.multiply(self.right_tracker_pose,unit_pose))
	
	stingray.Unit.set_local_scale(test_head,1,stingray.Vector3(0.1,0.1,0.1))
	stingray.Unit.set_local_scale(test_hand_l,1,stingray.Vector3(0.1,0.1,0.1))
	stingray.Unit.set_local_scale(test_hand_r,1,stingray.Vector3(0.1,0.1,0.1))
	stingray.Unit.set_local_scale(test_hip,1,stingray.Vector3(0.1,0.1,0.1))
	stingray.Unit.set_local_scale(test_foot_l,1,stingray.Vector3(0.1,0.1,0.1))
	stingray.Unit.set_local_scale(test_foot_r,1,stingray.Vector3(0.1,0.1,0.1))
end

function HIK_VR:update()
    self:enable_disable_debug()
    self:enable_disable_HIK()
    self:get_poses()
    
    if self.character_unit == nil then
        return
    end
    
    local character_pose = stingray.Unit.local_pose(self.character_unit,1)
    
    local position_head = Matrix4x4.translation(Matrix4x4.multiply(self.hmd_pose,character_pose))
    local position_hand_l = Matrix4x4.translation(Matrix4x4.multiply(self.left_controller_pose,character_pose))
    local position_hand_r = Matrix4x4.translation(Matrix4x4.multiply(self.right_controller_pose,character_pose))
    local position_hip = Matrix4x4.translation(Matrix4x4.multiply(self.mid_tracker_pose,character_pose)) 
    local position_foot_l = Matrix4x4.translation(Matrix4x4.multiply(self.left_tracker_pose,character_pose)) 
    local position_foot_r = Matrix4x4.translation(Matrix4x4.multiply(self.right_tracker_pose,character_pose))

    local rotation_head = Quaternion.inverse(Matrix4x4.rotation(self.hmd_pose))
    local rotation_hand_l = Matrix4x4.rotation(Matrix4x4.multiply(self.left_controller_pose,character_pose))
    local rotation_hand_r = Matrix4x4.rotation(Matrix4x4.multiply(self.right_controller_pose,character_pose))
    
    local _,_,yaw1 = Quaternion.to_euler_angles_xyz(Matrix4x4.rotation(self.start_point_pose))
    local _,_,yaw2 = Quaternion.to_euler_angles_xyz(Matrix4x4.rotation(character_pose))
    
    if yaw2>=0 then
        yaw2 = 180 - yaw2
    end
    
    local q2 = Quaternion.axis_angle(stingray.Vector3(1,0,0),-math.pi/2)
    local q1 = Quaternion.axis_angle(stingray.Vector3(0,1,0),yaw2/180*math.pi)

    rotation_head = Quaternion.multiply(rotation_head,q1) 
    rotation_head = Quaternion.multiply(rotation_head,q2)

    rotation_hand_l = Quaternion.multiply(rotation_hand_l,q2)
    rotation_hand_l = Quaternion.multiply(rotation_hand_l,q1)
    
    rotation_hand_r = Quaternion.multiply(rotation_hand_r,q2)
    rotation_hand_r = Quaternion.multiply(rotation_hand_r,q1)
    
    rotation_head = Matrix4x4.rotation(Matrix4x4.inverse(self.hmd_pose))
    local rotation_hip = Matrix4x4.rotation(Matrix4x4.inverse(self.mid_tracker_pose))
    rotation_hand_l = Matrix4x4.rotation(Matrix4x4.multiply(self.left_controller_pose,character_pose))
    rotation_hand_r = Matrix4x4.rotation(Matrix4x4.multiply(self.right_controller_pose,character_pose))
    local rotation_foot_l = Matrix4x4.rotation(Matrix4x4.inverse(self.left_tracker_pose))
    local rotation_foot_r =Matrix4x4.rotation(Matrix4x4.inverse(self.right_tracker_pose))
    
    q1 = Quaternion.axis_angle(stingray.Vector3(0,1,0),math.pi)
    q2 = Quaternion.axis_angle(stingray.Vector3(1,0,0),math.pi/2)
    rotation_head = Quaternion.multiply(rotation_head,q2) 
    rotation_head = Quaternion.multiply(rotation_head,q1)
    
    rotation_hip = Quaternion.multiply(rotation_hip,q2) 
    rotation_hip = Quaternion.multiply(rotation_hip,q1)
    
    rotation_foot_l = Quaternion.multiply(rotation_foot_l,q2) 
    rotation_foot_l = Quaternion.multiply(rotation_foot_l,q1)
    
    rotation_foot_r = Quaternion.multiply(rotation_foot_r,q2) 
    rotation_foot_r = Quaternion.multiply(rotation_foot_r,q1)
    
    self:HIK_debug()
    
    if self.HIK_enable == true then
        HumanIK.character_pop_all(self.character_unit)
        
        local e_head = 15
        local e_hand_l = 3
        local e_hand_r = 4
        local e_hip = 0
        local e_foot_l = 11
        local e_foot_r = 12
        local e_ankle_l = 1
        local e_ankle_r = 2
        
        local e_knee_l = 5
        local e_knee_r = 6
        local e_elbow = 7
        local e_elbow = 8
        
        --stingray.HumanIK.character_push_fingers_control(self.character_unit,1,1,0,0,1,0,0,1,0.5,1,0,-1)      
        
        HumanIK.character_push_reach_orientation(self.character_unit,e_head,-self:get_euler_angles(rotation_head),1,1,0,-1)
        HumanIK.character_push_reach_orientation(self.character_unit,e_hip,-self:get_euler_angles(rotation_hip),1,1,0,-1)
        --HumanIK.character_push_reach_orientation(self.character_unit,e_ankle_l,-Project.get_euler_angles(rotation_test_foot_l),1,1,0,-1)
        --HumanIK.character_push_reach_orientation(self.character_unit,e_ankle_r,-Project.get_euler_angles(rotation_test_foot_r),1,1,0,-1)
        --HumanIK.character_push_reach_orientation(self.character_unit,e_hand_l,-Project.get_euler_angles(rotation_test_head),1,1,0,-1)
        --HumanIK.character_push_reach_orientation(self.character_unit,e_hand_r,-Project.get_euler_angles(rotation_test_head),1,1,0,-1)
        --HumanIK.character_push_reach_orientation(self.character_unit,4,(-1)*Project.get_euler_angles(rotation_test_hand_r),1,1,0,-1)
        
        HumanIK.character_push_reach_position(self.character_unit,e_head,position_head,1,1,0,-1)
        HumanIK.character_push_reach_position(self.character_unit,e_hand_l,position_hand_l,1,1,0,-1)
        HumanIK.character_push_reach_position(self.character_unit,e_hand_r,position_hand_r,1,1,0,-1)
        HumanIK.character_push_reach_position(self.character_unit,e_hip,position_hip,1,1,0,-1)
        HumanIK.character_push_reach_position(self.character_unit,e_foot_l,position_foot_l,1,1,0,-1)
        HumanIK.character_push_reach_position(self.character_unit,e_foot_r,position_foot_r,1,1,0,-1)
        
        HumanIK.character_push_pull(self.character_unit,e_head,0.8,0,-1)
        HumanIK.character_push_pull(self.character_unit,e_hip,0.4,0,-1)
        --HumanIK.character_push_pull(self.character_unit,e_hand_l,0.2,0,-1)
        --HumanIK.character_push_pull(self.character_unit,e_hand_r,0.2,0,-1)
        --HumanIK.character_push_pull(self.character_unit,e_foot_l,0.2,0,-1)
        --HumanIK.character_push_pull(self.character_unit,e_foot_r,0.2,0,-1)
        
        stingray.HumanIK.character_push_resist(self.character_unit,e_knee_l,0,0,-1)
        stingray.HumanIK.character_push_resist(self.character_unit,e_knee_r,0,0,-1)
        stingray.HumanIK.character_push_resist(self.character_unit,e_hip,0.5,0,-1)
        stingray.HumanIK.character_push_resist(self.character_unit,e_head,0.2,0,-1)
        stingray.HumanIK.character_push_resist(self.character_unit,e_elbow,0,0,-1)
        stingray.HumanIK.character_push_resist(self.character_unit,e_elbow,0,0,-1)

        --HumanIK.character_push_pin(self.character_unit,0,1,1,0,-1)

        HumanIK.character_push_solve(self.character_unit)
    end

end

return HIK_VR