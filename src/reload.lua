---@meta _
-- globals we define are private to our plugin!
---@diagnostic disable: lowercase-global

---Checks whether the given boon is currently picked
---@param trait_name string
---@return boolean
function IsBoonPicked(trait_name)
	return HeroHasTrait(trait_name)
end

---Checks whether the god of the given boon is available (e.g., in the god pool if max reached).  
---@param trait_name string
---@return boolean
function IsBoonGodAvailable(trait_name)
	return not ReachedMaxGods()
		or CurrentRun.Hero.MetGods[GetGodSourceName(trait_name)]
end

---Checks whether the god of the given boon is one of the Olympian (slot) boon giver
---@param traitName string
---@return boolean
function IsBoonSlotGiver(traitName)
	local godName = GetGodSourceName(traitName)
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
function IsBoonDenied(traitName)
	for bannedBoon, banned in pairs(CurrentRun.BannedTraits) do
		if traitName == bannedBoon then
			return banned
		end
	end

	return false
end

---Gets the slot of the given boon (if applicable).
---@param trait_name string
---@return string?
function GetSlot(trait_name)
	local trait_data = TraitData[trait_name]
	return  trait_data
		and trait_data.Slot
end

---Checks if the slot of the given boon is available, always true if the boon has no slot.
---@param trait_name string
---@return boolean
function IsBoonSlotAvailable(trait_name)
	local slot_name = GetSlot(trait_name)
	return not slot_name
		or not HeroSlotFilled(slot_name)
end

---Create a BoonState table with each entry representing the count of occurences of that state in<br>
---the table 
---@param traits table
---@return table
local function CreateBoonStateCountTable(traits)
	local states = {}
	for _, trait_name in ipairs(traits) do
		local state_name = GetBoonState(trait_name)
		states[state_name] = (states[state_name] or 0) + 1
	end

	return states
end

---Parses a table created by CreateBoonStateCountTable and returns the boon state.
---@param stateCountTable table
---@param pickCountNeeded integer The number of picked boons required in the table
---@return string
local function GetStateFromStateCountTable(stateCountTable, pickCountNeeded)
	return (stateCountTable.Picked and stateCountTable.Picked >= pickCountNeeded and BoonState.Picked)
		or (stateCountTable.Available and stateCountTable.Available > 0 and BoonState.Available)
		or (stateCountTable.GodUnavailable and stateCountTable.GodUnavailable > 0 and BoonState.GodUnavailable)
		or (stateCountTable.SlotUnavailable and stateCountTable.SlotUnavailable > 0 and BoonState.SlotUnavailable)
		or BoonState.Denied
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
		local states = {}
		for _, set in ipairs(requirements) do
			local state_name = GetRequirementState(set, RequirementType.OneOf)
			states[state_name] = (states[state_name] or 0) + 1
		end
		-- We prioritize unavailability for OneOfEachSet type
		return (states.Denied and states.Denied > 0 and BoonState.Denied)
			or (states.SlotUnavailable and states.SlotUnavailable > 0 and BoonState.SlotUnavailable)
			or (states.GodUnavailable and states.GodUnavailable > 0 and BoonState.GodUnavailable)
			or (states.Available and states.Available > 0 and BoonState.Available)
			or BoonState.Picked
	end

	modutil.mod.Print("Something went wrong when checking requirements state, wrong type passed: "
					  .. type .. ", should be OneOf, TwoOf or OneFromEachSet")
	return BoonState.SlotUnavailable --We shouldn't ever get here
end

---Get the state of the requirements for the given boon. If multiple requirements are unavailable,<br>
---slot unavailability takes precedence on god unavailability as the condition is usually harder<br>
---to fulfill (i.e. requires a boon sacrifice vs requires a keepsake)
---@param trait_name string
---@return BoonState
function GetBoonRequirementState(trait_name)
	local boon_requirements = TraitRequirements[trait_name]
	if not boon_requirements then
		return BoonState.Available
	end

	for _, type in pairs(RequirementType) do

		local req = boon_requirements[type]
		if req then
			return GetRequirementState(req, type)
		end
	end

	modutil.mod.Print("Something went wrong when retrieving TraitRequirements for trait: "
					.. trait_name .. ", should have OneOf, TwoOf or OneFromEachSet")
	return BoonState.SlotUnavailable --We shouldn't ever get here
end

---Get the state of the given boon in the following order of importance:<br>
--- 1. Picked<br>
--- 2. Denied (vow of denials)<br>
--- 3. Slot unavailable<br>
--- 4. God unavailable<br>
--- 5. State from its requirements, see GetBoonRequirementState
---@param trait_name string
---@return BoonState
function GetBoonState(trait_name)
	local requirementState = GetBoonRequirementState(trait_name)
	return (IsBoonPicked(trait_name) and BoonState.Picked)
		or (not IsBoonSlotGiver(trait_name) and BoonState.Available) -- Make all boons from non slot boon god available
		or ((IsBoonDenied(trait_name) or requirementState == BoonState.Denied) and BoonState.Denied)
		or ((not IsBoonSlotAvailable(trait_name) or requirementState == BoonState.SlotUnavailable) and BoonState.SlotUnavailable)
		or ((not IsBoonGodAvailable(trait_name) or requirementState == BoonState.GodUnavailable) and BoonState.GodUnavailable)
		or BoonState.Available
end

---TODO
---@param slot_name string
---@return string?
function GetCurrentBoonForSlot(slot_name)
	if not slot_name then
		return nil
	end

	for _, traitData in ipairs( CurrentRun.Hero.Traits ) do
		if traitData.Slot == slot_name then
			return traitData.Name
		end
	end

	return nil
end

---TODO
---@param trait_name string
---@return string?
function GetSacrificeBoon(trait_name)
	if not trait_name then
		return nil
	end
	local trait_data = TraitData[trait_name]
	if not trait_data then
		return nil
	end

	local sacrifice_trait_name = GetCurrentBoonForSlot(trait_data.Slot)
	if not sacrifice_trait_name or trait_name == sacrifice_trait_name then
		return nil
	end

	return sacrifice_trait_name
end
