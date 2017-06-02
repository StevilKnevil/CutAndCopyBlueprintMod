--[[
A mod to enable the copy/cut and pasting or areas of the factory.

Implementation:
when an area is selected with the tool, a temporary blueprint is created in the players hand.
The initial selection of items are flagged as needing deconstruction by a different force (either neutral, or with a special name, 
if the neutral force starts being able to dismantle players factory in the future).

It is done this way so that we can indicate to the player that the initial items will be deconstructed, and also to allow the copied blueprint to be placed overlapping the original structure. However logistic robots won't start the dismantelling as thos bits are part of a different force now.

When the blueprint is stamped down somewhere new, the original components are transferred back to the player so that the logistic network can some and start taking it apart. If the player cancells, then the deconstruction flag is cleared and nothing untoward happens
]]

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
local kTempBlueprintLabel = "Copy Blueprint"
local kCopyBlueprintToolName = "copy-blueprint"
local kCutBlueprintToolName = "cut-blueprint"
local kUseCustomTempForce = true
local kCcpyBlueprintForceName = "neutral"
if kUseCustomTempForce then
  kCcpyBlueprintForceName = "Copy Blueprint Force"
else
end


--------------------------------------------------------------------------------
-- Utility to see if the given item is the temporary copy blueprint
--------------------------------------------------------------------------------
local isTempBlueprint = function(stack)
  if stack.type == "blueprint" and
    stack.name == "blueprint" and 
    stack.label == kTempBlueprintLabel then
    return true
  end
  return false
end

--------------------------------------------------------------------------------
-- Utility to find the copy blueprint item in the players inventories
--------------------------------------------------------------------------------
local findTempBlueprintSlotInInventory = function (player)
  local invs = {defines.inventory.player_quickbar, defines.inventory.player_main, defines.inventory.god_quickbar, defines.inventory.god_main}
  
  for _, idx in pairs(invs) do
    local inventory = player.get_inventory(idx)
    if inventory then
      for i = 1, #inventory do
        local slot = inventory[i]
        if slot.valid_for_read then
          if isTempBlueprint(slot) then
            return slot
          end
        end
      end
    end
  end
end


--------------------------------------------------------------------------------
-- Creates a temporary blueprint (in the players hand) of the passed in entities
--------------------------------------------------------------------------------
local createTempBlueprint = function(player, area)
  -- create a new temp blueprint in the players hand (the tool will be returned to the players inventory)
  player.cursor_stack.set_stack("blueprint")
  player.cursor_stack.clear_blueprint()
  player.cursor_stack.label = kTempBlueprintLabel
  player.cursor_stack.allow_manual_label_change = false  
  player.cursor_stack.create_blueprint{
    surface = player.surface,
    force = player.force,
    area = area,
    always_include_tiles = false
  }
end

--------------------------------------------------------------------------------
-- Convert the temp blueprint back to the blueprint too (to avoid cluttering inventory with temporary blueprints)
--------------------------------------------------------------------------------
local replaceTempBlueprintWithTool = function(player)
  local bp = findTempBlueprintSlotInInventory(player)
  if bp then
    -- revert back to the tool used
    bp.set_stack(global.toolUsed)
    global.toolUsed = nil
  end
end

--------------------------------------------------------------------------------
-- Flag entities for future destruction
--------------------------------------------------------------------------------
local initialiseOperation = function()
  for _,v in pairs(global.entitiesToDestroy) do
    -- Switch the original entities to the temp force and flag for deletion
    -- this stops them actually being deleted until the placement has been confirmed
    v.force = kCcpyBlueprintForceName
    v.order_deconstruction(kCcpyBlueprintForceName)
  end
end

--------------------------------------------------------------------------------
-- Allow entities to actually be destructed
--------------------------------------------------------------------------------
local finaliseOperation = function(player)
    -- delete the original entities
    for _,v in pairs(global.entitiesToDestroy) do
      -- not sure how entities in the list may be invalid, seems to happen after save some times.
      if (v.valid) then
        -- Cancel the deconstruction by temp force, assign back to player and request deconstruction by player's force
        v.cancel_deconstruction(kCcpyBlueprintForceName)
        v.force = player.force
        v.order_deconstruction(player.force)
      end
    end
    global.entitiesToDestroy = {}

end

--------------------------------------------------------------------------------
-- Cancel destruction of entities
--------------------------------------------------------------------------------
local cancelOperation = function(player)
  -- If we have a list of entities pending, theh we've flagged items for deletion and not placed the copy,
  -- so then clear the deletion flags as the user cancelled
  for _,v in pairs(global.entitiesToDestroy) do
    v.cancel_deconstruction(v.force)
    v.force = player.force
  end
  global.entitiesToDestroy = {}
end


--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
local on_player_copied_area = function(event)
  global.toolUsed = event.item
  createTempBlueprint(game.players[event.player_index], event.area)
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
local on_player_cut_area = function(event)
  -- first do the copy
  on_player_copied_area(event)
  
  -- Store the initial selection list (persitantly) as we'll need to use this later
  global.entitiesToDestroy = event.entities
  -- flag the items for deletion now, so that we can place the blueprint over the top
  initialiseOperation()  
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
script.on_event(defines.events.on_player_selected_area, function(event)
  if (#event.entities > 0) then
    if event.item == kCopyBlueprintToolName then
      on_player_copied_area(event)
    end
    
    if event.item == kCutBlueprintToolName then
      on_player_cut_area(event)
    end
  end
end)

script.on_event(defines.events.on_player_alt_selected_area, function(event)
  -- alt selection == other operation
  if (#event.entities > 0) then
    if event.item == kCopyBlueprintToolName then
      on_player_cut_area(event)
    end
    
    if event.item == kCutBlueprintToolName then
      on_player_copied_area(event)
    end 
  end
end)

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
script.on_event(defines.events.on_built_entity, function(event)
  local player = game.players[event.player_index]

  if event.item == "blueprint" and
    player.cursor_stack.valid_for_read and 
    isTempBlueprint(player.cursor_stack) then
  
    finaliseOperation(player)
    
  end
  
end)
 
--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
-- Clear the list of things to destroy every time the 'active' thing changes
script.on_event(defines.events.on_player_cursor_stack_changed, function(event) 
  local player = game.players[event.player_index]
  local item = event.item
  local entity = event.created_entity

  -- If we have just put the temp blueprint in our hand, then this it fine, nothing to do
  if player.cursor_stack.valid_for_read and isTempBlueprint(player.cursor_stack) then
    return
  end
  
  cancelOperation(player)
  
  -- ensure that the copy blueprint item is put back in place of the temp blueprint
  -- TODO: Avoid this search each time. Have a flag?
  replaceTempBlueprintWithTool(player)

end)


--------------------------------------------------------------------------------
-- Initialise data for the mod
--------------------------------------------------------------------------------
script.on_init(function()
  -- initialise the table
  global.entitiesToDestroy = {}
  global.toolUsed = nil
  
  if kUseCustomTempForce then
    -- Initialise the temp force
    game.create_force(kCcpyBlueprintForceName)
  end
end)
