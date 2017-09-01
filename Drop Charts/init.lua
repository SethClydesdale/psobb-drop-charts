-- drop chart data was acquired from Ephinea
-- https://ephinea.pioneer2.net/drop-charts/normal/

-- imports
local core_mainmenu = require("core_mainmenu")
local lib_helpers = require("solylib.helpers")
local lib_characters = require("solylib.characters")
local lib_unitxt = require("solylib.unitxt")
local lib_items = require("solylib.items.items")
local lib_items_list = require("solylib.items.items_list")
local lib_items_cfg = require("solylib.items.items_configuration")
local drop_charts = {
  ["Normal"] = require("Drop Charts.normal"),
  ["Hard"] = require("Drop Charts.hard"),
  ["Very Hard"] = require("Drop Charts.very-hard"),
  ["Ultimate"] = require("Drop Charts.ultimate")
}

-- window vars
local window_open = false
local button_func = function()
  window_open = not window_open
end

-- memory addresses
local _SideMessage = pso.base_address + 0x006AECC8
local _Difficulty = 0x00A9CD68
local _Episode = 0x00A9B1C8

-- variables
local party = { }
local input = { }
local counter = 0
local update_interval = 10
local fontScale = 1

-- Auto/Manual Button Info
local mode = {
	["auto"] = {
		status = "auto",
		text = "Auto Mode",
		color = 0xFFFFFF00,
		tooltip = "Auto Mode: setting all options automatically. Type /partyinfo to refresh auto data"
	},
	["manual"] = {
		status = "manual",
		text = "Manual Mode",
		color = 0xFFEEEEEE,
		tooltip = "Manual Mode: setting all options manually. Click Toggle to grab options automatically (may need to type /partyinfo to refresh)"
	},
	status = "manual",
	initialStatus = true, -- first time run, will switch to Auto on first info grab
	changed = false,
	lastEpisode = nil
}

-- episode list
local episodes = {
    [0] = "EPISODE 1",
    [1] = "EPISODE 2",
    [2] = "EPISODE 4"
}

-- difficulty list
local difficulty = {
  "Normal",
  "Hard",
  "Very Hard",
  "Ultimate"
}

-- section id list 
local section = {
  "Bluefull",
  "Greenill",
  "Oran",
  "Pinkal",
  "Purplenum",
  "Redria",
  "Skyly",
  "Viridia",
  "Yellowboze",
  "Whitill"
}

-- section id colors
local section_color = {
  { 0.5, 0.7, 1 },
  { 0.5, 1, 0.4 },
  { 1, 0.7, 0.5 },
  { 1, 0.7, 1 },
  { 0.8, 0.7, 1 },
  { 1, 0.6, 0.6 },
  { 0.6, 1, 1 },
  { 0.5, 0.8, 0.5 },
  { 1, 1, 0.6 },
  { 0.9, 0.9, 0.9 }
}

-- difficulty colors
local difficulty_color = {
  { 0.5, 1, 0.5 },
  { 1, 1, 0.5 },
  { 1, 0.7, 0.5 },
  { 1, 0.5, 0.5 }
}

-- episode order
local episode = {
  "EPISODE 1",
  "EPISODE 1 Boxes",
  "EPISODE 2",
  "EPISODE 2 Boxes",
  "EPISODE 4",
  "EPISODE 4 Boxes"
}

-- column headers for the drop charts
local cols = {
  "Target",
  "Item"
}

-- create an ASCII separator
local separator = "+" .. string.rep("-", 86) .. "+" 
local function Separator(noNewLine)
  if noNewLine == nil then
    imgui.NewLine()
  end
  
  imgui.TextColored(0.6, 0.6, 0.6, 1, separator)
end

-- create an ASCII column
local function NextColumn(rep, offset)
  imgui.SameLine(0, offset or 0)
  imgui.TextColored(0.6, 0.6, 0.6, 1, rep and string.rep("|", rep) or "|")
  imgui.SameLine(0, offset or 0)
end

-- add padding to each side of the string until it meets the specified length
local function Pad(str, len)
  local after = false
  local percent = false
  
  -- the escaped percent counts as two, so remove it and add a placeholder
  if string.find(str, "%%") then
    str = string.gsub(str, "%%", "") .. "?"
    percent = true
  end
  
  -- increase the string's length by adding whitespace until it satisfies the condition
  while string.len(str) < len do
    if after == true then
      str = str .. " "
      after = false
    else
      str = " " .. str
      after = true
    end
  end
  
  -- finally add the percent back, if it was removed
  if percent then
    str = string.gsub(str, "?", "%%%%")
  end
  
  return str
end

-- color the specified keywords
local function ColorKeyword(...) 
  local args = {...}
  local max = table.getn(args)
  local keyword
  local color
  
  -- if a table is the first argument use that instead
  if type(args[1]) == "table" then
    args = args[1]
    max = table.getn(args)
  end
  
  -- loop over the keywords and color them
  for i = 1, #args do
    keyword = string.lower(args[i])
    
    -- find the keyword's color
    if keyword == "viridia" then
      color = { 0, 0.70, 0 }
    elseif keyword == "greenill" then
      color = { 0.50, 1, 0 }
    elseif keyword == "skyly" then
      color = { 0.30, 255, 255 }
    elseif keyword == "bluefull" then
      color = { 0, 0.50, 1 }
    elseif keyword == "purplenum" then
      color = { 0.65, 0.30, 1 }
    elseif keyword == "pinkal" then
      color = { 1, 0.6, 1 }
    elseif keyword == "redria" then
      color = { 1, 0, 0 }
    elseif keyword == "oran" then
      color = { 1, 0.65, 0.30 }
    elseif keyword == "yellowboze" then
      color = { 1, 1, 0 }
    elseif keyword == "whitill" then
      color = { 0.7, 0.7, 0.7 }
    elseif keyword == "normal" then
      color = { 0, 1, 0 }
    elseif keyword == "hard" then
      color = { 1, 1, 0 }
    elseif keyword == "very hard" then
      color = { 1, 0.5, 0 }
    elseif keyword == "ultimate" then
      color = { 1, 0, 0 }
    end

    -- write the keyword on the same line
    imgui.SameLine(0, 0)
    if color ~= nil then
      imgui.TextColored(color[1], color[2], color[3], 1, args[i])
    else
      imgui.Text(args[i])
    end
    
    -- add a comma to separate multiple keywords
    if i ~= max then
      imgui.SameLine(0, 0)
      imgui.Text(", ")
    end
  end
end

-- read side message from memory buffer
local function get_side_text()
	local ptr = pso.read_u32(_SideMessage)
	if ptr ~= 0 then
		local text = pso.read_wstr(ptr + 0x14, 0xFF)
		return text
	end
	return ""
end

-- extract party dar, rare boosts, section id, and grab episode and difficulty
local function parse_side_message(text)
    local data = { }
	
	-- logic in identifying dar and rare boost
    local dropIndex = string.find(text, "Drop")
	local rareIndex = string.find(text, "Rare")
	local idIndex = string.find(text, "ID")
	
	local dropStr = string.sub(text,dropIndex, rareIndex-1)
	local rareStr = string.sub(text,rareIndex, -1)
	local idStr = string.sub(text, idIndex+4, dropIndex-1)

	-- other data
	local _difficulty = pso.read_u32(_Difficulty)
	local _episode = pso.read_u32(_Episode)
	
    data.dar = tonumber(string.match(dropStr, "%d+"))
	data.rare = tonumber(string.match(rareStr, "%d+"))
	data.id = string.match(idStr,"%a+")
	data.difficulty = _difficulty + 1
	data.episode = episodes[_episode]
	
	return data
end

-- show tooltip with computed values
local getToolTip = function(item)

	local custom
	
	if mode.status == "auto" then
		custom = {
			dar   = tonumber(party.dar),
			rare  = tonumber(party.rare)
		}
	else
		custom = {
			dar   = tonumber(input.dar),
			rare  = tonumber(input.rare)
		}
	end
	
	-- check party dar/rare values and use default values if not set
	if custom.dar == nil or custom.dar < 0 then
		custom.dar = 100
	end
	if custom.rare == nil or custom.rare < 0 then
		custom.rare = 100
	end
	
	-- get default item percentage
	local percent = item.dar * item.rare / 100
	local denom = 100 / percent
	
	-- factor party dar/rare bonuses into item's dar/rare
	local computedDar = (custom.dar * item.dar) / 100
	if computedDar > 100 then
		computedDar = 100
	end
	local computedRare = (custom.rare * item.rare) / 100
	if computedRare > 100 then
		computedRare = 100
	end
	
	-- get differences after computation
	local darDelta = computedDar - item.dar
	local rareDelta =  computedRare - item.rare
	
	-- get adjusted item percentage via computed dar/rare
	local computedPercent = computedDar * computedRare / 100
	local computedDenom = 100 / computedPercent
	
	-- formulate drop strings
	local drop = "Drop: 1/"..string.format("%.2f",denom)..string.format(" (%.2f%s)",percent,"%%%%")
	local adjustedDrop = "Drop: 1/"..string.format("%.2f",computedDenom)..string.format(" (%.2f%s)",computedPercent,"%%%%")
	
	-- generate tooltip
	imgui.BeginTooltip()
	
		imgui.SetWindowFontScale(fontScale)
		
		-- if party or item's dar has been adjusted
		if custom.dar ~= 100 and item.dar ~= computedDar then
			lib_helpers.TextC(false, 0xFFFFFFFF, "Adjusted ")
		end
		lib_helpers.TextC(false, 0xFFFFFFFF, "DAR: ")
		
		local color = 0xFFFFFFFF
		if computedDar == 100 then
			color = 0xFFFFFF00
		end
		lib_helpers.TextC(false, color, string.format("%.0f%s",computedDar,"%%%%"))
		
		-- display color-coded DAR delta
		if darDelta > 0 and custom.dar ~= 100 then
			lib_helpers.TextC(false, 0xFF00FF00, " +"..string.format("%.0f%s",darDelta, "%%%%"))
		elseif darDelta < 0 and custom.dar ~= 100 then
			lib_helpers.TextC(false, 0xFFFF0000, " "..string.format("%.0f%s",darDelta, "%%%%"))
		end
		
		imgui.NewLine()
		
		-- if party rare is not 100%
		if custom.rare ~= 100 then
			lib_helpers.TextC(false, 0xFFFFFFFF, "Adjusted ")
		end
		lib_helpers.TextC(false, 0xFFFFFFFF, "Rare: ")
		
		color = 0xFFFFFFFF
		if computedRare == 100 then
			color = 0xFFFFFF00
		end
		-- for rare enemies, etc, no decimals
		local rareStr = string.format("%.5f%s",computedRare,"%%%%")
		if computedRare > 19 then
			rareStr = string.format("%.1f%s",computedRare,"%%%%")
		end
		lib_helpers.TextC(false, color, rareStr)
		
		-- display color-coded RARE delta
		local deltaStr = string.format("%.4f",rareDelta)
		if computedRare > 19 then
			deltaStr = string.format("%.1f",rareDelta)
		end
		if rareDelta > 0 and custom.rare ~= 100 then
			lib_helpers.TextC(false, 0xFF00FF00, " +" .. deltaStr)
		elseif rareDelta < 0 and custom.rare ~= 100 then
			lib_helpers.TextC(false, 0xFFFF0000, " " .. deltaStr)
		end
		
		imgui.NewLine()
		
		-- If drop rate is different, show original drop rate string
		if item.dar ~= computedDar or item.rare ~= computedRare then
			lib_helpers.TextC(true, 0xFF888888, drop)
		end
		lib_helpers.TextC(true, 0xFFFFFFFF, adjustedDrop)
	
	imgui.EndTooltip()
end

-- Set Mode (Auto/Manual)
local setMode = function(status)
	mode.status = status
	mode.changed = true
end

-- Party Dar/Rare inputs/configuration
local getPartyConfig = function()
  local darSuccess
  local rareSuccess
  
  -- if Auto Mode, grab party dar
  if mode.status == "auto" then
	input.dar = party.dar
  end
  
  -- if uninitialized, use defaults
  if input.dar == nil then
  	input.dar = "100"
  end
  
  imgui.PushItemWidth(68)
  darSuccess, input.dar = imgui.InputText("% DAR",string.format("%s",input.dar), 255)
  imgui.PopItemWidth()
  
  -- if changed, enter Manual Mode
  if darSuccess then
	setMode("manual")
  end
  
  if input.dar == "" or input.dar == nil or tonumber(input.dar) == nil then
	input.dar = "100"
  end
  
  -- if Auto Mode, grab party rare
  if mode.status == "auto" then
	input.rare = party.rare
  end
  
  -- if uninitialized, use defaults
  if input.rare == nil then
  	input.rare = "100"
  end
  
  imgui.PushItemWidth(68)
  rareSuccess, input.rare = imgui.InputText("% Rare Rate",string.format("%s",input.rare), 255)
  imgui.PopItemWidth()
  
  -- if changed, enter Manual Mode
  if rareSuccess then
	setMode("manual")
  end
  
  if input.rare == "" or input.rare == nil or tonumber(input.rare) == nil then
	input.rare = "100"
  end
  
  -- create Toggle button with instructions
  local autoString = " " .. mode[mode.status].text
  if mode.status == "auto" and party.dar == nil then
	autoString = autoString .. " > Type /partyinfo to refresh..."
  end
  if imgui.Button("Toggle") then
	if mode.status == "auto" then
		setMode("manual")
	else
		setMode("auto")
	end
  end
  
  -- display current Mode, with tooltip
  lib_helpers.TextC(false,mode[mode.status].color, autoString)
  if imgui.IsItemHovered() then
	imgui.BeginTooltip()
		lib_helpers.TextC(false,0xFFFFFFFF, mode[mode.status].tooltip)
	imgui.EndTooltip()
  end
end

-- draw the drop charts
local difficultyChanged = true
local selectedDifficulty = 1
local sectionChanged = true
local selectedSection = 1
local padding = 42
local drawDropCharts = function()

	imgui.SetWindowFontScale(fontScale)
	
	-- if Auto Mode, set selectedSection and selectedDifficulty
	if mode.status == "auto" then
		if party.id ~= nil then
			for k, v in pairs(section) do
				if v == party.id then
					selectedSection = k
				end
			end
		end
		if party.difficulty ~= nil then
			selectedDifficulty = party.difficulty
		end
	end
  
  -- difficulty drop down
  imgui.PushItemWidth(250)
  difficultyChanged, selectedDifficulty = imgui.Combo("Difficulty", selectedDifficulty, difficulty, table.getn(difficulty))
  imgui.PopItemWidth()
  
  -- section id drop down
  imgui.SameLine(0, 10)
  imgui.PushItemWidth(250)
  sectionChanged, selectedSection = imgui.Combo("Section ID", selectedSection, section, table.getn(section))
  imgui.PopItemWidth()
  
  -- enter manual mode on changes
  if difficultyChanged or sectionChanged then
	setMode("manual")
  end
  
  --get DAR/Rare input boxes
  getPartyConfig()
  
  -- title
  imgui.Spacing()
  imgui.SetWindowFontScale(1.6)
  ColorKeyword(section[selectedSection])
  imgui.SameLine(0, 0)
  imgui.Text(" - ")
  ColorKeyword(difficulty[selectedDifficulty])
  imgui.SetWindowFontScale(1)
  imgui.Spacing()
  imgui.BeginChild("scrolling", 0, 0, false, {"HorizontalScrollbar"})
  
  imgui.SetWindowFontScale(fontScale)
  
  -- create the drop chart tables
  for i = 1, #episode do 
	-- automatically open current episode dropdown, if Auto Mode and episode has changed
	if mode.status == "auto" and party.episode ~= nil then
		if mode.initialStatus or mode.changed or party.episode ~= mode.lastEpisode then
			if episode[i] == party.episode then
				imgui.SetNextTreeNodeOpen(true)
			else
				imgui.SetNextTreeNodeOpen(false)
			end
		end
	end
    if imgui.TreeNodeEx(episode[i], {"Framed"}) then
      Separator(true)
      imgui.NewLine()
      NextColumn()
      
      for j = 1, #cols do
        imgui.TextColored(1, 1, 0, 1, Pad(cols[j], padding))
        
        if j == 1 then
          NextColumn(2, 2)
        else
          NextColumn()
        end
      end
      
      Separator()
      
      local row = drop_charts[difficulty[selectedDifficulty]][episode[i]][section[selectedSection]]
      for j = 1, #row do
        if (row[j].target == "SEPARATOR") then
          Separator()
        else
          imgui.NewLine()
          NextColumn()

          -- target
          imgui.TextColored(difficulty_color[selectedDifficulty][1], difficulty_color[selectedDifficulty][2], difficulty_color[selectedDifficulty][3], 1, Pad(row[j].target, padding))
          NextColumn(2, 2)

          -- item
          imgui.TextColored(section_color[selectedSection][1], section_color[selectedSection][2], section_color[selectedSection][3], 1, Pad(row[j].item, padding))
          
          if imgui.IsItemHovered() then
            getToolTip(row[j])
          end
          
          NextColumn()
          Separator()
        end
      end
    
      imgui.TreePop()
    end
  end
  
  imgui.EndChild()
end

-- show the drop charts when opened
local function present()
  if window_open then
	counter = counter + 1
    local status, dataFound = false
    imgui.SetNextWindowSize(700, 520, "FirstUseEver");
    status, window_open = imgui.Begin("Drop Charts", window_open)
	-- @todo: using counter prevents auto mode from updating upon party changes
    -- if counter % update_interval == 0 then
        local side = get_side_text()
		if string.find(side, "ID") and string.find(side, "Drop") and string.find(side, "Rare") then
            party = parse_side_message(side)
			if mode.initialStatus == true then
				mode.status = "auto"
				dataFound = true
			end
		end
        counter = 0
    -- end
	drawDropCharts()
	
	-- reset statuses
	mode.changed = false
	if mode.initialStatus == true and dataFound then
		mode.initialStatus = false
	end
	if party.episode ~= nil and party.episode ~= mode.lastEpisode then
		mode.lastEpisode = party.episode
	end
	
    imgui.End()
  end
end


local function init()
  core_mainmenu.add_button("Drop Charts", button_func)
  
  return {
    name = "Drop Charts",
    version = "1.0.2",
    author = "Seth Clydesdale",
    description = "Drop chart reference for PSOBB.",
    present = present
  }
end

return {
  __addon = {
    init = init
  }
}
