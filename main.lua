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
local transitionName

local TRANSITION_HALF_DUR = 80

_G['replaceScene'] = function (newScene, transition)
  lastScene = curScene
  curScene = newScene
  transitionTimer = 0
  transitionName = transition or 'fadeBlack'
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
  local count = 0
  while T > timeStep do
    T = T - timeStep
    count = count + 1
    curScene:update()
    if lastScene ~= nil then
      lastScene:update()
      -- At most 4 ticks per update for transitions
      if count <= 4 then
        transitionTimer = transitionTimer + 1
      end
    end
  end
end

local transitionDrawFn = {
  ['fadeBlack'] = function (x)
    local opacity = 0
    if x < 1 then
      lastScene:draw()
      opacity = x
    else
      curScene:draw()
      opacity = 2 - x
    end
    love.graphics.setColor(0.1, 0.1, 0.1, opacity)
    love.graphics.rectangle('fill', 0, 0, W, H)
  end,
  ['sheepPull'] = function (x)
  end,
}

function love.draw()
  love.graphics.setColor(0.975, 0.975, 0.975)
  love.graphics.rectangle('fill', 0, 0, W, H)
  love.graphics.setColor(1, 1, 1)
  if lastScene ~= nil then
    local x = transitionTimer / TRANSITION_HALF_DUR
    transitionDrawFn[transitionName](x)
    if x >= 2 then
      if lastScene.destroy then lastScene.destroy() end
      lastScene = nil
    end
  else
    curScene.draw()
  end
end
