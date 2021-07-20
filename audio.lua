local sources = {
  bark = love.audio.newSource('res/audio/bark.ogg', 'static'),
  bleat = love.audio.newSource('res/audio/bleat.ogg', 'static'),
  putPath = love.audio.newSource('res/audio/put_path.ogg', 'static'),
  rotate = love.audio.newSource('res/audio/rotate.ogg', 'static'),
  bubble = love.audio.newSource('res/audio/bubble.ogg', 'static'),
  levelFinish = love.audio.newSource('res/audio/level_finish.ogg', 'static'),
  correctSheepfold = love.audio.newSource('res/audio/correct_sheepfold.ogg', 'static'),
  wrongSheepfold = love.audio.newSource('res/audio/wrong_sheepfold.ogg', 'static'),
  disable = love.audio.newSource('res/audio/disable.ogg', 'static'),
  select = love.audio.newSource('res/audio/select.ogg', 'static'),
}

local sfx = function (name)
  sources[name]:stop()
  sources[name]:play()
end

-- Choose a value for `bufSize` so that
-- (loopLen (s) * sampleRate (Hz)) % (bufSize (B) / frameSize (B)) is close to 0
-- Note: frameSize is channelCount * (1 or 2 B, depending on bit depth)
local loop = function (introPath, introLen, loopPath, loopLen, bufSize)
  bufSize = bufSize or 1024
  local decIntro = love.sound.newDecoder(introPath, bufSize)
  local decLoop = love.sound.newDecoder(loopPath, bufSize)
  local sr = decIntro:getSampleRate()
  local ch = decIntro:getChannelCount()
  local bd = decIntro:getBitDepth()
  if sr ~= decLoop:getSampleRate() then error('Sample rates mismatch') end
  if ch ~= decLoop:getChannelCount() then error('Channel count mismatch') end
  if bd ~= decLoop:getBitDepth() then error('Bit depth mismatch') end

  local decLoopAlt = decLoop:clone()

  introLen = math.ceil(introLen * sr)
  loopLen = math.ceil(loopLen * sr)
  local pktSamples = math.floor(bufSize / (ch * bd / 8))

  local source = love.audio.newQueueableSource(sr, bd, ch, 64)

  local introRunning = true
  local altRunning = false
  local curSample = -introLen
  local push = function ()
    local data = {}   -- SoundData, offset
    if introRunning then
      local pkt = decIntro:decode()
      if pkt == nil then
        introRunning = false
      else
        data[#data + 1] = pkt
      end
    end
    if curSample >= 0 then
      -- Decoded packet is non-nil if the given length is less than actual
      -- but the assignment is a no-op if the packet is nil anyway
      data[#data + 1] = decLoop:decode()
      if altRunning then
        local pkt = decLoopAlt:decode()
        if pkt == nil then
          altRunning = false
        else
          data[#data + 1] = pkt
        end
      end
      -- Check: should a new loop be started?
      -- Round to cancel inaccuracies introduced by packets
      if curSample + pktSamples / 2 >= loopLen then
        decLoopAlt, decLoop = decLoop, decLoopAlt
        altRunning = true
        decLoop:seek(0)
        data[#data + 1] = decLoop:decode()
        curSample = curSample - loopLen
      end
    end
    curSample = curSample + pktSamples
    if #data == 1 then
      source:queue(data[1])
    elseif #data >= 2 then
      local mix = love.sound.newSoundData(pktSamples, sr, bd, ch)
      for i = 1, pktSamples do
        for c = 1, ch do
          local mixSample = 0
          for _, d in ipairs(data) do
            if i <= d:getSampleCount() then
              mixSample = mixSample + d:getSample(i - 1, c)
            end
          end
          mix:setSample(i - 1, c, mixSample)
        end
      end
      source:queue(mix)
    end
  end

  local update = function ()
    for _ = 1, source:getFreeBufferCount() do push() end
    if not source:isPlaying() then source:play() end
  end
  update()

  return source, update
end

return { sfx = sfx, loop = loop }
