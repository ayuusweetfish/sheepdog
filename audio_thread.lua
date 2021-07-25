require 'love.audio'
require 'love.sound'
require 'love.timer'

local loop = require('audio').loop
local bgm, update = loop(
  'res/audio/background_intro.ogg', 60 / 126 * 8,
  'res/audio/background_loop.ogg', 60 / 126 * 168,
  1600 * 4)
bgm:setVolume(0.5 ^ 1.75)  -- -10.5 dB

while true do
  love.timer.sleep(0.5)
  update()
end
