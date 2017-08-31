require 'core/appkit/lua/class'
ProjectUtils = ProjectUtils or Appkit.class(ProjectUtils)

local EntityManager = stingray.EntityManager
local World         = stingray.World

function ProjectUtils.find_shading_env_entity_and_component(world, resource_name)
	local data_component_manager = EntityManager.data_component(world)
	local all_entity_handles     = World.entities(world)

	for _, entity_handle in ipairs(all_entity_handles) do
		local all_data_component_handles = {data_component_manager:instances(entity_handle)}
		
		for _, data_component_handle in ipairs(all_data_component_handles) do	
			local shading_environment_mapping_resource_name = data_component_manager:get_property(
				entity_handle,
				data_component_handle,
				{"shading_environment_mapping"}
				)

			if shading_environment_mapping_resource_name == resource_name then
				return {
					entity    = entity_handle,
					component = data_component_handle
				}
			end
		end
	end

	-- Specified component was not found
	return nil
end
 
function ProjectUtils.update_shading_env_entity(world, entity, component, name, value)
	if not world or not entity or not component then return end
	local data_component_manager = EntityManager.data_component(world)
	data_component_manager:set_property(entity, component, {name}, value)
end

return ProjectUtils