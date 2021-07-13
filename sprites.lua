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

local function draw(name, x, y, w, h, layer, r, ox, oy)
  layer = layer or 0
  r = r or 0
  ox = ox or 0
  oy = oy or 0
  local item = lookup[name]
  local cw, ch = item.w, item.h
  local tx, ty = item.tx, item.ty
  local scalex, scaley = w / cw, h / ch
  item.batch:add(item.quad,
    x, y,
    r, scalex, scaley,
    -tx + cw * ox, -ty + ch * oy)
end

local function rectangle(x, y, w, h)
  draw('white_pixel', x, y, w, h)
end

local function tint(r, g, b, a)
  for _, v in ipairs(batches) do
    v:setColor(r, g, b, a)
  end
end

local function delete(name)
  cache[name] = nil
end

local function flush()
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
