return function (script)
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
    return (currentUntil <= #script and script[currentUntil][5])
  end

  t.blocksInteractions = function ()
    return (currentUntil <= #script and
      script[currentUntil][4] ~= nil and
      script[currentUntil][4]:sub(1, 6) == 'delay ')
  end

  t.update = function ()
    time = time + 1
    if time % 120 == 0 then
      t.emit('delay ' .. time)
    end
  end

  t.draw = function ()
    love.graphics.setColor(0, 0, 0)
    for i = current, math.min(currentUntil, #script) do
      love.graphics.print(script[i][3], W * script[i][1], H * script[i][2])
    end
  end

  return t
end
