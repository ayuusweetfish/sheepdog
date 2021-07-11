local font = love.graphics.getFont()

-- script: list of items to be displayed
--   {{x, y, object, action, flags}, ...}
-- if object is string, text is shown
-- otherwise if x == -1 and y is string, a rectangle is shown
--   and clickable area is restricted to this rectangle
--   - y == 'btn_storehouse <index>': storehouse item button
--   - y == 'btn_run': run button
--   - y == 'cell <row> <col>': cell
-- if action is string, the corresponding action is awaited
-- otherwise if action is nil, the item will be shown together
--   with the following one
-- flags = { instant = true/false, blocksBoard = true/false }

-- areas: list of areas (for x == -1 cases)
--   { name = { x, y, w, h }, ... }
return function (script, areas)
  local t = {}

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
    for i = current, math.min(currentUntil, #script) do
      if script[i][1] == -1 then
        local a = areas[script[i][2]]
        local PAD = 5
        love.graphics.setColor(0.8, 0.7, 0.2)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle('line', a[1] - PAD, a[2] - PAD, a[3] + PAD * 2, a[4] + PAD * 2)
        love.graphics.setColor(1, 0.95, 0.7, 0.5)
        love.graphics.rectangle('fill', a[1] - PAD, a[2] - PAD, a[3] + PAD * 2, a[4] + PAD * 2)
      else
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(script[i][3], W * script[i][1], H * script[i][2])
      end
    end
  end

  return t
end
