-- drop chart data was acquired from Ephinea
-- https://ephinea.pioneer2.net/drop-charts/normal/

-- imports
local core_mainmenu = require("core_mainmenu")
local util = require("Drop Charts.util")
local copy = util.copy
local orderedPairs = util.orderedPairs
local splitByDelimiter = util.splitByDelimiter
local quests = require("Drop Charts.quests")
local quest_categories = require("Drop Charts.categories")
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
local _Quest = 0xA95AA8

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
  "EPISODE 4 Boxes",
  "QUEST"
}

-- quest category dropdown values
local category_values = {
  ["EPISODE 1"] = {
    ["Government"] = 1,
    ["Side Story"] = 2,
    ["Extermination"] = 3,
    ["Maximum Attack"] = 4,
    ["Retrieval"] = 5,
    ["VR"] = 6,
    ["Solo Only"] = 7,
    ["Event"] = 8,
    ["Halloween"] = 9
  },
  ["EPISODE 2"] = {
    ["Government"] = 1,
    ["Side Story"] = 2,
    ["Extermination"] = 3,
    ["Maximum Attack"] = 4,
    ["Retrieval"] = 5,
    ["Tower"] = 6,
    ["VR"] = 7,
    ["Solo Only"] = 8,
    ["Event"] = 9,
    ["Halloween"] = 10,
  },
  ["EPISODE 4"] = {
    ["Government"] = 1,
    ["Side Story"] = 2,
    ["Extermination"] = 3,
    ["Maximum Attack"] = 4,
    ["Retrieval"] = 5,
    ["VR"] = 6,
    ["Event"] = 7,
    ["Halloween"] = 8
  }
}

-- column headers for the drop charts
local cols = {
  "Target",
  "Item",
  "Count"
}

-- Search Feature Info
local search = {
	changed = true,
	inputString = "",
	filterString = "",
	scope = "selection"
}

-- Soly's lib_helper functions for standalone addon
local function GetColorAsFloats(color)
    color = color or 0xFFFFFFFF

    local a = bit.band(bit.rshift(color, 24), 0xFF) / 255;
    local r = bit.band(bit.rshift(color, 16), 0xFF) / 255;
    local g = bit.band(bit.rshift(color, 8), 0xFF) / 255;
    local b = bit.band(color, 0xFF) / 255;

    return { r = r, g = g, b = b, a = a }
end
local function TextC(newLine, col, fmt, ...)
    newLine = newLine or false
    col = col or 0xFFFFFFFF
    fmt = fmt or "nil"

    if newLine == false then
        imgui.SameLine(0, 0)
    end

    local c = GetColorAsFloats(col)
    local str = string.format(fmt, ...)
    imgui.TextColored(c.r, c.g, c.b, c.a, str)
    return str
end
-- End Soly

-- create an ASCII separator
local separator = "+" .. string.rep("-", 86) .. "+"
local long_separator = "+" .. string.rep("-", 129) .. "+"
local function Separator(noNewLine, isQuest)
  if noNewLine == nil or noNewLine == false then
    imgui.NewLine()
  end

  if isQuest == true then
    imgui.TextColored(0.6, 0.6, 0.6, 1, long_separator)
  else
    imgui.TextColored(0.6, 0.6, 0.6, 1, separator)
  end

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

-- gets quest number then converts to string
local function get_quest_name()
  local questPtr = pso.read_u32(_Quest)
  if questPtr == 0 then
      return 0
  end

  local questData = pso.read_u32(questPtr + 0x19C)
  if questData == 0 then
    return 0
  end

  return pso.read_wstr(questData + 0x18, 0xFF)
end

-- extract party dar, rare boosts, section id, and grab episode and difficulty
local function parse_side_message(text)
  local data = { }
	
	-- logic in identifying dar and rare boost
  local dropIndex = string.find(text, "Drop")
	local rareIndex = string.find(text, "Rare")
	local idIndex = string.find(text, "ID")

	local dropStr = string.sub(text, dropIndex, rareIndex-1)
	local rareStr = string.sub(text, rareIndex, -1)
	local idStr = string.sub(text, idIndex+2, dropIndex-1)

	-- other data
	local _difficulty = pso.read_u32(_Difficulty)
	local _episode = pso.read_u32(_Episode)
	
  data.dar = tonumber(string.match(dropStr, "%d+"))
	data.rare = tonumber(string.match(rareStr, "%d+"))
	data.id = string.match(idStr,"%a+")
	data.difficulty = _difficulty + 1
	data.episode = episodes[_episode]
  data.quest = get_quest_name()
	
	return data
end

-- show tooltip with computed values
local getToolTip = function(item, diff, sect, mob_count)
	diff = diff or selectedDifficulty
	sect = sect or selectedSection

	local custom
	
	if mode.status == "auto" then
		custom = {
			dar   = tonumber(party.dar),
			rare  = tonumber(party.rare),
      chances = tonumber(input.chances)
		}
	else
		custom = {
			dar   = tonumber(input.dar),
			rare  = tonumber(input.rare),
      chances = tonumber(input.chances)
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
	local drop = "Drop: 1/"..string.format("%.2f",denom)..string.format(" (%.2f%s)",percent,"%%")
	local adjustedDrop = "Drop: 1/"..string.format("%.2f",computedDenom)..string.format(" (%.2f%s)",computedPercent,"%%")
	
	-- generate tooltip
	imgui.BeginTooltip()
	
		imgui.SetWindowFontScale(fontScale)
		
		-- if search, display difficulty and section
		if search.scope == "all" then
			imgui.TextColored(difficulty_color[diff][1], difficulty_color[diff][2], difficulty_color[diff][3], 1, difficulty[diff])
			imgui.SameLine(0, 8)
      imgui.TextColored(section_color[sect][1], section_color[sect][2], section_color[sect][3], 1, section[sect])
			imgui.NewLine()
			imgui.NewLine()
		end
		
		-- if party or item's dar has been adjusted
		if custom.dar ~= 100 and item.dar ~= computedDar then
			TextC(false, 0xFFFFFFFF, "Adjusted ")
		end
		TextC(false, 0xFFFFFFFF, "DAR: ")
		
		local color = 0xFFFFFFFF
		if computedDar == 100 then
			color = 0xFFFFFF00
		end
		TextC(false, color, string.format("%.0f%s",computedDar,"%%"))
		
		-- display color-coded DAR delta
		if darDelta > 0 and custom.dar ~= 100 then
			TextC(false, 0xFF00FF00, " +"..string.format("%.0f%s",darDelta, "%%"))
		elseif darDelta < 0 and custom.dar ~= 100 then
			TextC(false, 0xFFFF0000, " "..string.format("%.0f%s",darDelta, "%%"))
		end
		
		imgui.NewLine()
		
		-- if party rare is not 100%
		if custom.rare ~= 100 then
			TextC(false, 0xFFFFFFFF, "Adjusted ")
		end
		TextC(false, 0xFFFFFFFF, "Rare: ")
		
		color = 0xFFFFFFFF
		if computedRare == 100 then
			color = 0xFFFFFF00
		end
		-- for rare enemies, etc, no decimals
		local rareStr = string.format("%.5f%s",computedRare,"%%")
		if computedRare > 19 then
			rareStr = string.format("%.1f%s",computedRare,"%%")
		end
		TextC(false, color, rareStr)
		
		-- display color-coded RARE delta
		local deltaStr = string.format("%.4f",rareDelta)
		if computedRare > 19 then
			deltaStr = string.format("%.1f",rareDelta)
		end
		if rareDelta > 0 and custom.rare ~= 100 then
			TextC(false, 0xFF00FF00, " +" .. deltaStr)
		elseif rareDelta < 0 and custom.rare ~= 100 then
			TextC(false, 0xFFFF0000, " " .. deltaStr)
		end
		
		imgui.NewLine()
    -- chance calculator
    local chancePercentage = percent
    local _computedDenom = string.format("%.2f",computedDenom)
    local noHit = (_computedDenom - 1) / _computedDenom
    local noChancePercentage = noHit

    -- check if row is a quest
    if mob_count and custom.chances >= 1 then
      TextC(true, 0xFFFFFFFF, "Probability from (")
      TextC(false, 0xFF00FF00, custom.chances)
      TextC(false, 0xFFFFFFFF, ") Quest runs")
      custom.chances = mob_count * custom.chances
    end

    if item.dar ~= computedDar or item.rare ~= computedRare or custom.chances > 1 then
      local counter = 1

      while (counter < custom.chances)
      do
        noChancePercentage = noChancePercentage * noHit
        counter = counter + 1
      end
      -- convert it to chance
      chancePercentage = string.format("%.2f",((1 - noChancePercentage) * 100))
    end

    TextC(true, 0xFFFFFFFF, "Chances: ")
    TextC(false, 0xFF00FF00, custom.chances)
    TextC(false, 0xFFFFFFFF, ", Probability: ")
    TextC(false, 0xFF00FF00, chancePercentage .. "%%")

		imgui.NewLine()
		
		-- If drop rate is different, show original drop rate string
		if item.dar ~= computedDar or item.rare ~= computedRare then
			TextC(true, 0xFF888888, drop)
		end
		TextC(true, 0xFFFFFFFF, adjustedDrop)
	
	imgui.EndTooltip()
end

-- Set Mode (Auto/Manual)
local setMode = function(status)
	mode.status = status
	mode.changed = true
end

local compareStrings = function(s1, s2)
  -- first parse "#" out of any strings
  s1 = string.gsub(s1, "#", "")
  s1 = string.upper(s1)
  s2 = string.upper(s2)

  if s1 == s2 then
    return true
  else
    return false
  end
end

local updateQuestDropdowns = function(qt, quests, category_values)
  local _quests = quests[qt["episodes"][qt["selectedEpisode"]]]
  
  if party.episode ~= nil and party.quest ~= nil then
    for k,v in pairs(_quests) do
      for _k,_v in pairs(v) do
        if compareStrings(party.quest, _v.Name) == true then
          qt.selectedCategory = category_values[party.episode][_v.Category]

          for i = 1, #qt.quest_names, 1 do
            if compareStrings(party.quest, qt["quest_names"][i]) == true then
              qt.selectedQuest = i
            end
          end
        end
      end
    end
  end
end

-- Quest Filter
local getQuestInputs = function (qt, quest_categories, quests)
  if mode.status == "auto" then
    if party.episode == "EPISODE 1" then
      qt.selectedEpisode = 1
    elseif party.episode == "EPISODE 2" then
      qt.selectedEpisode = 2
    else
      qt.selectedEpisode = 3
    end

    updateQuestDropdowns(qt, quests, category_values)
  end

  TextC(true, 0xFFFFFFFF, "Quest Filter")
  imgui.SameLine(0, 0)

  -- episode dropdown
  imgui.NewLine()
  imgui.PushItemWidth(250)
  qt.episodeChanged, qt.selectedEpisode = imgui.Combo("Episodes", qt.selectedEpisode, qt.episodes, table.getn(qt.episodes))
  imgui.PopItemWidth()

  -- if changed, enter Manual Mode
  if qt.episodeChanged then
	  setMode("manual")
  end

  -- category dropdown
  imgui.PushItemWidth(250)
  qt.categoryChanged, qt.selectedCategory = imgui.Combo("Categories", qt.selectedCategory, quest_categories[qt["episodes"][qt.selectedEpisode]], table.getn(quest_categories[qt["episodes"][qt.selectedEpisode]]))
  imgui.PopItemWidth()

  -- if changed, enter Manual Mode
  if qt.categoryChanged then
	  setMode("manual")
  end
 
  -- get quests and store in a table for quest dropdown
  qt.quests = quests[qt["episodes"][qt["selectedEpisode"]]][quest_categories[qt["episodes"][qt["selectedEpisode"]]][qt["selectedCategory"]]]
  qt.quest_names = {}
  for k, v in orderedPairs(qt.quests) do
    table.insert(qt.quest_names, qt["quests"][tostring(k)]["Name"])
  end

  -- quests dropdown
  imgui.PushItemWidth(320)
  qt.questChanged, qt.selectedQuest = imgui.Combo("Quests", qt.selectedQuest, qt.quest_names, table.getn(qt.quest_names))
  imgui.PopItemWidth()

  -- if changed, enter Manual Mode
  if qt.questChanged then
	  setMode("manual")
  end

  imgui.NewLine()
end

-- Search Feature
local getSearchInput = function()
  imgui.NewLine()

  TextC(true, 0xFFFFFFFF, "Search for ")
  imgui.SameLine(0, 0)
  
  imgui.PushItemWidth(168)
  search.changed, search.inputString = imgui.InputText("", search.inputString, 255)
  imgui.PopItemWidth()
  
  TextC(false , 0xFFFFFFFF, " in ")
  imgui.SameLine(0,0)
  
  if imgui.Button("Selection") then
    search.filterString = search.inputString
    search.scope = "selection"
  end
  
  TextC(false, 0xFFFFFFFF, " or ")
  imgui.SameLine(0,0)
  
  if imgui.Button("All") then
    search.filterString = search.inputString
    search.scope = "all"
  end
  
  imgui.SameLine(0,25)
  
  if imgui.Button("Clear Search") then
    search.filterString = ""
    search.inputString = ""
  end
  
  imgui.NewLine()
end

-- Party Dar/Rare inputs/configuration
local getPartyConfig = function()
  local darSuccess
  local rareSuccess
  local chancesSuccess
  
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
  imgui.SameLine(0, 10)
  
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
  imgui.SameLine(0, 10)
  
  -- if changed, enter Manual Mode
  if rareSuccess then
	  setMode("manual")
  end
  
  if input.rare == "" or input.rare == nil or tonumber(input.rare) == nil then
	  input.rare = "100"
  end

  -- if uninitialized, use defaults
  if input.chances == "" or input.chances == nil or tonumber(input.chances) == nil then
	  input.chances = "1"
  end

  imgui.PushItemWidth(48)
  chancesSuccess, input.chances = imgui.InputText("Chance(s)",string.format("%s",input.chances), 255)
  imgui.PopItemWidth()
  imgui.SameLine(0, 10)
  
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
  TextC(false,mode[mode.status].color, autoString)
  if imgui.IsItemHovered() then
	  imgui.BeginTooltip()
		TextC(false,0xFFFFFFFF, mode[mode.status].tooltip)
	  imgui.EndTooltip()
  end
end

-- draw the drop charts
local difficultyChanged = true
local selectedDifficulty = 1
local sectionChanged = true
local selectedSection = 1
local padding = 42

-- quest table
local qt = {
  ["episodeChanged"] = true,
  ["selectedEpisode"] = 1,
  ["categoryChanged"] = true,
  ["selectedCategory"] = 1,
  ["questChanged"] = true,
  ["selectedQuest"] = 1 ,
  ["quests"] = {},
  ["quest_names"] = {},
  ["episodes"] = {
    "EPISODE 1",
    "EPISODE 2",
    "EPISODE 4"
  }
}

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

  --get Search Input
  getSearchInput()

  --get Quest Input
  getQuestInputs(qt, quest_categories, quests)

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
        if episode[i] == party.episode and party.quest == nil  then
          imgui.SetNextTreeNodeOpen(true)
        elseif episode[i] == "QUEST" and party.quest ~= nill then
          imgui.SetNextTreeNodeOpen(true)
        else
          imgui.SetNextTreeNodeOpen(false)
        end
      end
    end
    if imgui.TreeNodeEx(episode[i], {"Framed"}) then
      local party_quest = ""
      if party.quest == 0 or party.quest == nil then
        party_quest = qt["quest_names"][qt["selectedQuest"]]
      else
        party_quest = party.quest
      end

      if episode[i] == "QUEST" then
        -- Quest title
        imgui.NewLine()
        imgui.Spacing()
        imgui.SetWindowFontScale(1.4)
        ColorKeyword(party_quest)
        imgui.SetWindowFontScale(fontScale)
        imgui.Spacing()
        Separator(false, true)
      else
        Separator(true)
      end

      imgui.NewLine()
      NextColumn()

      for j = 1, #cols do
        if j == 3 and episode[i] ~= "QUEST" then
          break
        else
          imgui.TextColored(1, 1, 0, 1, Pad(cols[j], padding))
          if j == 1 or (j == 2 and episode[i] == "QUEST") then
              NextColumn(2, 2)
          else
              NextColumn()
          end
        end
      end
      
      if episode[i] == "QUEST" then
        Separator(false, true)
      else
        Separator()
      end

	  -- Define generateRows function, to accommodate search feature
	  local function generateRows(row, diff, sect)
      diff = diff or selectedDifficulty
      sect = sect or selectedSection
      
      for j = 1, #row do
        if (row[j].target == "SEPARATOR") then
        -- Don't generate separators on searches to prevent empty skips between areas (otherwise, no results in an area still generates a starting separator)
          if (search.filterString == "") then
            Separator()
          end
        else
        -- Only display result row if no filterString or if a match occurs
          if(search.filterString == "" or string.find(string.lower(row[j].item), string.lower(search.filterString), 1, true)) then
            local target = string.gsub(row[j].target, "[\r\n]", "")
            imgui.NewLine()
            NextColumn()

            -- target
            imgui.TextColored(difficulty_color[diff][1], difficulty_color[diff][2], difficulty_color[diff][3], 1, Pad(target, padding))
            NextColumn(2, 2)

            -- item
            imgui.TextColored(section_color[sect][1], section_color[sect][2], section_color[sect][3], 1, Pad(row[j].item, padding))

            if imgui.IsItemHovered() then
              getToolTip(row[j], diff, sect)
            end

            -- count
            if row[j].count then
              NextColumn(2, 2)
              imgui.TextColored(section_color[sect][1], section_color[sect][2], section_color[sect][3], 1, Pad(row[j].count, padding))

              if imgui.IsItemHovered() then
                getToolTip(row[j], diff, sect, row[j].count)
              end
            end
        
            NextColumn()
            -- check if it's quest row
            if row[j].count then
              Separator(false, true)
            else
              Separator()
            end
          end
        end
      end
	  end

    local function generateQuestRows(row, quests)
      local quest_row, quest_mobs, selected_quest = {}, {}, {}
      local selected_quest_name = qt["quest_names"][qt["selectedQuest"]]

      -- parse through quests table for the selected quest
      for k,v in orderedPairs(quests) do
        if quests[tostring(k)]["Name"] == selected_quest_name then
          selected_quest = quests[tostring(k)]
        end    
      end

      -- loop through selected quests mobs
      for k,v in pairs(selected_quest["Mobs"]) do
        -- loops through quest's area tables
        local is_random = k:find("Random Spawns")
        for _k,_v in pairs(v) do
          if quest_mobs[_k] then                    
            if is_random == nil then
              quest_mobs[_k] = quest_mobs[_k] + tonumber(_v)
            else
              quest_mobs[_k] = quest_mobs[_k] .. " + " .. _v .. "(Chance)"
            end
          else
            if is_random == nil then
              quest_mobs[_k] = tonumber(_v)
            else
              quest_mobs[_k] = _v .. "(Chance)"
            end
          end
        end
      end

      -- now loop through quest_mobs + drop_chart row for same mobs
      -- on match, copy drop_charts target properties into new table
      for k,v in pairs(quest_mobs) do
        for i = 1, #row do
          -- drop chart mob
          local dc_mob = splitByDelimiter(row[i].target, "/")
          local s1_res = compareStrings(dc_mob.s1, k)
          local s2_res = compareStrings(dc_mob.s2, k)

          if s1_res or s2_res then
            local target = copy(row[i])
            target["count"] = v
            table.insert(quest_row, target)
          end
        end
      end
      
      generateRows(quest_row)
    end

	  -- Generate rows depending on search
	  if search.filterString == "" or search.scope == "selection" then
		-- No search term, or "selection" mode, so use rows with selected settings
      if episode[i] ~= "QUEST" then
        local row = drop_charts[difficulty[selectedDifficulty]][episode[i]][section[selectedSection]]
        generateRows(row)
      else
        local row = drop_charts[difficulty[selectedDifficulty]][qt["episodes"][qt["selectedEpisode"]]][section[selectedSection]]
        generateQuestRows(row, qt.quests)
      end
	  else
		-- Iterate through all difficulties, episodes, and sections, using search.filterString
      for d = 1, #difficulty do
        for s = 1, #section do
          local row = drop_charts[difficulty[d]][episode[i]][section[s]]
          generateRows(row, d, s)
        end
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
    version = "1.2.1",
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
