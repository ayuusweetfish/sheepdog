--[[
format for each level:
  {items}   items: I, L, T, +, dog
  {sheep}   flock 1 length, rest length, flock 2 length, etc.
  "grid"
    space = empty
    o = obstacle
    1234 = sheepfold with entrance facing left
    ABCD = sheepfold with entrance facing right
    box drawing characters = fixed paths
      ─ │ ┌ ┐ └ ┘ ├ ┤ ┬ ┴ ┼
]]
return {
  [1] = {
    {4, 3, 2, 0, 2},
    {3, 1, 3},
    "    o 1",
    " ┌─┼   ",
    "  o    ",
    "  o   2",
    "─      ",
  },
}
