W = 1080
H = 720

local globalScale
love.window.setMode(W, H, { highdpi = true })
love.window.setTitle('为小羊指路')
local wDev, hDev = love.graphics.getDimensions()
W = wDev / hDev * H
globalScale = math.min(wDev / W, hDev / H)

if _G['bit'] == nil then
  _G['bit'] = {
    band = function (a, b)
      local val = 1
      local ans = 0
      while b > 0 do
        if a % 2 == 1 and b % 2 == 1 then ans = ans + val end
        val = val + val
        a = math.floor(a / 2)
        b = math.floor(b / 2)
      end
      return ans
    end,
    bxor = function (a, b)
      local val = 1
      local ans = 0
      while b > 0 do
        if a % 2 ~= b % 2 then ans = ans + val end
        val = val + val
        a = math.floor(a / 2)
        b = math.floor(b / 2)
      end
      return ans
    end,
    lshift = function (a, b) return a * (2 ^ b) end,
    arshift = function (a, b) return math.floor(a / (2 ^ b)) end,
  }
end

local sceneStartup = require 'scene_startup'
local sceneGameplay = require 'scene_gameplay'

local sprites = require 'sprites'

require 'utils'
local drawBackground = drawBackground

_G['font_Mali'] = love.graphics.newFont('res/Mali-Regular.ttf', 24)
_G['font_TSZY'] = love.graphics.newFont('res/AaTianShiZhuYi.ttf', 24)
love.graphics.setFont(_G['font_TSZY'])

local thread = love.thread.newThread('audio_thread.lua')
thread:start()

local curScene = sceneStartup()
local lastScene = nil
local transitionTimer = 0
local currentTransition = nil
local transitions = {}

_G['replaceScene'] = function (newScene, transitionName)
  lastScene = curScene
  curScene = newScene
  transitionTimer = 0
  currentTransition = transitions[transitionName or 'fadeBlack']
end

local mouseScene = nil
function love.mousepressed(x, y, button, istouch, presses)
  if button ~= 1 then return end
  if lastScene ~= nil then return end
  mouseScene = curScene
  curScene.press(x / globalScale, y / globalScale)
end
function love.mousemoved(x, y, button, istouch)
  if mouseScene ~= curScene then return end
  curScene.move(x / globalScale, y / globalScale)
end
function love.mousereleased(x, y, button, istouch, presses)
  if button ~= 1 then return end
  if mouseScene ~= curScene then return end
  curScene.release(x / globalScale, y / globalScale)
  mouseScene = nil
end

local T = 0
local timeStep = 1 / 240

function love.update(dt)
  T = T + dt
  local count = 0
  while T > timeStep do
    T = T - timeStep
    count = count + 1
    if lastScene ~= nil then
      lastScene:update()
      -- At most 4 ticks per update for transitions
      if count <= 4 then
        transitionTimer = transitionTimer + 1
      end
    else
      curScene:update()
    end
  end
end

transitions['fadeBlack'] = {
  dur = 160,
  draw = function (x)
    local opacity = 0
    if x < 0.5 then
      lastScene:draw()
      opacity = x * 2
    else
      curScene:draw()
      opacity = 2 - x * 2
    end
    love.graphics.setColor(0.1, 0.1, 0.1, opacity)
    love.graphics.rectangle('fill', 0, 0, W, H)
  end
}

local levelClearText = love.graphics.newText(
  love.graphics.newFont('res/AaTianShiZhuYi.ttf', 120),
  '通关'
)
transitions['sheepPull'] = {
  dur = 1200,
  draw = function (x)
    local sheepProgress = 0
    if x < 0.5 then
      lastScene:draw()
      love.graphics.setColor(0.99, 1, 0.99, math.min(x * 20, 1) * 0.7)
      love.graphics.rectangle('fill', 0, 0, W, H)
      if x >= 0.15 then
        local y = (x - 0.15) / 0.35
        sheepProgress = (1 - (1 - y) * math.exp(-0.3 * y)) * 0.2
      end
      if x >= 0.1 then
        local opacity = math.min((x - 0.1) * 20, 1)
        if x >= 0.45 then opacity = 1 - (x - 0.45) * 20 end
        love.graphics.setColor(0.3, 0.3, 0.3, opacity)
        love.graphics.draw(levelClearText,
          (W - levelClearText:getWidth()) / 2,
          (H - levelClearText:getHeight() * 1.6) / 2)
      end
    else
      local y = (x - 0.5) / 0.5
      y = 1 - (1 - y) * (1 - y) * math.exp(-3 * y)
      y = math.pow(y, 1.5)
      love.graphics.push()
      love.graphics.translate(W * (1 - y), 0)
      curScene:draw()
      love.graphics.pop()
      love.graphics.push()
      love.graphics.translate(W * (-y), 0)
      lastScene:draw()
      love.graphics.pop()
      love.graphics.setColor(0.99, 1, 0.99, 0.7)
      love.graphics.rectangle('fill', 0, 0, W * (1 - y), H)
      sheepProgress = 0.2 + y * 0.8
    end

    local sheepW = 300
    local sheepH = sheepW * 0.5
    local sheepXCen = -sheepW / 2 + (W + sheepW) * (1 - sheepProgress)

    -- Animate the sheep
    local period = (sheepProgress < 0.2 and 0.1 or 0.4)
    local phase = math.fmod(sheepProgress, period) / period
    sheepW = sheepW * (1 - 0.004 * math.cos(phase * math.pi * 2))
    sheepH = sheepH * (1 + 0.006 * math.cos(phase * math.pi * 2))

    sprites.draw(
      (phase < 0.25 or phase >= 0.75) and 'sheep_running_1' or 'sheep_running_2',
      sheepXCen - sheepW / 2, H * 0.7, sheepW, sheepH)
    sprites.flush()
  end
}

function love.draw()
  love.graphics.scale(globalScale)
  love.graphics.setColor(0.975, 0.975, 0.975)
  love.graphics.rectangle('fill', 0, 0, W, H)
  love.graphics.setColor(1, 1, 1)
  if lastScene ~= nil then
    local x = transitionTimer / currentTransition.dur
    currentTransition.draw(x)
    if x >= 1 then
      if lastScene.destroy then lastScene.destroy() end
      lastScene = nil
    end
  else
    curScene.draw()
  end
end
