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
  love.graphics.setColor(1, 1, 1, opacity or 1)
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
