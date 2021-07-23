local cache = {}

local function texture(name)
  local tex = cache[name]
  if tex == nil then
    tex = love.graphics.newImage('res/sprites/' .. name .. '.png')
    cache[name] = tex
  end
  return tex
end

local function draw(name, x, y, w, h, layer, r, ox, oy)
  -- layer = layer or 0
  r = r or 0
  ox = ox or 0
  oy = oy or 0
  local tex = texture(name)
  local cw, ch = tex:getDimensions()
  local scalex, scaley = w / cw, h / ch
  -- Only one batch
  love.graphics.draw(tex,
    x, y,
    r, scalex, scaley,
    cw * ox, ch * oy)
end

local function delete(name)
  cache[name] = nil
end

-- Optimized for batch drawing
local function drawMulti(name, posList, w, h, layer, r, ox, oy)
  for i = 1, #posList, 2 do
    draw(name, posList[i], posList[i + 1], w, h, layer, r, ox, oy)
  end
end

local function rectangle(x, y, w, h)
  draw('white_pixel', x, y, w, h)
end

local function tint(r, g, b, a)
  love.graphics.setColor(r, g, b, a)
end

local function delete(name)
  cache[name] = nil
end

local function flush()
  -- No-op before spritesheets and batches are implemented
end

return {
  draw = draw,
  drawMulti = drawMulti,
  tint = tint,
  delete = delete,
  rectangle = rectangle,
  flush = flush,
}
