local sprites = require 'sprites'
local sceneGameplay = require 'scene_gameplay'

return function ()
  local s = {}

  local image = love.graphics.newImage('res/background/game_start.png')
  local w, h = image:getDimensions()
  local sx, sy = W / w, H / h

  s.press = function (x, y)
  end

  s.move = function (x, y)
  end

  s.release = function (x, y)
    _G['replaceScene'](sceneGameplay(1))
  end

  s.update = function ()
  end

  s.draw = function ()
    love.graphics.draw(image, 0, 0, 0, sx, sy)
  end

  s.destroy = function ()
  end

  return s
end
