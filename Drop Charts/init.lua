-- drop chart data was acquired from Ephinea
-- https://ephinea.pioneer2.net/drop-charts/normal/

-- imports
local core_mainmenu = require("core_mainmenu")
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
local separator = "+" .. string.rep("-", 85) .. "+" 
local function Separator(noNewLine)
  if noNewLine == nil then
    imgui.NewLine()
  end
  
  imgui.TextColored(0.6, 0.6, 0.6, 1, separator)
end

-- create an ASCII column
local function NextColumn()
  imgui.SameLine(0, 0)
  imgui.TextColored(0.6, 0.6, 0.6, 1, "|")
  imgui.SameLine(0, 0)
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


-- draw the drop charts
local difficultyChanged = true
local selectedDifficulty = 1
local sectionChanged = true
local selectedSection = 1
local padding = 42
local drawDropCharts = function()
  
  -- difficulty drop down
  imgui.PushItemWidth(250)
  difficultyChanged, selectedDifficulty = imgui.Combo("Difficulty", selectedDifficulty, difficulty, table.getn(difficulty))
  imgui.PopItemWidth()
  
  -- section id drop down
  imgui.SameLine(0, 10)
  imgui.PushItemWidth(250)
  sectionChanged, selectedSection = imgui.Combo("Section ID", selectedSection, section, table.getn(section))
  imgui.PopItemWidth()
  
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
  
  -- create the drop chart tables
  for i = 1, #episode do 
    if imgui.TreeNodeEx(episode[i], {"Framed"}) then
      Separator(true)
      imgui.NewLine()
      NextColumn()
      
      for j = 1, #cols do
        imgui.TextColored(1, 1, 0, 1, Pad(cols[j], padding))
        NextColumn()
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
          NextColumn()

          -- item
          imgui.TextColored(section_color[selectedSection][1], section_color[selectedSection][2], section_color[selectedSection][3], 1, Pad(row[j].item, padding))
          
          if imgui.IsItemHovered() then
            imgui.SetTooltip(row[j].tooltip)
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
    local status
    imgui.SetNextWindowSize(700, 520, "FirstUseEver");
    status, window_open = imgui.Begin("Drop Charts", window_open)
    drawDropCharts()
    imgui.End()
  end
end


local function init()
  core_mainmenu.add_button("Drop Charts", button_func)
  
  return {
    name = "Drop Charts",
    version = "1.0.0",
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
