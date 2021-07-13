-- Spritesheets

-- Array of sprite batches
local batches = {}

-- Map from names to sprite batches and rectangles
-- {
--   batch = <SpriteBatch>,
--   sx = <number>, sy = <number>,
--   sw = <number>, sh = <number>,  -- source rectangle
--   tx = <number>, ty = <number>,  -- destination origin
--   w = <number>, h = <number>     -- canvas size, all in pixels
-- }
local lookup = {}

local loadCrunch = function (path)
  local splitPath = function (path)
    local p = #path
    local q   -- p: last '/'; q: last '.' after p
    -- ord('/') == 47, ord('.') == 46
    while p >= 1 and path:byte(p) ~= 47 do
      if path:byte(p) == 46 and q == nil then q = p end
      p = p - 1
    end
    q = q or #path + 1
    return path:sub(1, p), path:sub(p + 1, q - 1)
  end
  local wd, name = splitPath(path)

  local f, err = love.filesystem.read(path)
  if f == nil then
    error('Cannot load sprite sheet metadata ' .. path .. ' (' .. err .. ')')
    return nil
  end

  local p = 1

  local read_int16 = function ()
    local l, h = f:byte(p, p + 1)
    p = p + 2
    local x = h * 256 + l
    if x >= 32768 then x = x - 65536 end
    return x
  end
  local read_str = function ()
    local q = p
    repeat
      local ch = f:byte(p)
      p = p + 1
      if ch == 0 then break end
    until false
    return f:sub(q, p - 2)
  end

  local texCount = read_int16()
  for texId = 1, texCount do
    local texName = read_str()
    local img = love.graphics.newImage(wd .. texName .. '.png')
    local batch = love.graphics.newSpriteBatch(img, nil, 'stream')
    img:setFilter('nearest', 'nearest')
    batches[#batches + 1] = batch

    local sprCount = read_int16()
    for sprId = 1, sprCount do
      local name = read_str()
      local spr = {}
      spr.batch = batch
      spr.sx = read_int16()
      spr.sy = read_int16()
      spr.sw = read_int16()
      spr.sh = read_int16()
      spr.tx = -read_int16()
      spr.ty = -read_int16()
      spr.w = read_int16()
      spr.h = read_int16()
      spr.quad = love.graphics.newQuad(
        spr.sx, spr.sy, spr.sw, spr.sh,
        img:getPixelDimensions())
      lookup[name] = spr
    end
  end
end

loadCrunch('res/sprites.bin')

-- Drawing

local drawR, drawG, drawB, drawA = 1, 1, 1, 1

local layers = {}
local layerList = {}

local function draw(name, x, y, w, h, layer, r, ox, oy)
  layer = layer or 0
  r = r or 0
  ox = ox or 0
  oy = oy or 0
  local item = lookup[name]
  local cw, ch = item.w, item.h
  local tx, ty = item.tx, item.ty
  local scalex, scaley = w / cw, h / ch

  local l = layers[layer]
  if l == nil then
    l = {}
    layers[layer] = l
    layerList[#layerList + 1] = layer
  end
  l[#l + 1] = {
    item,
    drawR, drawG, drawB, drawA,
    x, y,
    r, scalex, scaley,
    -tx + cw * ox, -ty + ch * oy
  }
end

local function rectangle(x, y, w, h, layer)
  draw('white_pixel', x, y, w, h, layer)
end

local function tint(r, g, b, a)
  drawR, drawG, drawB, drawA = r, g, b, a or 1
end

local function delete(name)
  cache[name] = nil
end

local function flush()
  -- Sort layers
  table.sort(layerList)
  for k, layer in ipairs(layerList) do
    local l = layers[layer]
    for _, call in ipairs(l) do
      call[1].batch:setColor(call[2], call[3], call[4], call[5])
      call[1].batch:add(
        call[1].quad,
        call[6], call[7], call[8], call[9], call[10], call[11], call[12]
      )
    end
    layers[layer] = nil
    layerList[k] = nil
  end

  love.graphics.setColor(1, 1, 1)
  for _, v in ipairs(batches) do
    love.graphics.draw(v, 0, 0)
    v:clear()
  end
end

return {
  draw = draw,
  tint = tint,
  delete = delete,
  rectangle = rectangle,
  flush = flush,
}
