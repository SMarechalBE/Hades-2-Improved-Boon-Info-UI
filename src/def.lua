---@meta SMarBe-Improved_Boon_Info_UI
local public = {}

---Get the state of the given boon in the following order of importance:<br>
--- 1. Picked<br>
--- 2. Denied (vow of denials)<br>
--- 3. Slot unavailable<br>
--- 4. God unavailable<br>
--- 5. State from its requirements, see GetBoonRequirementState
---@param traitName string
---@return BoonState
function public.GetBoonState(traitName) end

---Checks whether the god is one of the Olympian (slot) boon giver
---@param godName string
---@return boolean
function public.IsSlotGiver(godName) end


public.BoonState = ...

return public