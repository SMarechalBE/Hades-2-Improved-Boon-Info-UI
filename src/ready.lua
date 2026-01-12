---@meta _
-- globals we define are private to our plugin!
---@diagnostic disable: lowercase-global

--#region SJSON hook

---Add Pin Icon as an animation in VFX

local bulletPointPinIconAnimationName = "BulletPointPinIcon"

function sjson_BulletPointPinIcon(data)
	local bulletPointPinned =
	{
		Name = bulletPointPinIconAnimationName,
		FilePath = "GUI\\Icons\\Reminder",
		Material = "Unlit" -- Not sure what this is for
	}
	local order = {"Name", "FilePath", "Material"}
	table.insert(data.Animations, sjson.to_object(bulletPointPinned, order))
end

local vfxFile = rom.path.combine(rom.paths.Content, 'Game/Animations/GUI_Screens_VFX.sjson')
sjson.hook(vfxFile, function(data)
	return sjson_BulletPointPinIcon(data)
end)

--#endregion SJSON hook

--#region definitions
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

---@enum BoonUnfulfilledState
BoonUnfulfilledState =
{
	SlotUnavailable = "SlotUnavailable",
	GodUnavailable = "GodUnavailable",
}

---@enum RequirementType
RequirementType =
{
	OneOf = "OneOf",
	TwoOf = "TwoOf",
	OneFromEachSet = "OneFromEachSet",
}
--#endregion definitions

--#region style

local function ChangeAlpha(color, alpha)
	local newColor = game.ShallowCopyTable(color)
	newColor[4] = alpha

	return newColor
end

local GreyishColor = { 52, 48, 58, 185 }
local BaseColor =
{
	SlotUnavailable = Color.BonesUnaffordable,
	GodUnavailable = Color.BonesLocked,
	Denied = Color.BonesInactive,
	Picked = Color.BoonInfoAcquired
}
local BaseAlpha =
{
	Full = 255,
	AlmostFull = 185,
	UnfulfilledRarity = 120,
	Unfulfilled = 50,
}

BoonColors =
{
	Title =
	{
		Value =
		{
			Picked = BaseColor.Picked,
			SlotUnavailable = BaseColor.SlotUnavailable,
			GodUnavailable = BaseColor.GodUnavailable,
		},
		Alpha =
		{
			Default = BaseAlpha.Full,

			Available = BaseAlpha.Full,
			Unfulfilled = BaseAlpha.UnfulfilledRarity,
			Denied = BaseAlpha.UnfulfilledRarity,
		},
	},
	Requirement =
	{
		Header =
		{
			Available = BaseColor.Picked,
			Unfulfilled = Color.White,
			SlotUnavailable = BaseColor.SlotUnavailable,
			GodUnavailable = BaseColor.GodUnavailable,
			Denied = BaseColor.Denied, -- black-ish
		},
		BulletList =
		{
			Picked = Color.White,
			SlotUnavailable = ChangeAlpha(BaseColor.SlotUnavailable, BaseAlpha.AlmostFull),
			GodUnavailable = ChangeAlpha(BaseColor.GodUnavailable, BaseAlpha.AlmostFull),
			Available = GreyishColor,
			Unfulfilled = ChangeAlpha(GreyishColor, BaseAlpha.Unfulfilled),
			Denied = ChangeAlpha(BaseColor.Denied, BaseAlpha.AlmostFull),
		},
		Shadow =
		{
			Color =
			{
				Default = {0, 0, 0, 1},
			},
			Offset =
			{
				Default = {0, 1},

				Available = {0, 0},
				Unfulfilled = {0, 0},
				Denied = {0, 0},
			},
		},
	},
}

-- Init colors from the config override values
for state, styleData in pairs(config.AvailabilityStyle) do
	if styleData.Enable then
		local buttonTitle = styleData.ButtonTitle
		if buttonTitle.Color.Override and buttonTitle.Color.Value then
			BoonColors.Title.Value[state] = StrToColor(buttonTitle.Color.Value)
		end
		if buttonTitle.Alpha.Override and buttonTitle.Alpha.Value then
			BoonColors.Title.Alpha[state] = ClampAlpha(buttonTitle.Alpha.Value)
		end

		local bulletList = styleData.BulletList
		if bulletList.Color.Override and bulletList.Color.Value then
			BoonColors.Requirement.BulletList[state] = StrToColor(bulletList.Color.Value)
		end
		if bulletList.Alpha.Override and bulletList.Alpha.Value then
			BoonColors.Requirement.BulletList[state] = ChangeAlpha(BoonColors.Requirement.BulletList[state], ClampAlpha(bulletList.Alpha.Value))
		end
		local shadowColor = bulletList.ShadowColor
		if  shadowColor.Override and shadowColor.Value then
			BoonColors.Requirement.Shadow.Color[state] = StrToColor(shadowColor.Value)
		end

		local header = styleData.Header
		if header and header.Color.Override and header.Color.Value then
			BoonColors.Requirement.Header[state] = StrToColor(header.Color.Value)
		end
		if header and header.Alpha.Override and header.Alpha.Value then
			BoonColors.Requirement.Header[state] = ChangeAlpha(BoonColors.Requirement.Header[state], ClampAlpha(header.Alpha.Value))
		end
	end
end

local function GetTitleColor(state, colorOverride)
	local color = BoonColors.Title.Value[state] or colorOverride or game.Color.White
	local alpha = BoonColors.Title.Alpha[state] or BoonColors.Title.Alpha.Default

	return ChangeAlpha(color, alpha)
end

local Icons =
{
	Scale = 0.35,
	Alpha = 1.0,
}

local function CreateListRequirementFormatTableWithColor(state)
	return {
		Text = "BoonInfo_BulletPoint",
		FontSize = 22,
		OffsetX = 30,
		Color = BoonColors.Requirement.BulletList[state] or GreyishColor,
		Font = "P22UndergroundSCMedium",
		ShadowBlur = 0,
		ShadowColor = BoonColors.Requirement.Shadow.Color[state] or BoonColors.Requirement.Shadow.Color.Default,
		ShadowOffset = BoonColors.Requirement.Shadow.Offset[state] or BoonColors.Requirement.Shadow.Offset.Default,
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
	"PlayerUnit", -- Enable it with Run Boon Overview (though this is not great pattern as it is hidden)
}

--#endregion style

--#region BoonInfo UI

modutil.mod.Path.Override("CreateBoonInfoButton", function(screen, traitName, index)
	--#region CreateBoonInfoButton
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
	--#endregion
	-- override start
	-- We retrieve boon state from GetBoonState, then retrieve the corresponding color
	local boonState = GetBoonState(traitName)
	titleText.Color = GetTitleColor(boonState, rarityColor)
	-- override end
	--#region CreateBoonInfoButton
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
--#endregion

	-- override start
	if boonState == BoonState.Denied and CurrentHubRoom == nil then
		local bannedOverlay = CreateScreenComponent({ Name = "BlankObstacle", Group = "Combat_Menu_TraitTray_Overlay", Animation = "BoonInfoSlotLocked", X = purchaseButton.X, Y = purchaseButton.Y })
		table.insert( traitInfo.Components, bannedOverlay )
	end

	
	local traitToReplace = GetSacrificeBoon(traitName)
	if traitToReplace ~= nil then

		screen.TraitToReplaceName = traitToReplace -- Seems unnecessary, not sure why I added this

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
		local traitToReplaceData = GetHeroTrait(traitToReplace)
		local traitToReplaceRarity = traitToReplaceData and traitToReplaceData.Rarity or "Rare" -- Fallback to rare just in case
		SetAnimation({ DestinationId = exchangeIconFrame.Id, Name = "BoonIcon_Frame_" .. traitToReplaceRarity })
	end
	-- override end
	
end)

modutil.mod.Path.Override("CreateTraitRequirementList", function(screen, headerTextArgs, traitList, startY, metRequirement)
	--#region CreateTraitRequirementList
	if traitList == nil then
		return
	end
	local originalY = startY
	local headerText = headerTextArgs.Text
	if TableLength(traitList) == 1 and headerTextArgs.TextSingular then
		headerText = headerTextArgs.TextSingular
	end
	--#endregion

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
		local boonState, unfulfilledState = GetRequirementState(traitList, reqType)
		color = BoonColors.Requirement.Header[unfulfilledState or boonState]
	end
	-- override END

	--#region CreateTraitRequirementList
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
		--#endregion CreateTraitRequirementList
			-- override START
			local reqBoonState = GetBoonState(traitName)
			-- Create bullet point
			local listRequirementFormat = CreateListRequirementFormatTableWithColor(reqBoonState)

			-- Add pin icon for pinned/tracked boons if elligible
			if config.IconInRequirements.Pinned.Enable and game.HasStoreItemPin(traitName) then
				local pinned = CreateScreenComponent({ Name = "BlankObstacle", Group = "Combat_Menu_TraitTray", Animation = bulletPointPinIconAnimationName, Scale = Icons.Scale, Alpha = Icons.Alpha })
				table.insert( screen.TraitRequirements, pinned.Id )
				Attach({ Id = pinned.Id, DestinationId = screen.Components.RequirementsText.Id, OffsetX = listRequirementFormat.OffsetX - 10, OffsetY = startY + 1 })
			end

			-- Add locked icon for banned boons if elligible
			if config.IconInRequirements.Banned.Enable and reqBoonState == BoonState.Denied then
				local strikeThrough = CreateScreenComponent({ Name = "BlankObstacle", Group = "Combat_Menu_TraitTray", Animation = "LockedKeepsakeIcon", Scale = Icons.Scale, Alpha = Icons.Alpha })
				table.insert( screen.TraitRequirements, strikeThrough.Id )
				Attach({ Id = strikeThrough.Id, DestinationId = screen.Components.RequirementsText.Id, OffsetX = listRequirementFormat.OffsetX - 12, OffsetY = startY + 1 })
			end
			-- override END

			listRequirementFormat.Id = screen.Components.RequirementsText.Id
			listRequirementFormat.OffsetY = startY
			listRequirementFormat.LuaValue = { TraitName = traitName }
			CreateTextBox( listRequirementFormat )

			--#region CreateTraitRequirementList
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
	--#endregion CreateTraitRequirementList
end)

--#endregion BoonInfo UI

--#region Filtering

BoonInfoFilterButtonsBar =
{
	X = game.UIData.ContextualButtonXRight,
	Y = game.UIData.ContextualButtonY,
	BottomOffset = game.UIData.ActionBarBottomOffset,
	AutoAlignContextualButtons = true,
	AutoAlignJustification = "Right",

	ChildrenOrder =
	{
		"NextFilter",
		"PreviousFilter",
	},

	Children =
	{
		NextFilter =
		{
			Graphic = "ContextualActionButton",
			Alpha = 0.0,
			Data =
			{
				-- Hotkey only
				OnPressedFunctionName = "BoonInfoScreenNextFilter",
				ControlHotkeys = { "MenuRight", },
			},
			Text = "Menu_NextCategory",
			TextArgs = game.UIData.ContextualButtonFormatRight,
		},

		PreviousFilter = 
		{
			Graphic = "ContextualActionButton",
			Alpha = 0.0,
			Data =
			{
				-- Hotkey only
				OnPressedFunctionName = "BoonInfoScreenPreviousFilter",
				ControlHotkeys = { "MenuLeft", },
			},
			Text = "Menu_PrevCategory",
			TextArgs = game.UIData.ContextualButtonFormatRight,
		},
	},
}

BoonInfoFilterTextBar =
{
	X = game.UIData.ContextualButtonXRight-300,
	Y = game.UIData.ContextualButtonY,
	BottomOffset = game.UIData.ActionBarBottomOffset+40,
	AutoAlignContextualButtons = true,
	AutoAlignJustification = "Left",

	ChildrenOrder =
	{
		"TextFilterType",
		-- "TextFilterLabel",
	},

	Children =
	{
		TextFilterType = 
		{
			Graphic = "ContextualActionButton",
			Alpha = 1.0,
			Text = "FILTER: NONE",
			TextArgs = game.UIData.ContextualButtonFormatLeft,
		},

		-- TextFilterLabel = 
		-- {
		-- 	Graphic = "ContextualActionButton",
		-- 	Alpha = 1.0,
		-- 	Text = "FILTER: ",
		-- 	TextArgs = game.UIData.ContextualButtonFormatRight,
		-- },
	},
}

table.insert(game.ScreenData.BoonInfo.ComponentData, BoonInfoFilterButtonsBar)
table.insert(game.ScreenData.BoonInfo.ComponentData, BoonInfoFilterTextBar)

modutil.mod.Path.Wrap("BoonInfoScreenNextFilter", function(base, screen, button)
	BoonInfoScreenNextFilter(screen, button)
end)

modutil.mod.Path.Wrap("BoonInfoScreenPreviousFilter", function(base, screen, button)
	BoonInfoScreenPreviousFilter(screen, button)
end)

modutil.mod.Path.Override("ShowBoonInfoScreen", function(args)

	local screen = DeepCopyTable( ScreenData.BoonInfo )
	screen.LootName = args.LootName
	screen.CodexScreen = args.CodexScreen
	screen.CodexEntryName = args.CodexEntryName
	screen.CodexEntryData = args.CodexEntryData
	if args.CloseFunctionName ~= nil then
		screen.CloseFunctionName = args.CloseFunctionName
		screen.CloseFunctionArgs = args.CloseFunctionArgs
	end
	OnScreenOpened( screen )
	CreateScreenFromData( screen, screen.ComponentData )
	-- Override start
	InitializeFilter(screen)
	-- Override end

	local components = screen.Components
	local sourceData = EnemyData[screen.LootName] or LootData[screen.LootName] or {}
	ModifyTextBox({ Id = components.TitleText.Id, Text = sourceData.BoonInfoTitleText or screen.CodexEntryData.BoonInfoTitle, LuaKey = "TempTextData", LuaValue = { BoonName = screen.LootName, WeaponName = screen.CodexEntryName } })
	
	PlaySound({ Name = "/SFX/Menu Sounds/GeneralWhooshMENULoud" })	

	if screen.CodexScreen ~= nil then
		screen.CodexScreen.Components.CloseButton.OnPressedFunctionName = nil
	end

	-- Override start 
	-- Moved BoonInfoPopulateTraits, CreateBoonInfoButtons, TeleportCursor
	-- and UpdateBoonInfoPageButtons inside RefreshBoons
	-- Maybe when ModUtil.Path.Context is fixed, this could be dealt with in a cleaner way ?
	RefreshBoons(screen)
	-- Override end

	screen.KeepOpen = true
	screen.CanClose = true
	HandleScreenInput( screen )

end)

--#endregion Filtering
