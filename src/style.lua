---@alias Color table<integer,integer,integer,integer>

---Convert a string hexa value into a Color table
---@param hexStr string
---@return Color?
local function HexStrToColor(hexStr)
	local hex = hexStr:lower():gsub("^#", ""):gsub("^0x", "")

	local r, g, b, a = hex:match("^(%x%x)(%x%x)(%x%x)(%x?%x?)$")

	if not r then
		return nil
	end

	return {
		tonumber(r, 16),
		tonumber(g, 16),
		tonumber(b, 16),
		tonumber(a ~= "" and a or "ff", 16),
	}
end

---Get a game Color string value into its defined value.
---@param gameColorStr string
---@return Color?
local function GameColorStrToColor(gameColorStr)
	local name = gameColorStr:match("^Color%.(%w+)$")

	if not name or not game.Color[name] then
		return nil
	end

	return game.Color[name]
end

---Get the color from a string, defaults to Color.White (#FFFFFFFF)
---@param str string
function StrToColor(str)
	if type(str) ~= "string" then
		modutil.mod.Print("Error: not a string, defaulting to white")
		return game.Color.White
	end

	local color = HexStrToColor(str) or GameColorStrToColor(str)
	if not color then
		modutil.mod.Print("Error: Can't find color for " .. str .. ", defaulting to white")
		return game.Color.White
	end

	return color
end

function ClampAlpha(num)
	if type(num) ~= "number" then
		modutil.mod.Print("Error: not a number, defaulting to 255")
		return 255
	end

	return (num < 0 and 0) or (num > 255 and 255) or num
end
