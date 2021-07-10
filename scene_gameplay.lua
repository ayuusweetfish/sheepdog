local buttons = require 'buttons'

local BORDER_PAD = 12
local ITEM_SIZE = 60
local ITEM_SPACE = 12

return function ()
  local s = {}

  local btnsStorehouse = buttons()
  for i = 1, 5 do
    btnsStorehouse.add(
      BORDER_PAD,
      BORDER_PAD + (ITEM_SIZE + ITEM_SPACE) * (i - 1),
      ITEM_SIZE, ITEM_SIZE,
      'ice-cream_1f368.png',
      function () print('item ' .. i) end
    )
  end

  s.press = function (x, y)
    if btnsStorehouse.press(x, y) then return end
  end

  s.move = function (x, y)
    if btnsStorehouse.move(x, y) then return end
  end

  s.release = function (x, y)
    if btnsStorehouse.release(x, y) then return end
  end

  s.update = function ()
    btnsStorehouse.update()
  end

  s.draw = function ()
    btnsStorehouse.draw()
  end

  return s
end
