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

return function (name)
  sources[name]:play()
end
