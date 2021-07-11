local cache = {}

local function texture(name)
  local tex = cache[name]
  if tex == nil then
    tex = love.graphics.newImage('res/' .. name .. '.png')
    cache[name] = tex
  end
  return tex
end

local function draw(name, x, y, r, w, h, ox, oy)
  local tex = texture(name)
  local tw, th = tex:getDimensions()
  ox = ox or 0.5
  oy = oy or 0.5
  love.graphics.draw(tex, x + w * ox, y + h * oy, r, w / tw, h / th, tw * ox, th * oy)
end

local function flush()
  -- No-op before spritesheets and batches are implemented
end

return {
  draw = draw,
  flush = flush,
}
