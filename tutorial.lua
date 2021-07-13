local sprites = require 'sprites'
require 'utils'
local drawCoarseRect = drawCoarseRect

-- script: list of items to be displayed
--   {{x, y, object, action, flags}, ...}
-- if object is string, text is shown
-- otherwise if x == -1 and y is string, a rectangle is shown
--   and clickable area is restricted to this rectangle
--   - y == 'btn_storehouse <index>': storehouse item button
--   - y == 'btn_run': run button
--   - y == 'cell <row> <col>': cell
-- otherwise if x == -2, the rectangle is shown
--   but clickable area is not restricted
-- if action is string, the corresponding action is awaited
-- otherwise if action is nil, the item will be shown together
--   with the following one
-- flags = { instant = true/false, blocksBoard = true/false }

-- areas: list of areas (for x == -1 cases)
--   { name = { x, y, w, h }, ... }
return function (script, areas)
  local t = {}

  local font = love.graphics.getFont()

  script = script or {}
  local current = 1
  local currentUntil = 0

  local time = 0
  local timeWaitTarget = 0

  local function calcUntil()
    local i = current
    while i < #script do
      if script[i][4] ~= nil then break end
      i = i + 1
    end
    currentUntil = i
    if currentUntil <= #script and
        script[currentUntil][4] ~= nil and
        script[currentUntil][4]:sub(1, 6) == 'delay '
    then
      timeWaitTarget = tonumber(script[currentUntil][4]:sub(7))
    else
      timeWaitTarget = 0
    end
  end
  calcUntil()

  t.emit = function (event)
    if currentUntil <= #script and script[currentUntil][4] == event then
      current = currentUntil + 1
      calcUntil()
      time = 0
    end
  end

  t.blocksBoardUpdates = function ()
    return (currentUntil <= #script and
      script[currentUntil][5] ~= nil and
      script[currentUntil][5].blocksBoard)
  end

  t.blocksInteractions = function (x, y)
    if timeWaitTarget > 0 then return true end
    local blocking = false
    for i = current, math.min(currentUntil, #script) do
      if script[i][1] == -1 then
        local a = areas[script[i][2]]
        if x >= a[1] and x < a[1] + a[3] and
           y >= a[2] and y < a[2] + a[4] then
          return false
        else
          blocking = true
        end
      end
    end
    return blocking
  end

  t.update = function ()
    time = time + 1
    if time == timeWaitTarget then
      t.emit('delay ' .. time)
    end
  end

  t.draw = function ()
    local progress = 1
    if time < 120 then
      local x = time / 120
      progress = 1 - math.exp(-6 * x) * (1 - x)
    end
  --[[
    local restrict = false
    for i = current, math.min(currentUntil, #script) do
      if script[i][1] == -1 then
        restrict = true
        break
      end
    end
    if restrict then
      sprites.tint(0.7, 0.7, 0.7, progress * 0.2)
      sprites.rectangle(0, 0, W, H)
    end
  ]]
    local textDrawCalls = {}
    for i = current, math.min(currentUntil, #script) do
      local progress = progress
      -- Instant?
      if script[i][5] ~= nil and script[i][5].instant then progress = 1 end
      if script[i][1] == -1 or script[i][1] == -2 then
        local a = areas[script[i][2]]
        local PAD = 16
        local xCen = a[1] + a[3] / 2
        local yCen = a[2] + a[4] / 2
        local w = a[3] + PAD * 2
        local h = a[4] + PAD * 2
        w = w * (0.5 + progress * 0.5)
        h = h * (0.5 + progress * 0.5)
        local x = xCen - w / 2
        local y = yCen - h / 2
        if script[i][1] == -1 then
          sprites.tint(1, 0.95, 0.7, 0.5 * progress)
        else
          sprites.tint(0.75, 0.95, 1, 0.5 * progress)
        end
        sprites.rectangle(x, y, w, h)
        if script[i][1] == -1 then
          sprites.tint(0.8, 0.7, 0.2, progress)
        else
          sprites.tint(0.4, 0.7, 1.0, progress)
        end
        drawCoarseRect(x, y, w, h)
      elseif script[i][3] ~= '' then
        local s = script[i][3]
        local pad = 48
        local lines = 1
        for i = 1, #s do
          if s:sub(i, i) == '\n' then lines = lines + 1 end
        end
        local w = font:getWidth(s) + pad * 2
        local h = font:getHeight() * lines + pad * 2
        sprites.tint(1, 1, 1, progress)
        sprites.draw(w / h > 5 / 3 and 'bubble_1' or 'bubble_2',
          W * script[i][1] - pad, H * script[i][2] - pad,
          w, h)
        textDrawCalls[#textDrawCalls + 1] = {
          progress,
          s, W * script[i][1], H * script[i][2]
        }
      end
    end

    -- Sprites
    sprites.flush()
    -- Text
    for _, t in ipairs(textDrawCalls) do
      love.graphics.setColor(0.3, 0.3, 0.3, t[1])
      love.graphics.print(t[2], t[3], t[4])
    end
  end

  return t
end
