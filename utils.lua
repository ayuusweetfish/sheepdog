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

function drawCoarseRect(x1, y1, w, h, weight)
  local x2, y2 = x1 + w, y1 + h
  local ext = 2
  local l = 195 + 1/3
  local w = weight or 6
  local sprite = 'line'
  if x2 - x1 < l or y2 - y1 < l then
    sprite = 'line_short'
    l = 40
  end
  local xCount = math.ceil((x2 - x1) / l)
  local yCount = math.ceil((y2 - y1) / l)
  for i = 0, xCount do
    local x = x1 - ext + (x2 - x1 - l + ext * 2) * i / xCount
    sprites.draw(sprite, x, y1, l, w, 0, 0, 0, 0.5)
    sprites.draw(sprite, x, y2, l, w, 0, 0, 0, 0.5)
  end
  for i = 0, yCount do
    local y = y1 - ext + (y2 - y1 - l + ext * 2) * i / yCount
    sprites.draw(sprite, x1, y, l, w, 0, math.pi / 2, 0, 0.5)
    sprites.draw(sprite, x2, y, l, w, 0, math.pi / 2, 0, 0.5)
  end
end
