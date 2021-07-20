local popcountTable = {
  [0] = 0, 1, 1, 2, 1, 2, 2, 3,
        1, 2, 2, 3, 2, 3, 3, 4,
}
function popcount4(x)
  return popcountTable[x % 16]
end
function ctz4(x)
  if x == 1 then return 0
  elseif x == 2 then return 1
  elseif x == 4 then return 2
  elseif x == 8 then return 3
  else return -1 end
end

function cellDog(cell)
  return bit.arshift(cell, 4) % 16
end

-- Return value:
-- 0: no dog
-- 1: dog, movable
-- 2: dog, not movable
function dogMobility(cell, boardRunning)
  local dogType = bit.arshift(cell, 6) % 4
  if dogType == 0 then
    return 0
  elseif not boardRunning then
    return 1
  else
    return dogType == 2 and 1 or 2
  end
end

function cloneGrid(dst, grid)
  for i = 1, #dst do dst[i] = nil end
  for i, row in ipairs(grid) do
    local row1 = {}
    for j, col in ipairs(row) do row1[j] = col end
    dst[i] = row1
  end
  return grid1
end

local sprites = require 'sprites'

function drawBackground(opacity)
  sprites.tint(1, 1, 1, opacity or 1)
  local backgroundScale = 0.4
  local xBackground
  xBackground = W - 450 * backgroundScale
  sprites.draw('background_upperright',
    xBackground, 0,
    450 * backgroundScale, 250 * backgroundScale)
  while xBackground > 0 do
    xBackground = xBackground - 540 * backgroundScale
    sprites.draw('background_upperleft',
      xBackground, 0,
      540 * backgroundScale, 250 * backgroundScale)
  end
  local backgroundLowerWidth = 1000 * backgroundScale
  local backgroundLowerHeight = 750 * backgroundScale
  for x = 1, math.ceil(W / backgroundLowerWidth) do
    for y = 1, math.ceil(H / backgroundLowerHeight) do
      sprites.draw('background_lower',
        W - x * backgroundLowerWidth,
        (y - 1) * backgroundLowerHeight + 250 * backgroundScale,
        backgroundLowerWidth, backgroundLowerHeight)
    end
  end
end

-- Optimized for batch drawing
function drawCoarseRect(posList, w, h, weight)
  local ext = 2
  local l = 195 + 1/3
  weight = weight or 6
  local sprite = 'line'
  if w < l or h < l then
    sprite = 'line_short'
    l = 40
  end
  local xCount = math.ceil(w / l)
  local yCount = math.ceil(h / l)
  for i = 1, #posList, 2 do
    local x1, y1 = posList[i], posList[i + 1]
    local x2, y2 = x1 + w, y1 + h
    local xSpritePos = {}
    for i = 0, xCount do
      local x = x1 - ext + (x2 - x1 - l + ext * 2) * i / xCount
      xSpritePos[#xSpritePos + 1] = x
      xSpritePos[#xSpritePos + 1] = y1
      xSpritePos[#xSpritePos + 1] = x
      xSpritePos[#xSpritePos + 1] = y2
    end
    sprites.drawMulti(sprite, xSpritePos, l, weight, 0, 0, 0, 0.5)
    local ySpritePos = {}
    for i = 0, yCount do
      local y = y1 - ext + (y2 - y1 - l + ext * 2) * i / yCount
      ySpritePos[#ySpritePos + 1] = x1
      ySpritePos[#ySpritePos + 1] = y
      ySpritePos[#ySpritePos + 1] = x2
      ySpritePos[#ySpritePos + 1] = y
    end
    sprites.drawMulti(sprite, ySpritePos, l, weight, 0, math.pi / 2, 0, 0.5)
  end
end

function drawCoarseLineVert(x, y1, y2, weight)
  local ext = 2
  local l = 195 + 1/3
  local w = weight or 6
  local sprite = 'line'
  if y2 - y1 < l then
    sprite = 'line_short'
    l = 40
  end
  local yCount = math.ceil((y2 - y1) / l)
  for i = 0, yCount do
    local y = y1 - ext + (y2 - y1 - l + ext * 2) * i / yCount
    sprites.draw(sprite, x, y, l, w, 0, math.pi / 2, 0, 0.5)
  end
end

function drawCoarseLineHorz(y, x1, x2, weight)
  local ext = 2
  local l = 195 + 1/3
  local w = weight or 6
  local sprite = 'line'
  if x2 - x1 < l then
    sprite = 'line_short'
    l = 40
  end
  local xCount = math.ceil((x2 - x1) / l)
  for i = 0, xCount do
    local x = x1 - ext + (x2 - x1 - l + ext * 2) * i / xCount
    sprites.draw(sprite, x, y, l, w, 0, 0, 0, 0.5)
  end
end
