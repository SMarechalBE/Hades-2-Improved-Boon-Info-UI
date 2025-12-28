---@meta _
-- globals we define are private to our plugin!
---@diagnostic disable: lowercase-global

---Checks whether the given boon is currently picked
---@param traitName string
---@return boolean
function IsBoonPicked(traitName)
	return game.HeroHasTrait(traitName)
end

---Get a lookup table of the gods met this run
---@return table
function GetMetGodsLookup()

	local gods = {}
	for _, godName in pairs( GetInteractedGodsThisRun() ) do
		gods[godName] = true
	end

	return gods
end

---Get the list of gods linked to the given boon
---@param traitName string
---@return [string]
function GetGodsName(traitName)
	local gods = {}

	for _, god in pairs(game.LootData) do
		if god.GodLoot and god.TraitIndex[traitName] then
			table.insert(gods, god.Name)
		end
	end

	return gods
end

---Checks whether the god of the given boon is available (e.g., in the god pool if max reached).  
---@param traitName string
---@return boolean
function IsBoonGodAvailable(traitName)
	if not IsRunOngoing() or not game.ReachedMaxGods() then return true end

	local metGods = GetMetGodsLookup()

	local requiredGods = GetGodsName(traitName)
	for _, godName in ipairs(requiredGods) do
		if not metGods[godName] then return false end
	end

	return true
end

---Checks whether the god is one of the Olympian (slot) boon giver
---TODO: I think this should just be GodLoot
---@param godName string
---@return boolean
function IsSlotGiver(godName)
	for _, slotGod in ipairs(BoonSlotGivers) do
		if godName == slotGod then
			return true
		end
	end

	return false
end

---Checks whether the god of the given boon is one of the Olympian (slot) boon giver
---@param traitName string
---@return boolean
function IsBoonFromSlotGiver(traitName)
	local godName = game.GetGodSourceName(traitName)
	return IsSlotGiver(godName)
end

---Checks whether the god of the given boon is one of the Olympian (slot) boon giver
---@param traitName string
---@return boolean
function IsBoonDenied(traitName)
	for bannedBoon, banned in pairs(game.CurrentRun.BannedTraits) do
		if traitName == bannedBoon then
			return banned
		end
	end

	return false
end

---Gets the slot of the given boon (if applicable).
---@param traitName string
---@return string?
function GetSlot(traitName)
	local traitData = game.TraitData[traitName]
	return  traitData
		and traitData.Slot
end

---Checks if the slot of the given boon is available, always true if the boon has no slot.
---@param traitName string
---@return boolean
function IsBoonSlotAvailable(traitName)
	local slotName = GetSlot(traitName)
	return not slotName
		or not game.HeroSlotFilled(slotName)
end

---Checks if a run is currently ongoing
---@return boolean
function IsRunOngoing()
	return not game.CurrentHubRoom
end

---Create a BoonState table with each entry representing the count of occurences of that state in<br>
---the table 
---@param traits table
---@return table
local function CreateBoonStateCountTable(traits)
	local states = {}
	for _, traitName in ipairs(traits) do
		local stateName, unfulfilledStateName = GetBoonState(traitName)
		if unfulfilledStateName then stateName = unfulfilledStateName end
		states[stateName] = (states[stateName] or 0) + 1
	end

	return states
end

---Parses a table created by CreateBoonStateCountTable and returns the boon state.<br> 
---  Those strange calculations are necessary to handle pickCountNeeded > 1 
---@param stateCountTable table
---@param pickCountNeeded integer The number of picked boons required in the table
---@return BoonState
---@return BoonUnfulfilledState?
local function GetStateFromStateCountTable(stateCountTable, pickCountNeeded)

	pickCountNeeded = pickCountNeeded - (stateCountTable.Picked and stateCountTable.Picked or 0)
	if pickCountNeeded < 1 then
		return BoonState.Available -- requirement is fulfilled, so boon is available
	end
	
	pickCountNeeded = pickCountNeeded - (stateCountTable.Available and stateCountTable.Available or 0)
	if pickCountNeeded < 1 then
		return BoonState.Unfulfilled
	end

	pickCountNeeded = pickCountNeeded - (stateCountTable.Unfulfilled and stateCountTable.Unfulfilled or 0)
	if pickCountNeeded < 1 then
		return BoonState.Unfulfilled
	end

	pickCountNeeded = pickCountNeeded - (stateCountTable.SlotUnavailable and stateCountTable.SlotUnavailable or 0)
	if pickCountNeeded < 1 then
		return BoonState.Unfulfilled, BoonUnfulfilledState.SlotUnavailable
	end

	if stateCountTable.GodUnavailable and stateCountTable.GodUnavailable >= pickCountNeeded then
		return BoonState.Unfulfilled, BoonUnfulfilledState.GodUnavailable
	else
		return BoonState.Denied
	end
end

---Compute boon state given requirement sets
---@param requirementSets [ [string]]
---@return BoonState
---@return BoonUnfulfilledState?
function GetStateFromOneFromEachSet(requirementSets)
	local states = {}
	local unfulfilledStates = {}

	for _, requirements in ipairs(requirementSets) do
		local stateName, unfulfilledStateName = GetStateFromStateCountTable(CreateBoonStateCountTable(requirements), 1)
		states[stateName] = true
		if unfulfilledStateName then unfulfilledStates[unfulfilledStateName] = true end
	end
	
	-- Unavailability has more weight between sets
	if states.Denied then return BoonState.Denied end
	if states.Unfulfilled then
		if unfulfilledStates.GodUnavailable then
			return BoonState.Unfulfilled, BoonUnfulfilledState.GodUnavailable
		elseif unfulfilledStates.SlotUnavailable then
			return BoonState.Unfulfilled, BoonUnfulfilledState.SlotUnavailable
		else
			return BoonState.Unfulfilled
		end
	end

	return BoonState.Available
end

---Get the state of the requirements for the given requirement table. When evaluating boon states<br>
---inside a requirements listing, we prioritize the overall state by its availability:<br>
--- 1. Picked<br>
--- 2. Available<br>
--- 3. God unavailable<br>
--- 4. Slot unavailable<br>
--- 5. Slot denied (vow of denials)
---@param requirements table
---@param type RequirementType
---@return BoonState
---@return BoonUnfulfilledState?
function GetRequirementState(requirements, type)
	if not requirements then
		return BoonState.Available
	end

	if type == RequirementType.OneOf then
		return GetStateFromStateCountTable(CreateBoonStateCountTable(requirements), 1)
	end

	if type == RequirementType.TwoOf then
		-- This is technically not implemented in the game currently, but let's add this here<br>
		--  for robustness.
		return GetStateFromStateCountTable(CreateBoonStateCountTable(requirements), 2)
	end

	if type == RequirementType.OneFromEachSet then
		return GetStateFromOneFromEachSet(requirements)
	end

	modutil.mod.Print("Something went wrong when checking requirements state, wrong type passed: "
					  .. type .. ", should be OneOf, TwoOf or OneFromEachSet")
	return BoonState.Available --We shouldn't ever get here
end

---Get the state of the requirements for the given boon. If multiple requirements are unavailable,<br>
---slot unavailability takes precedence on god unavailability as the condition is usually harder<br>
---to fulfill (i.e. requires a boon sacrifice vs requires a keepsake)
---@param traitName string
---@return BoonState
---@return BoonUnfulfilledState?
function GetBoonRequirementState(traitName)
	local boonRequirements = game.TraitRequirements[traitName]
	if not boonRequirements then
		return BoonState.Available
	end

	for _, type in pairs(RequirementType) do
		local req = boonRequirements[type]
		if req then
			return GetRequirementState(req, type)
		end
	end

	modutil.mod.Print("Something went wrong when retrieving TraitRequirements for trait: "
					.. traitName .. ", should have OneOf, TwoOf or OneFromEachSet")
	return BoonState.Available --We shouldn't ever get here
end

---Get the state of the given boon in the following order of importance:<br>
--- 1. Picked<br>
--- 2. Denied (vow of denials)<br>
--- 3. Slot unavailable<br>
--- 4. God unavailable<br>
--- 5. State from its requirements, see GetBoonRequirementState
---@param traitName string
---@return BoonState
---@return BoonUnfulfilledState?
function GetBoonState(traitName)
	if IsBoonPicked(traitName) then
		return BoonState.Picked
	elseif not IsBoonFromSlotGiver(traitName) then -- Make all boons from non slot boon god available
		return BoonState.Available
	end

	local requirementState, unfulfilledState = GetBoonRequirementState(traitName)
	if IsBoonDenied(traitName) or requirementState == BoonState.Denied then
		return BoonState.Denied
	elseif not IsBoonGodAvailable(traitName) then
		return BoonState.GodUnavailable
	elseif not IsBoonSlotAvailable(traitName) then
		return BoonState.SlotUnavailable
	else
		return requirementState, unfulfilledState
	end
end

---Retrieve the boon currently in the given slot
---@param slotName string
---@return string?
function GetCurrentBoonForSlot(slotName)
	if not slotName then return nil end
	if not game.CurrentRun or not game.CurrentRun.Hero or not game.CurrentRun.Hero.Traits then return nil end

	for _, traitData in ipairs( game.CurrentRun.Hero.Traits ) do
		if traitData.Slot == slotName then
			return traitData.Name
		end
	end

	return nil
end

---Retrieve different boon to sacrifice for this boon 
---@param traitName string
---@return string?
function GetSacrificeBoon(traitName)
	local traitData = traitName and game.TraitData[traitName]
	if not traitData then return nil end

	local sacrificeTraitName = GetCurrentBoonForSlot(traitData.Slot)
	if not sacrificeTraitName or traitName == sacrificeTraitName then
		return nil
	end

	return sacrificeTraitName
end


local Context =
{
	Filter =
	{
		Values =
		{
			Order =
			{
				"Available", -- 1
				"Unfulfilled", -- 2
				"Unavailable", -- 3
				"All", -- 4
			},

			All =
			{
				Text = "ALL",
				StatesAllowed =
				{
					BoonState.Picked,
					BoonState.SlotUnavailable,
					BoonState.GodUnavailable,
					BoonState.Available,
					BoonState.Denied,
					BoonState.Unfulfilled,
				}
			},

			Available =
			{
				Text = "AVAILABLE",
				StatesAllowed =
				{
					BoonState.Available,
					config.sacrificeBoonsAlwaysAsAvailable and BoonState.SlotUnavailable or nil,
				}
			},

			Unfulfilled =
			{
				Text = "UNFULFILLED",
				StatesAllowed =
				{
					BoonState.Available,
					config.sacrificeBoonsAlwaysAsAvailable and BoonState.SlotUnavailable or nil,
					BoonState.Unfulfilled,
				}
			},

			Unavailable =
			{
				Text = "UNAVAILABLE",
				StatesAllowed =
				{
					BoonState.SlotUnavailable,
					BoonState.GodUnavailable,
					BoonState.Available,
					BoonState.Unfulfilled,
				}
			},

		},
		CurrentIndex = 2,
	},
}


function GetStartingFilterIndex(godName)
	if godName == "PlayerUnit" then
		return 2 -- Show unfulfilled by default for Melinoe (dirty dependency hack)
	end

	local metGodsLookup = GetMetGodsLookup()
	if metGodsLookup[godName] then
		return 1 -- Show available by default for met gods
	else
		return 3 -- Show unavailable for other gods
	end
end

function BoonInfoScreenNextFilter( screen, button )
	SetFilter(Context.Filter.CurrentIndex + 1, screen)
	RefreshBoons(screen)
	game.PlaySound({ Name = "/SFX/Menu Sounds/IrisMenuSwitch" })
end

function BoonInfoScreenPreviousFilter( screen, button )
	SetFilter(Context.Filter.CurrentIndex - 1, screen)
	RefreshBoons(screen)
	game.PlaySound({ Name = "/SFX/Menu Sounds/IrisMenuSwitch" })
end

function SetComponent(componentId, setOn)
	if setOn then
		game.SetAlpha({ Id = componentId, Fraction = 1.0, Duration = 0.0 })
		game.UseableOn({ Id = componentId })
	else
		game.SetAlpha({ Id = componentId, Fraction = 0.0, Duration = 0.0 })
		game.UseableOff({ Id = componentId})
	end
end

function GetFilterValue(value)
	return Context.Filter.Values.Order[value]
end

function GetCurrentFilterText()
	local filter = GetFilterValue(Context.Filter.CurrentIndex)
	return filter and "FILTER: "..Context.Filter.Values[filter].Text
end

function GetCurrentFilterAllowedStates()
	local filter = GetFilterValue(Context.Filter.CurrentIndex)
	return filter and Context.Filter.Values[filter].StatesAllowed
end

function RefreshBoons(screen)
	game.BoonInfoPopulateTraits( screen )
	ApplyFilter(screen)
	game.CreateBoonInfoButtons( screen )
	if #screen.TraitList > 0 then
		game.TeleportCursor({ DestinationId = screen.Components["BooninfoButton1"].PurchaseButton.Id, ForceUseCheck = true })
	end
	game.UpdateBoonInfoPageButtons( screen )
end

function SetFilter(index, screen)
	Context.Filter.CurrentIndex = index

	local components = screen.Components
	if not components then return end

	local textFilterTypeId = components.TextFilterType and components.TextFilterType.Id
	if textFilterTypeId then
		local filterText = GetCurrentFilterText()
		if filterText then
			game.ModifyTextBox({ Id = textFilterTypeId, Text = filterText })
		end
		SetComponent(textFilterTypeId, filterText)
	end

	local previousFilterId = components.PreviousFilter and components.PreviousFilter.Id
	if previousFilterId then
		SetComponent(previousFilterId, GetFilterValue(index - 1))
	end

	local nextFilterId = components.NextFilter and components.NextFilter.Id
	if nextFilterId then
		SetComponent(nextFilterId, GetFilterValue(index + 1))
	end
end

function InitializeFilter(screen)
	local components = screen and screen.Components
	if not components then return end

	if not IsSlotGiver(screen.LootName) then
		SetComponent(components.PreviousFilter.Id)
		SetComponent(components.NextFilter.Id)
		SetComponent(components.TextFilterType.Id)
		return
	end

	SetFilter(GetStartingFilterIndex(screen.LootName), screen)
end

function ApplyFilter(screen)
	if not IsSlotGiver(screen.LootName) then return end

	local allowedStates = GetCurrentFilterAllowedStates()
	if not allowedStates then return end -- Shouldn't be the case

	local filteredTraitList = {}
	for _, traitName in ipairs(screen.TraitList) do
		local boonState, unfulfilledBoonState = GetBoonState(traitName)
		for _, state in pairs(allowedStates) do
			if (unfulfilledBoonState or boonState) == state then
				table.insert(filteredTraitList, traitName)
			end
		end
	end
	screen.TraitList = filteredTraitList
end
