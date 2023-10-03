--[[

Argo Bubbles
------------
Speech bubble script for Visionaire Studio 5

Author:          The Argonauts
Version:         2.0
Date:            2022-07-27
Play our games:  https://the-argonauts.itch.io/

based on (with permission):
Advanced Speechbubble Script [v1.1] (10/13/2018) -- Written by TURBOMODUS


MIT License

Copyright 2022 The Argonauts

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

]]


-- GENERAL SETTINGS
local min_distance = 15 -- minimum distance from edge of screen


-- DEFAULT BUBBLE STYLE
local default_style = {
  align_h = 'center', -- horizontal alignment of bubble in relation to character (center, left, right, char_facing)
  align_v = 'top', -- vertical alignment of bubble in relation to character (top, bottom), defines position of pointer
  bubble_offset_x = 0, -- horizontal bubble offset
  bubble_offset_y = -25, -- vertical bubble offset
  color = 0xcce2ef, -- bubble background color (replaces white)

  linesgap = 3, -- gap between lines of text, as defined in font
  padding = {
    top = 20,
    right = 25,
    bottom = 20,
    left = 25
  }, -- distance between text block and outer edge of bubble
  
  file_bubble = "vispath:gui/bubble/bubble.png", -- path to ninerect bubble graphic
  ninerect_x = 20, -- width of top left corner in ninerect bubble graphic
  ninerect_y = 15, -- height of top left corner in ninerect bubble graphic
  ninerect_width = 100, -- width of center part of ninerect bubble graphic
  ninerect_height = 20, -- height of center part of ninerect bubble graphic
  
  file_pointer_bottom_right = "vispath:gui/bubble/bubble_pointer_bottom_right.png", -- path to right facing pointer at bubble bottom
  file_pointer_bottom_left = "vispath:gui/bubble/bubbe_pointer_bottom_left.png", -- path to left facing pointer at bubble bottom
  pointer_bottom_right_offset_x = -35, -- x offset of right facing pointer at bubble bottom
  pointer_bottom_left_offset_x = 5, -- x offset of left facing pointer at bubble bottom
  pointer_bottom_offset_y = 10, -- y offset of pointer at bubble bottom (positive numbers for moving inwards)
  
  file_pointer_top_right = nil, -- path to right facing pointer at bubble top
  file_pointer_top_left = nil, -- path to left facing pointer at bubble top
  pointer_top_right_offset_x = 0, -- x offset of right facing pointer at bubble top
  pointer_top_left_offset_x = 0, -- x offset of left facing pointer at bubble top
  pointer_top_offset_y = 0 -- y offset of pointer at bubble top (positive numbers for moving inwards)
}


-- CUSTOM BUBBLE STYLES
--[[
Add custom bubble styles to the "custom_styles" table. You can override all properties of the default
style. Undefined properties will fallback to default.

Each custom bubble style is defined for a specific character. Add the name of the character as an additional
"char" property.

You can define multiple bubble styles per character. Add a Visionaire value called "argo_bubble" to the
character to set the desired bubble style in-game. Counting starts with 1. If you don't add this value,
the first bubble style definition for this character will be used. If you have only one custom style
defined for a character, you don't need to add the Visionaire value.

Example:
local custom_styles = {
  {
    char = 'Hero',
    align_h = 'left',
    align_v = 'bottom',
    bubble_offset_x = -40,
    bubble_offset_y = 80,
    file_pointer_top_right = "vispath:gui/bubble/bubble_pointer_top_right.png",
    pointer_top_offset_y = 10
  },
  {
    ... next style definition here
  }
}

]]

local custom_styles = {}


-- BIND TO HANDLERS
-- Set to false, if you are using the "textStarted" and "textStopped" event handlers in another script.
-- You'll then have to call "show_argo_bubble(text)" AND "destroy_argo_bubble(text)" over there.
local bind_to_handlers = true

-- OPTIONAL: CALL EXTERNAL FUNCTIONS FOR THE "textStarted" EVENT HANDLER
function on_text_started(text)
  -- add your functions here

end

-- OPTIONAL: CALL EXTERNAL FUNCTIONS FOR THE "textStopped" EVENT HANDLER
function on_text_stopped(text)
  -- add your functions here

end





--------------------------------------------------------
-- USUALLY NO NEED TO CHANGE ANYTHING BELOW THIS LINE --
--------------------------------------------------------


-- Build new custom styles table "c_styles" and fill up with default values
local c_styles = {}

if custom_styles ~= nil then
  for key, styles in pairs(custom_styles) do
    local num_char_styles = 1

    if c_styles[ styles["char"] ] ~= nil then
      num_char_styles = #c_styles[ styles["char"] ] + 1
      c_styles[ styles["char"] ][num_char_styles] = {}
    else
      c_styles[ styles["char"] ] = {{}}
    end

    for k, v in pairs(default_style) do
      c_styles[ styles["char"] ][num_char_styles][k] = v
    end

    for k, v in pairs(styles) do
      c_styles[ styles["char"] ][num_char_styles][k] = v
    end
  end
end



-- EVENT HANDLERS
local bubbles = {}

function show_argo_bubble(text)
  -- Add current text to the bubbles table and prevent displaying
  if text.Owner:getId().tableId == eCharacters then
    bubbles[text:getId().id] = {Text = text.CurrentText, Owner = text.Owner:getName(), Background = text.Background}

    text.CurrentText = ""
  end

  -- Call external functions that use the "textStarted" event handler
  if on_text_started ~= nil then
    on_text_started(text)
  end
end

function destroy_argo_bubble(text)
  -- Remove current text from bubbles table
  bubbles[text:getId().id] = nil

  -- Call external functions that use the "textStopped" event handler
  if on_text_stopped ~= nil then
    on_text_stopped(text)
  end
end

if bind_to_handlers then
  registerEventHandler("textStarted","show_argo_bubble")
  registerEventHandler("textStopped","destroy_argo_bubble")
end


-- DRAW FUNCTIONS

-- Draw background texts from bubbles table below interfaces (and cursors)
function bubble_below_interface()
  for key, val in pairs(bubbles) do
    if val.Background then
      create_bubble(key, val)
    end
  end
end

-- Draw non-background texts from bubbles table above interfaces
function bubble_above_interface()
  for key, val in pairs(bubbles) do
    if not val.Background then
      create_bubble(key, val)
    end
  end
end

-- Main bubble function
function create_bubble(key, val)
  -- Get talking character
  local char = Characters[val.Owner]
  local pos = graphics.getCharacterTextPosition(char)
  local char_facing = 'right'
  if char.Direction > 90 and char.Direction < 270 then
    char_facing = 'left'
  end
  graphics.font = char.Font

  -- Use default bubble style or custom style depending on talking character
  local bubble_style = default_style

  if c_styles ~= nil and c_styles[char.name] ~= nil then
    if Characters[char.name].Values["argo_bubble"] ~= nil then
      if c_styles[char.name][ Characters[char.name].Values["argo_bubble"].Int ] ~= nil then
        bubble_style = c_styles[char.name][ Characters[char.name].Values["argo_bubble"].Int ]
      else
        bubble_style = c_styles[char.name][1]
      end
    else
      bubble_style = c_styles[char.name][1]
    end
  end

  -- Calculate the text dimensions (width, height)
  local txt = val.Text:gsub("<br/"..">", "\n")
  local lines = graphics.performLinebreaks(txt)
  local dim = {x = 0, y = 0}

  for k,v in ipairs(lines) do 
    local tempdim = graphics.fontDimension(v)
    if dim.x < tempdim.x then dim.x = tempdim.x end 
  end

  dim.y = #lines * (char.Font.Size + bubble_style.linesgap) - bubble_style.linesgap

  -- Calculate the bubble position
  if bubble_style.align_h == 'left' or (bubble_style.align_h == 'char_facing' and char_facing == 'left') then
    pos.x = pos.x - game.ScrollPosition.x - dim.x - bubble_style.padding.right - bubble_style.padding.left + bubble_style.bubble_offset_x
  elseif bubble_style.align_h == 'right' or (bubble_style.align_h == 'char_facing' and char_facing == 'right') then
    pos.x = pos.x - game.ScrollPosition.x + bubble_style.bubble_offset_x
  else -- center
    pos.x = pos.x - game.ScrollPosition.x - (dim.x + bubble_style.padding.right + bubble_style.padding.left) / 2 + bubble_style.bubble_offset_x
  end

  if pos.x < min_distance then
    pos.x = min_distance
  elseif pos.x > game.WindowResolution.x - dim.x - bubble_style.padding.right - bubble_style.padding.left - min_distance then
    pos.x = game.WindowResolution.x - dim.x - bubble_style.padding.right - bubble_style.padding.left - min_distance
  end

  if bubble_style.align_v == 'bottom' then
    pos.y = pos.y - game.ScrollPosition.y + bubble_style.bubble_offset_y
  else -- top
    pos.y = pos.y - game.ScrollPosition.y - (dim.y + bubble_style.padding.top + bubble_style.padding.bottom) + bubble_style.bubble_offset_y
  end

  if pos.y < min_distance then
    pos.y = min_distance
  elseif pos.y > game.WindowResolution.y - dim.y - bubble_style.padding.top - bubble_style.padding.bottom - min_distance then
    pos.y = game.WindowResolution.y - dim.y - bubble_style.padding.top - bubble_style.padding.bottom - min_distance
  end

  -- Get bubble graphic and define ninerect geometry
  local sprite = graphics.loadFromFile(bubble_style.file_bubble)
  local destRect = {
    x = pos.x,
    y = pos.y,
    width = dim.x + bubble_style.padding.right + bubble_style.padding.left,
    height = dim.y + bubble_style.padding.top + bubble_style.padding.bottom
  }
  local nineRect = {
    x = bubble_style.ninerect_x,
    y = bubble_style.ninerect_y,
    width = bubble_style.ninerect_width,
    height = bubble_style.ninerect_height
  }

  -- Get pointer graphic
  local pointer = nil
  local plus = nil

  if char_facing == 'left' then
    -- right pointer when char facing left
    if bubble_style.align_v == 'bottom' then
      -- top pointer when bubble aligned to bottom
      pointer = graphics.loadFromFile(bubble_style.file_pointer_top_right)
      plus = bubble_style.pointer_top_right_offset_x
    else
      -- bottom pointer when bubble aligned to top
      pointer = graphics.loadFromFile(bubble_style.file_pointer_bottom_right)
      plus = bubble_style.pointer_bottom_right_offset_x
    end
  else
    -- left pointer when char facing right
    if bubble_style.align_v == 'bottom' then
      -- top pointer when bubble aligned to bottom
      pointer = graphics.loadFromFile(bubble_style.file_pointer_top_left)
      plus = bubble_style.pointer_top_left_offset_x
    else
      -- bottom pointer when bubble aligned to top
      pointer = graphics.loadFromFile(bubble_style.file_pointer_bottom_left)
      plus = bubble_style.pointer_bottom_left_offset_x
    end
  end

  -- Calculate pointer position
  local pointer_x = 0
  local pointer_y = 0

  if bubble_style.align_h == 'left' or (bubble_style.align_h == 'char_facing' and char_facing == 'left') then
    -- if bubble is aligned left, pointer is positioned rightmost
    pointer_x = pos.x + dim.x + bubble_style.padding.right + bubble_style.padding.left - pointer.width + plus
  elseif bubble_style.align_h == 'right' or (bubble_style.align_h == 'char_facing' and char_facing == 'right') then
    -- if bubble is aligned right, pointer is positioned leftmost
    pointer_x = pos.x
  else -- center
    -- if bubble is aligned center, pointer is positioned at character
    pointer_x = char.Position.x - game.ScrollPosition.x + plus
  end

  if bubble_style.align_v == 'bottom' then
    -- pointer on top when bubble aligned to bottom
    pointer_y = pos.y - pointer.height + bubble_style.pointer_top_offset_y
  else
    -- pointer on bottom when bubble aligned to top
    pointer_y = pos.y + dim.y + bubble_style.padding.top + bubble_style.padding.bottom - bubble_style.pointer_bottom_offset_y
  end

  pointer.position = {x = pointer_x, y = pointer_y}

  -- Draw the bubble
  graphics.drawSpriteWithNineRect(sprite, destRect, nineRect, bubble_style.color, 1.0)
  graphics.drawSprite(pointer, 1.0, bubble_style.color)
  
  -- Draw the text line by line
  for k,v in ipairs(lines) do 
    local tempdim = graphics.fontDimension(v)

    graphics.drawFont(v,
      math.floor(pos.x + bubble_style.padding.left + dim.x / 2 - tempdim.x / 2),
      math.floor(pos.y + bubble_style.padding.top + (k - 1) * (char.Font.Size + bubble_style.linesgap)),
      1.0
    )
  end
end -- end of bubble function



-- ADD DRAW FUNCTIONS
graphics.addDrawFunc("bubble_below_interface()", 0)
graphics.addDrawFunc("bubble_above_interface()", 1)