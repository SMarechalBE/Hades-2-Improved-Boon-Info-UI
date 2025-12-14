---@meta _
-- globals we define are private to our plugin!
---@diagnostic disable: lowercase-global

---@enum BoonState
BoonState =
{
	Picked = "Picked",
	SlotUnavailable = "SlotUnavailable",
	GodUnavailable = "GodUnavailable",
	Available = "Available",
	Denied = "Denied",
	Unfulfilled = "Unfulfilled"
}
public.BoonState = BoonState

---@enum RequirementType
RequirementType =
{
	OneOf = "OneOf",
	TwoOf = "TwoOf",
	OneFromEachSet = "OneFromEachSet",
}

local function ChangeAlpha(color, alpha)
	local newColor = game.ShallowCopyTable(color)
	newColor[4] = alpha

	return newColor
end

BoonColors = {}

BoonColors.State =
{
	Picked = Color.BoonInfoAcquired,
	SlotUnavailable = Color.BonesUnaffordable,
	GodUnavailable = Color.BonesLocked,
	-- Available = rarity
	-- Unfulfilled: rarity with lower alpha
	-- Denied = rarity with lower alpha
}

BoonColors.Requirement = {}

BoonColors.Requirement.Header =
{
	Available = BoonColors.State.Picked,
	Unfulfilled = Color.White,
	SlotUnavailable = BoonColors.State.SlotUnavailable,
	GodUnavailable = BoonColors.State.GodUnavailable,
	Denied = Color.BonesInactive, -- black-ish
}

local GreyishColor = { 52, 48, 58, 185 }
BoonColors.Requirement.BulletList =
{
	Picked = Color.White,
	SlotUnavailable = ChangeAlpha(BoonColors.State.SlotUnavailable, 185),
	GodUnavailable = ChangeAlpha(BoonColors.State.GodUnavailable, 185),
	Available = GreyishColor,
	Unfulfilled = ChangeAlpha(GreyishColor, 50),
	Denied = ChangeAlpha(BoonColors.Requirement.Header.Denied, 185),
}

local function CreateListRequirementFormatTableWithColor(color)
	return {
		Text = "BoonInfo_BulletPoint",
		FontSize = 22,
		OffsetX = 30,
		Color = color,
		Font = "P22UndergroundSCMedium",
		ShadowBlur = 0, ShadowColor = {0,0,0,1}, ShadowOffset={0, 1},
		Justification = "Left",
		LuaKey = "TempTextData",
		DataProperties =
		{
			OpacityWithOwner = true,
		},
	}
end

---@enum BoonSlotGivers
BoonSlotGivers = {
	"AphroditeUpgrade",
	"ApolloUpgrade",
	"DemeterUpgrade", 
	"HephaestusUpgrade",
	"HestiaUpgrade",
	"HeraUpgrade",
	"PoseidonUpgrade",
	"ZeusUpgrade",
	"AresUpgrade",
}


modutil.mod.Path.Override("CreateBoonInfoButton", function(screen, traitName, index)
	local screenData = ScreenData.UpgradeChoice

	local traitInfo = {}
	traitInfo.Components = {}
	table.insert( screen.TraitContainers, traitInfo )
	local offset = { X = screen.ButtonStartX, Y = screen.ButtonStartY + index * screenData.ButtonSpacingY }
	local itemLocationX = offset.X + ScreenCenterNativeOffsetX
	local itemLocationY = offset.Y + ScreenCenterNativeOffsetY

	screen.Components["BooninfoButton"..index] = traitInfo

	local traitData = TraitData[traitName]
	local rarity = GetBoonRarityFromData( traitData )
	local overrideRarityName = GetBoonOverrideRarityNameFromData( traitData )

	local consumable = GetRampedConsumableData( ConsumableData[traitName], { ForceMin = true } )
	local newTraitData = consumable or GetProcessedTraitData({ Unit = CurrentRun.Hero, TraitName = traitName, Rarity = rarity, ForBoonInfo = true, ForceMin = true })
	newTraitData.ForBoonInfo = true
	SetTraitTextData( newTraitData )

	local backingAnim = screenData.RarityBackingAnimations[rarity]
	if traitData ~= nil and traitData.UpgradeChoiceBackingAnimation ~= nil then
		backingAnim = traitData.UpgradeChoiceBackingAnimation
	end
	
	local purchaseButton = ShallowCopyTable( screenData.PurchaseButton )
	purchaseButton.Group = "Combat_Menu_TraitTray"
	if backingAnim ~= nil then
		purchaseButton.Animation = backingAnim
	end
	purchaseButton.X = itemLocationX + screenData.ButtonOffsetX
	purchaseButton.Y = itemLocationY
	purchaseButton.TraitData = newTraitData
	local button = CreateScreenComponent( purchaseButton )
	traitInfo.PurchaseButton = button
	button.TraitData = newTraitData
	button.Screen = screen
	button.OnMouseOverFunctionName = "MouseOverBoonInfoItem"
	button.OnMouseOffFunctionName = "MouseOffBoonInfoItem"
	SetInteractProperty({ DestinationId = button.Id, Property = "TooltipOffsetX", Value = screen.TooltipOffsetX })
	SetInteractProperty({ DestinationId = button.Id, Property = "TooltipOffsetY", Value = screen.TooltipOffsetY })
	--SetInteractProperty({ DestinationId = button.Id, Property = "TooltipX", Value = screen.TooltipX })
	--SetInteractProperty({ DestinationId = button.Id, Property = "TooltipY", Value = screen.TooltipY })
	AttachLua({ Id = button.Id, Table = button })
	table.insert( traitInfo.Components, button )

	local rarityColor = newTraitData.CustomRarityColor or Color["BoonPatch"..rarity]

	traitInfo.TitleBox = CreateScreenComponent({ Name = "BlankObstacle", Group = "Combat_Menu_TraitTray_Overlay", X = purchaseButton.X, Y = purchaseButton.Y })
	local titleText = ShallowCopyTable( screenData.TitleText )
	titleText.Id = traitInfo.TitleBox.Id
	titleText.Text = newTraitData.Name
	titleText.LuaValue = newTraitData
	-- override start
	-- We retrieve boon state from GetBoonState, then retrieve the corresponding color
	local boonState = GetBoonState(traitName)
	if boonState == BoonState.Available then
		titleText.Color = rarityColor
	elseif boonState == BoonState.Unfulfilled or boonState == BoonState.Denied then
		titleText.Color = ChangeAlpha(rarityColor, 120)
	else
		titleText.Color = BoonColors.State[boonState]
	end
	-- override end
	CreateTextBox( titleText )
	table.insert( traitInfo.Components, traitInfo.TitleBox )

	local descriptionText = ShallowCopyTable( screenData.DescriptionText )
	descriptionText.Text = newTraitData.CodexName or newTraitData.Name
	descriptionText.LuaValue = newTraitData
	descriptionText.TextSymbolScale = newTraitData.DescriptionTextSymbolScale or descriptionText.TextSymbolScale
	descriptionText.Id = traitInfo.PurchaseButton.Id
	CreateTextBoxWithFormat( descriptionText )

	if not newTraitData.HideStatLinesInCodex then
		local statLines = newTraitData.StatLines
		if newTraitData.CustomStatLinesWithShrineUpgrade ~= nil and GetNumShrineUpgrades( newTraitData.CustomStatLinesWithShrineUpgrade.ShrineUpgradeName ) > 0 then
			statLines = newTraitData.CustomStatLinesWithShrineUpgrade.StatLines
		end
		if statLines ~= nil then
			local appendToId = descriptionText.Id
			for lineNum, statLine in ipairs( statLines ) do
				if statLine ~= "" then

					local offsetY = (lineNum - 1) * screenData.LineHeight
				
					local statLineLeft = ShallowCopyTable( screenData.StatLineLeft )
					statLineLeft.Id = traitInfo.PurchaseButton.Id
					statLineLeft.Text = statLine
					statLineLeft.OffsetY = offsetY
					statLineLeft.AppendToId = appendToId
					statLineLeft.LuaValue = newTraitData
					CreateTextBoxWithFormat( statLineLeft )

					local statLineRight = ShallowCopyTable( screenData.StatLineRight )
					statLineRight.Id = traitInfo.PurchaseButton.Id
					statLineRight.Text = statLine
					statLineRight.OffsetY = offsetY
					statLineRight.AppendToId = appendToId
					statLineRight.LuaValue = newTraitData
					CreateTextBoxWithFormat( statLineRight )

				end
			end
		end
	end

	if newTraitData.FlavorText ~= nil then
		local flavorText = ShallowCopyTable( screenData.FlavorText )
		flavorText.Id = traitInfo.PurchaseButton.Id
		flavorText.Text = newTraitData.FlavorText
		CreateTextBox( flavorText )
	end

	local rarityText = ShallowCopyTable( screenData.RarityText )
	rarityText.Id = traitInfo.PurchaseButton.Id
	rarityText.Text = overrideRarityName or newTraitData.CustomRarityName or "Boon_"..tostring(rarity)
	rarityText.Color = rarityColor 
	CreateTextBox( rarityText )

	local highlight = ShallowCopyTable( screenData.Highlight )
	highlight.X = purchaseButton.X
	highlight.Y = purchaseButton.Y
	highlight.Group = "Combat_Menu_TraitTray_Overlay"
	button.Highlight = CreateScreenComponent( highlight )
	traitInfo.Highlight = button.Highlight
	
	local icon = ShallowCopyTable( screenData.Icon )
	icon.X = screenData.IconOffsetX + itemLocationX + screenData.ButtonOffsetX
	icon.Y = screenData.IconOffsetY + itemLocationY
	icon.Group = "Combat_Menu_TraitTray_Overlay"
	traitInfo.Icon = CreateScreenComponent( icon )

	if not newTraitData.NoFrame then
		local frame = ShallowCopyTable( screenData.Frame )
		frame.X = screenData.IconOffsetX + itemLocationX + screenData.ButtonOffsetX
		frame.Y = screenData.IconOffsetY + itemLocationY
		frame.Group = "Combat_Menu_TraitTray_Overlay"
		frame.Animation = "Frame_Boon_Menu_"..( newTraitData.Frame or rarity )
		traitInfo.Frame = CreateScreenComponent( frame )
	end

	traitInfo.QuestIcon = CreateScreenComponent({
		Name = "BlankObstacle",
		Group = "Combat_Menu_TraitTray_Overlay",
		X = offset.X + screenData.QuestIconOffsetX + ScreenCenterNativeOffsetX,
		Y = offset.Y + screenData.QuestIconOffsetY + ScreenCenterNativeOffsetY
	})
	traitInfo.TraitName = traitName
	traitInfo.Index = index

	traitInfo.PinIcon = CreateScreenComponent({
		Name = "BlankObstacle",
		Group = "Combat_Menu_TraitTray_Overlay",
		Animation = "StoreItemPin",
		Alpha = 0.0,
		X = offset.X + ScreenData.UpgradeChoice.PinOffsetX + ScreenCenterNativeOffsetX,
		Y = offset.Y + ScreenData.UpgradeChoice.PinOffsetY + ScreenCenterNativeOffsetY
	})
	traitInfo.PurchaseButton.PinButtonId = traitInfo.PinIcon.Id
	if HasStoreItemPin( traitName ) then
		SetAlpha({ Id = traitInfo.PinIcon.Id, Fraction = 1 })
		-- Silent toolip
		CreateTextBox({ Id = button.Id, TextSymbolScale = 0, Text = "NeededPinBoonTooltip_Codex", Color = Color.Transparent })
	end
	
	if IsGameStateEligible( screen, TraitRarityData.ElementalGameStateRequirements ) and not IsEmpty( newTraitData.Elements ) then
		local elementName = GetFirstValue( newTraitData.Elements )
		local elementIcon = ShallowCopyTable( screenData.ElementIcon )
		elementIcon.Group = "Combat_Menu_TraitTray_Overlay"
		elementIcon.Name = TraitElementData[elementName].Icon
		elementIcon.X = itemLocationX + elementIcon.XShift
		elementIcon.Y = itemLocationY + elementIcon.YShift
		local elementIconComponent = CreateScreenComponent( elementIcon )
		table.insert( traitInfo.Components, elementIconComponent )
	end
	
	SetTraitTrayDetails(
	{
		TraitData = newTraitData, 
		ForBoonInfo = true,
		--DetailsBox = traitInfo.DetailsBacking,
		--RarityBox = traitInfo.RarityBox, 
		--TitleBox = traitInfo.TitleBox, 
		Patch = traitInfo.Patch, 
		Icon = traitInfo.Icon, 
		Frame = traitInfo.Frame,
		--StatLines = traitInfo.StatlineBackings,
		--ElementalIcons = traitInfo.ElementalIcons 
	})

	if not GameState.TraitsTaken[traitName] and not GameState.ItemInteractions[traitName] and HasActiveQuestForName( traitName ) then
		SetAnimation({ DestinationId = traitInfo.QuestIcon.Id, Name = "QuestItemFound" })
	else
		SetAnimation({ DestinationId = traitInfo.QuestIcon.Id, Name = "Blank" })
	end

	BoonInfoScreenUpdateTooltipToggle( screen, button )

	-- override start
	if boonState == BoonState.Denied and CurrentHubRoom == nil then
		local bannedOverlay = CreateScreenComponent({ Name = "BlankObstacle", Group = "Combat_Menu_TraitTray_Overlay", Animation = "BoonInfoSlotLocked", X = purchaseButton.X, Y = purchaseButton.Y })
		table.insert( traitInfo.Components, bannedOverlay )
	end

	
	local traitToReplace = GetSacrificeBoon(traitName)
	if traitToReplace ~= nil then

		screen.TraitToReplaceName = traitToReplace

		local exchangeSymbol = CreateScreenComponent({ Name = "BlankObstacle", Group = "Combat_Menu_TraitTray_Overlay", Scale = screenData.ExchangeSymbol.Scale })
		table.insert( traitInfo.Components, exchangeSymbol )
		Attach({ Id = exchangeSymbol.Id, DestinationId = traitInfo.PurchaseButton.Id, OffsetX = screenData.ExchangeSymbol.OffsetX, OffsetY = screenData.ExchangeSymbol.OffsetY })
		SetAnimation({ DestinationId = exchangeSymbol.Id, Name = "TraitExchangeSymbol" })
		
		local exchangeIcon = CreateScreenComponent({ Name = "BlankObstacle", Group = "Combat_Menu_TraitTray_Overlay", Scale = screenData.Icon.Scale * screenData.ExchangeIconScale })
		table.insert( traitInfo.Components, exchangeIcon )
		Attach({ Id = exchangeIcon.Id, DestinationId = traitInfo.PurchaseButton.Id, OffsetX = screenData.ExchangeIconOffsetX, OffsetY = screenData.ExchangeIconOffsetY })
		SetAnimation({ DestinationId = exchangeIcon.Id, Name = TraitData[traitToReplace].Icon })

		local exchangeIconFrame = CreateScreenComponent({ Name = "BlankObstacle", Group = "Combat_Menu_TraitTray_Overlay", Scale = screenData.Icon.Scale * screenData.ExchangeIconScale })		
		table.insert( traitInfo.Components, exchangeIconFrame )
		Attach({ Id = exchangeIconFrame.Id, DestinationId = traitInfo.PurchaseButton.Id, OffsetX = screenData.ExchangeIconOffsetX, OffsetY = screenData.ExchangeIconOffsetY })
		SetAnimation({ DestinationId = exchangeIconFrame.Id, Name = "BoonIcon_Frame_Rare" })
	end
	-- override end
	
end)



modutil.mod.Path.Override("CreateTraitRequirementList", function(screen, headerTextArgs, traitList, startY, metRequirement)
	if traitList == nil then
		return
	end
	local originalY = startY
	local headerText = headerTextArgs.Text
	if TableLength(traitList) == 1 and headerTextArgs.TextSingular then
		headerText = headerTextArgs.TextSingular
	end
	
	-- override START
	-- TwoOf isn't used but won't work anyway in current game codebase.
	--  Still, we're implementing against it by pattern matching on the value of headerTextArgs.Text
	--  Its value is always either BoonInfo_OneOf, either BoonInfo_TwoOf, thus we extract first part
	--  retrieving OneOf or TwoOf.
	-- We can then retrieve the corresponding requirement state by calling GetRequirementState()
	local color = Color.White
	if metRequirement then -- Not sure what it is for but let's keep it in
		color = Color.BoonInfoAcquired
	else
		local reqType = string.match(headerTextArgs.Text, "^BoonInfo_(.*)$")
		color = BoonColors.Requirement.Header[GetRequirementState(traitList, reqType)]
	end
	-- override END

	local listRequirementHeaderFormat = ShallowCopyTable( ScreenData.BoonInfo.ListRequirementHeaderFormat )
	listRequirementHeaderFormat.Id = screen.Components.RequirementsText.Id
	listRequirementHeaderFormat.Text = headerText
	listRequirementHeaderFormat.Color = color
	listRequirementHeaderFormat.OffsetY = startY
	CreateTextBox( listRequirementHeaderFormat )

	startY = startY + ScreenData.BoonInfo.ListRequirementHeaderSpacingY
	local sharedGod = nil
	local allSame = true
	for i, traitName in ipairs( traitList ) do
		local traitData = TraitData[traitName]
		if traitData.CodexGameStateRequirements == nil or IsGameStateEligible( traitData, traitData.CodexGameStateRequirements ) then 
			local lootSourceName = GetLootSourceName( traitName, { ForBoonInfo = true } )
			if not sharedGod then
				sharedGod = lootSourceName
			elseif sharedGod ~= lootSourceName and not LootData[sharedGod].TraitIndex[traitName] then
				allSame = false
			end
		
			-- override START
			-- For each boon, we get its current state, and then take the corresponding table
			local listRequirementFormat = CreateListRequirementFormatTableWithColor(BoonColors.Requirement.BulletList[GetBoonState(traitName)])
			-- override END
			listRequirementFormat.Id = screen.Components.RequirementsText.Id
			listRequirementFormat.OffsetY = startY
			listRequirementFormat.LuaValue = { TraitName = traitName }
			CreateTextBox( listRequirementFormat )

			startY = startY + ScreenData.BoonInfo.ListRequirementSpacingY
		end
	end

	local headerIcon = ScreenData.BoonInfo.GenericHeaderIcon
	local headerIconScale = ScreenData.BoonInfo.GenericHeaderIconScale
	if allSame and sharedGod and LootData[sharedGod].BoonInfoIcon then
		headerIcon = LootData[sharedGod].BoonInfoIcon
		headerIconScale = ScreenData.BoonInfo.GodIconScale
	end
	local godPlate = CreateScreenComponent({ Name = "BlankObstacle", Group = "Combat_Menu_TraitTray", Animation = headerIcon, Scale = headerIconScale, Alpha = 0.0 })
	table.insert( screen.TraitRequirements, godPlate.Id )
	Attach({ Id = godPlate.Id, DestinationId = screen.Components.RequirementsText.Id, OffsetY = originalY })
	if not screen.ShowTooltips then
		SetAlpha({ Id = godPlate.Id, Fraction = 1.0, Duration = 0.2 })
	end

	startY = startY + ScreenData.BoonInfo.ListRequirementHeaderSpacingY
	return startY
end)
