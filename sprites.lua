local cache = {}

local function texture(name)
  local tex = cache[name]
  if tex == nil then
    tex = love.graphics.newImage('res/' .. name .. '.png')
    cache[name] = tex
  end
  return tex
end

local function dimensions(name)
  return texture(name):getDimensions()
end

local function draw(name, x, y, w, h, layer, r, ox, oy)
  local tex = texture(name)
  local tw, th = tex:getDimensions()
  layer = layer or 0
  r = r or 0
  ox = ox or 0.5
  oy = oy or 0.5
  love.graphics.draw(tex, x + w * ox, y + h * oy, r, w / tw, h / th, tw * ox, th * oy)
end

local function delete(name)
  cache[name] = nil
end

local function flush()
  -- No-op before spritesheets and batches are implemented
end

return {
  draw = draw,
  dimensions = dimensions,
  delete = delete,
  flush = flush,
}
