if global.OPExhausters ~= nil then
  for i,OPExhauster in pairs(global.OPExhausters) do
    if OPExhauster.ent.valid then
      if OPExhauster.drained ~= nil then
        local newOPExhauster = {}
        newOPExhauster.ent = OPExhauster.ent
        newOPExhauster.patches_to_exhaust = {}
        for i,oil_patch in pairs(FindOilPatchesUnder(entity)) do
          if oil_patch.amount <= 3000 then
            local valid_patch = {ent = oil_patch, estimated_oil = oil_patch.amount * 10}
            table.insert(OPExhauster.patches_to_exhaust, valid_patch)
          end
        end
        global.OPExhausters[i] = newOPExhauster
      end
    else --OPExhauster.ent.valid == false
      global.OPExhausters[i] = nil
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
