W = 1080
H = 720

local sceneGameplay = require 'scene_gameplay'

_G['font_Mali'] = love.graphics.newFont('res/Mali-Regular.ttf', 24)
_G['font_TSZY'] = love.graphics.newFont('res/AaTianShiZhuYi-2.ttf', 24)
love.graphics.setFont(_G['font_TSZY'])

function love.load()
  love.window.setMode(W, H, { highdpi = true })
end

local curScene = sceneGameplay()

function love.mousepressed(x, y, button, istouch, presses)
  if button ~= 1 then return end
  curScene.press(x, y)
end
function love.mousemoved(x, y, button, istouch)
  curScene.move(x, y)
end
function love.mousereleased(x, y, button, istouch, presses)
  if button ~= 1 then return end
  curScene.release(x, y)
end

local T = 0
local timeStep = 1 / 240

function love.update(dt)
  T = T + dt
  while T > 0 do
    T = T - timeStep
    curScene:update()
  end
end

function love.draw()
  love.graphics.setColor(0.975, 0.975, 0.975)
  love.graphics.rectangle('fill', 0, 0, W, H)
  love.graphics.setColor(1, 1, 1)
  curScene.draw()
end
