W = 1080
H = 720

local sceneStartup = require 'scene_startup'
local sceneGameplay = require 'scene_gameplay'

_G['font_Mali'] = love.graphics.newFont('res/Mali-Regular.ttf', 24)
_G['font_TSZY'] = love.graphics.newFont('res/AaTianShiZhuYi-2.ttf', 24)
love.graphics.setFont(_G['font_TSZY'])

function love.load()
  love.window.setMode(W, H, { highdpi = true })
end

-- local curScene = sceneGameplay()
local curScene = sceneStartup()
local lastScene = nil
local transitionTimer = 0

local TRANSITION_HALF_DUR = 80

_G['replaceScene'] = function (newScene)
  lastScene = curScene
  curScene = newScene
  transitionTimer = 0
end

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
    if lastScene ~= nil then
      lastScene:update()
      transitionTimer = transitionTimer + 1
    end
  end
end

function love.draw()
  love.graphics.setColor(0.975, 0.975, 0.975)
  love.graphics.rectangle('fill', 0, 0, W, H)
  love.graphics.setColor(1, 1, 1)
  if lastScene ~= nil then
    local opacity = 0
    local x = transitionTimer / TRANSITION_HALF_DUR
    if x < 1 then
      lastScene:draw()
      opacity = x
    else
      curScene:draw()
      opacity = 2 - x
      if x >= 2 then lastScene = nil end
    end
    love.graphics.setColor(0.1, 0.1, 0.1, opacity)
    love.graphics.rectangle('fill', 0, 0, W, H)
  else
    curScene.draw()
  end
end
