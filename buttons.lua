local function inRect(px, py, x, y, w, h)
  return px >= x and px < x + w and
         py >= y and py < y + h
end

return function ()
  local g = {}

  local btns = {}
  local selected = -1
  local ptInside = false

  local function processSprite(sprite, w, h)
    if type(sprite) == 'string' then
      sprite = love.graphics.newImage(sprite)
    end
    local iw, ih = sprite:getDimensions()
    sx, sy = w / iw, h / ih
    return sprite, sx, sy
  end

  g.add = function (x, y, w, h, sprite, fn)
    local sprite, sx, sy = processSprite(sprite, w, h)
    btns[#btns + 1] = {
      x = x, y = y,
      w = w, h = h,
      sprite = sprite,
      sx = sx, sy = sy,
      fn = fn,
      enabled = true,
    }
    return #btns
  end

  g.enable = function (i, enable)
    btns[i].enabled = enable
    if not enable and selected == i then selected = -1 end
  end

  g.sprite = function (i, sprite)
    local sprite, sx, sy = processSprite(sprite, btns[i].w, btns[i].h)
    btns[i].sprite = sprite
    btns[i].sx = sx
    btns[i].sy = sy
  end

  -- Immediately triggers the selected button if there is one,
  -- regardless of current pointer status
  g.trigger = function ()
    if selected == -1 then return false end
    btns[selected].fn()
    selected = -1
    ptInside = false
  end

  g.press = function (x, y)
    for i, b in ipairs(btns) do
      if b.enabled and inRect(x, y, b.x, b.y, b.w, b.h) then
        selected = i
        ptInside = true
        return true
      end
    end
    return false
  end

  g.move = function (x, y)
    if selected == -1 then return false end
    local b = btns[selected]
    ptInside = inRect(x, y, b.x, b.y, b.w, b.h)
    return true
  end

  g.release = function (x, y)
    if selected == -1 then return false end
    if ptInside then btns[selected].fn() end
    selected = -1
    ptInside = false
    return true
  end

  g.update = function ()
  end

  g.draw = function ()
    for i, b in ipairs(btns) do
      if not b.enabled then
        love.graphics.setColor(1, 1, 1, 0.4)
      elseif i == selected and ptInside then
        love.graphics.setColor(0.8, 0.8, 0.8)
      else
        love.graphics.setColor(1, 1, 1)
      end
      love.graphics.draw(b.sprite, b.x, b.y, 0, b.sx, b.sy)
    end
    love.graphics.setColor(1, 1, 1)
  end

  return g
end
