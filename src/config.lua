local config = {
  enabled = true,
  sacrificeBoonsAlwaysAsAvailable = false,
  enablePinnedBoonsIconInRequirements = true,
  enableBannedBoonsIconInRequirements = true,
}

local configDesc = {
  enabled = "Whether the mod is enabled or not",
  sacrificeBoonsAlwaysAsAvailable = "Set to true to always consider sacrifice/replacement boons as available. This can be useful if you often use vow of denial as those will appear more often.",
  enablePinnedBoonsIconInRequirements = "Set to true to display pin icon next to pinned/tracked boons in the requirements list.",
  enableBannedBoonsIconInRequirements = "Set to true to display locked icon next to banned boons in the requirements list.",
}

return config, configDesc
