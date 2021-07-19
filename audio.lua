local sources = {
  bark = love.audio.newSource('res/0_517132__wdomino__woofbig2.wav', 'static'),
  bleat = love.audio.newSource('res/1_182509__swiftoid__lamb-and-mother.wav', 'static'),
  putPath = love.audio.newSource('res/3_480891__sheyvan__putting-down-book.wav', 'static'),
  rotate = love.audio.newSource('res/5_343130__inspectorj__ticking-clock-a.wav', 'static'),
  bubble = love.audio.newSource('res/6_512135__beezlefm__pop-up-sound.wav', 'static'),
  levelFinish = love.audio.newSource('res/7_391539__mativve__electro-win-sound.wav', 'static'),
  correctSheepfold = love.audio.newSource('res/8_413629__djlprojects__video-game-sfx-positive-action-long-tail.wav', 'static'),
  wrongSheepfold = love.audio.newSource('res/9_146731__leszek-szary__game-fail.wav', 'static'),
}

local sfx = function (name)
  sources[name]:play()
end

local loop = function (introPath, introLen, loopPath, loopLen)
  local bufSize = 1024
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
  end
  update()

  return source, update
end

return { sfx = sfx, loop = loop }
