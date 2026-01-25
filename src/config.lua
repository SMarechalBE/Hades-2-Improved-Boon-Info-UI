local function MakeOverride(defaultOverride, defaultValue)
	return {
		Override = defaultOverride,
		Value = defaultValue,
	}
end

local function ColorDescription(default)
	if not default then
		default = "unknown"
	end
	return MakeOverride(
		"Override default color",
		"Hexadecimal RGB or RGBA color value (e.g. '#FFFFFFFF'), providing no alpha makes it FF by default. Default: "
			.. default
	)
end

local function AlphaDescription(default)
	if not default then
		default = "unknown"
	end
	return MakeOverride(
		"Override alpha for the default/custom color. Default: " .. default,
		"Alpha value, use a value in the range [0, 255]"
	)
end

local function ButtonTitleDescription(defaultColor, defaultAlpha)
	return {
		Color = ColorDescription(defaultColor),
		Alpha = AlphaDescription(defaultAlpha),
	}
end

local function BulletListDescription(defaultColor, defaultAlpha)
	return {
		Color = ColorDescription(defaultColor),
		Alpha = AlphaDescription(defaultAlpha),
		ShadowColor = ColorDescription("00000001"),
	}
end

local function HeaderDescription(defaultColor, defaultAlpha)
	return ButtonTitleDescription(defaultColor, defaultAlpha)
end

local config = {
	enabled = true,
	sacrificeBoonsAlwaysAsAvailable = false,
	unreplaceableSacrificeBoonsAsBanned = true,
	IconInRequirements = {
		Pinned = { Enable = true },
		Banned = { Enable = true },
	},
	Filtering = {
		DefaultLandingPage = MakeOverride(false, "All"),
	},
	AvailabilityStyle = {
		Picked = {
			Enable = true,
			ButtonTitle = {
				Color = MakeOverride(false, "ffffffff"),
				Alpha = MakeOverride(false, 255),
			},
			BulletList = {
				Color = MakeOverride(false, "ffffffff"),
				Alpha = MakeOverride(false, 255),
				ShadowColor = MakeOverride(false, "00000001"),
			},
		},
		Available = {
			Enable = true,
			ButtonTitle = {
				Color = MakeOverride(false, "ffffffff"),
				Alpha = MakeOverride(false, 255),
			},
			BulletList = {
				Color = MakeOverride(false, "ffffffff"),
				Alpha = MakeOverride(false, 255),
				ShadowColor = MakeOverride(false, "00000001"),
			},
			Header = {
				Color = MakeOverride(false, "ffffffff"),
				Alpha = MakeOverride(false, 255),
			},
		},
		Unfulfilled = {
			Enable = true,
			ButtonTitle = {
				Color = MakeOverride(false, "ffffffff"),
				Alpha = MakeOverride(false, 255),
			},
			BulletList = {
				Color = MakeOverride(false, "ffffffff"),
				Alpha = MakeOverride(false, 255),
				ShadowColor = MakeOverride(false, "00000001"),
			},
			Header = {
				Color = MakeOverride(false, "ffffffff"),
				Alpha = MakeOverride(false, 255),
			},
		},
		SlotUnavailable = {
			Enable = true,
			ButtonTitle = {
				Color = MakeOverride(false, "ffffffff"),
				Alpha = MakeOverride(false, 255),
			},
			BulletList = {
				Color = MakeOverride(false, "ffffffff"),
				Alpha = MakeOverride(false, 255),
				ShadowColor = MakeOverride(false, "00000001"),
			},
			Header = {
				Color = MakeOverride(false, "ffffffff"),
				Alpha = MakeOverride(false, 255),
			},
		},
		GodUnavailable = {
			Enable = true,
			ButtonTitle = {
				Color = MakeOverride(false, "ffffffff"),
				Alpha = MakeOverride(false, 255),
			},
			BulletList = {
				Color = MakeOverride(false, "ffffffff"),
				Alpha = MakeOverride(false, 255),
				ShadowColor = MakeOverride(false, "00000001"),
			},
			Header = {
				Color = MakeOverride(false, "ffffffff"),
				Alpha = MakeOverride(false, 255),
			},
		},
		Banned = {
			Enable = true,
			ButtonTitle = {
				Color = MakeOverride(false, "ffffffff"),
				Alpha = MakeOverride(false, 255),
			},
			BulletList = {
				Color = MakeOverride(false, "ffffffff"),
				Alpha = MakeOverride(false, 255),
				ShadowColor = MakeOverride(false, "00000001"),
			},
			Header = {
				Color = MakeOverride(false, "ffffffff"),
				Alpha = MakeOverride(false, 255),
			},
		},
	},
}

local configDesc = {
	enabled = "Whether the mod is enabled or not",
	sacrificeBoonsAlwaysAsAvailable = "Set to true to always consider sacrifice/replacement boons as available. This can be useful if you often use vow of denial as those will appear more often.",
	unreplaceableSacrificeBoonsAsBanned = "Set to true to always consider sacrifice/replacement boons for currently equipped Heroic boons as banned. Defaults to true",
	IconInRequirements = {
		Pinned = { Enable = "Set to true to display pin icon next to pinned/tracked boons in the requirements list." },
		Banned = { Enable = "Set to true to display locked icon next to banned boons in the requirements list." },
	},
	Filtering = {
		DefaultLandingPage = MakeOverride(
			"Enable setting a default filter landing page override",
			"Acceptable values: Available, Unfulfilled, Unavailable, All"
		),
	},
	AvailabilityStyle = {
		Picked = {
			Enable = "Enable custom style for picked boons.",
			ButtonTitle = ButtonTitleDescription("Color.BoonInfoAcquired (light green)", "/"),
			BulletList = BulletListDescription("Color.White", "/"),
		},
		Available = {
			Enable = "Enable custom style for available boons.",
			ButtonTitle = ButtonTitleDescription("Rarity", "/"),
			BulletList = BulletListDescription("'#34303AB9' (greyish)", "/"),
			Header = HeaderDescription("Color.BoonInfoAcquired (light green)", "/"),
		},
		Unfulfilled = {
			Enable = "Enable custom style for unfulfilled boons.",
			ButtonTitle = ButtonTitleDescription("Rarity", "120"),
			BulletList = BulletListDescription("'#34303AB9' (greyish)", "50"),
			Header = HeaderDescription("Color.White", "/"),
		},
		SlotUnavailable = {
			Enable = "Enable custom style for sacrifice/replacement boons.",
			ButtonTitle = ButtonTitleDescription("Color.BonesUnaffordable (dark red)", "/"),
			BulletList = BulletListDescription("Color.BonesUnaffordable (dark red)", "185"),
			Header = HeaderDescription("Color.BonesUnaffordable (dark red)", "/"),
		},
		GodUnavailable = {
			Enable = "Enable custom style for out of god-pool boons.",
			ButtonTitle = ButtonTitleDescription("Color.BonesLocked (dark blue)", "/"),
			BulletList = BulletListDescription("Color.BonesLocked (dark blue)", "185"),
			Header = HeaderDescription("Color.BonesLocked (dark blue)", "/"),
		},
		Banned = {
			Enable = "Enable custom style for banned boons.",
			ButtonTitle = ButtonTitleDescription("Rarity", "120"),
			BulletList = BulletListDescription("Color.BonesInactive (blackish/dark blue)", "185"),
			Header = HeaderDescription("Color.BonesInactive (blackish/dark blue)", "/"),
		},
	},
}

return config, configDesc
