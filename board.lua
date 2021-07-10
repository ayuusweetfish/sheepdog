local Board = {
  EMPTY = 0,
  OBSTACLE = 1,
  ENTRY = 10,
}

function Board.create(level)
  local w, h = 16, 10
  local grid = {}
  for r = 1, h do
    grid[r] = {}
    for c = 1, w do grid[r][c] = Board.EMPTY end
  end
  grid[h][1] = Board.ENTRY

  return {
    w = w, h = h,
    grid = grid,
  }
end

return Board
