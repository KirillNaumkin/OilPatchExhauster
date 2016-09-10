require "util"
require "config"

--script.on_event(defines.events.on_gui_click, function(event)
--  game.players[event.player_index].print("GUI element clicked: " .. event.element.name)
--end)

script.on_event(defines.events.on_tick, function(event)
	TickTanks(event)
end)

script.on_event({
    defines.events.on_built_entity, 
    defines.events.on_robot_built_entity
  }, 
  function(event)
    if event.created_entity.name == "oil-exhauster" then
      RememberOilPatchExhauster(event.created_entity)
    end
  end)

script.on_event({
    defines.events.on_preplayer_mined_item, 
    defines.events.on_robot_pre_mined, 
    defines.events.on_entity_died
  }, 
  function(event)
    if event.entity.name == "oil-exhauster" then
      ForgetOilPatchExhauster(event.entity)
    end
  end)

function RememberOilPatchExhauster(entity)
  if global.OPExhausters == nil then
    global.OPExhausters = {}
  end
  local OPExhauster = {}
  OPExhauster.ent = entity
  --PExhauster.drained = 0 --outdated
  OPExhauster.patches_to_exhaust = {}
  for i,oil_patch in pairs(FindOilPatchesUnder(entity)) do
    --entity.built_by.print("Yield = " .. oil_patch.amount)
    if oil_patch.amount <= (MINIMAL_YIELD_PERCENTAGE_TO_EXHAUST * 150) then
      local valid_patch = {ent = oil_patch, estimated_oil = oil_patch.amount * 10}
      table.insert(OPExhauster.patches_to_exhaust, valid_patch)
    end
  end
  table.insert(global.OPExhausters, OPExhauster)
end

function ForgetOilPatchExhauster(entity)
  if global.OPExhausters ~= nil then
    for i,OPExhauster in pairs(global.OPExhausters) do
      if OPExhauster.ent.surface == entity.surface then
        if OPExhauster.ent.position.x == entity.position.x and OPExhauster.ent.position.y == entity.position.y then
          for j,oil_patch in pairs(OPExhauster.patches_to_exhaust) do
            oil_patch.ent.destroy()
          end
          table.remove(global.OPExhausters, i)
          return
        end
      end
    end
  end
end

function TickTanks(event)
	if global.OPExhausters ~= nil then 
		for i = #global.OPExhausters,1,-1 do
      local OPExhauster = global.OPExhausters[i]
			if OPExhauster.ent.valid then
        for j = #OPExhauster.patches_to_exhaust, 1, -1 do
          local oil_patch = OPExhauster.patches_to_exhaust[j]
          if oil_patch.ent.valid then
            if oil_patch.estimated_oil > 0 then
              local amount = 1
              if OPExhauster.ent.fluidbox[1] ~= nil then
                amount = OPExhauster.ent.fluidbox[1].amount
              end
              if (amount + 1) <= EXHAUSTER_CAPACITY then --is there free capacity for new portion?
                OPExhauster.ent.fluidbox[1] = {
                  ["type"] = "crude-oil",
                  ["amount"] = amount + 1
                }
                oil_patch.estimated_oil = oil_patch.estimated_oil - 1
              end
            else --oil_patch.estimated_oil == 0
              oil_patch.ent.destroy()
              table.remove(OPExhauster.patches_to_exhaust, j)
            end
          else --oil_patch.ent.valid == false
            table.remove(OPExhauster.patches_to_exhaust, j)
          end
        end
			else --OPExhauster.ent.valid == false
        table.remove(global.OPExhausters, i)
      end
		end
	end
end

function FindOilPatchesUnder(entity)
  local pos = entity.position
  local srf = entity.surface
  local dlt = 1
  local search_area = {{pos.x - dlt, pos.y - dlt}, {pos.x + dlt, pos.y + dlt}}
  local oil_patches = srf.find_entities_filtered{area = search_area, name = "crude-oil"}
  return oil_patches
end
