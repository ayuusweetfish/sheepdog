local cache = {}

local function draw(name, x, y, r, w, h)
  local tex = cache[name]
  if tex == nil then
    tex = love.graphics.newImage('res/' .. name .. '.png')
    cache[name] = tex
  end
  local tw, th = tex:getDimensions()
  love.graphics.draw(tex, x + w / 2, y + h / 2, r, w / tw, h / th, tw / 2, th / 2)
end

local function flush()
  -- No-op before spritesheets and batches are implemented
end

return {
  draw = draw,
  flush = flush,
}
