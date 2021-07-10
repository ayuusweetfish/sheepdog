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
    {1, 2, 0, 0, 0},
    {6},
    "   1",
    "─   ",
    tutorial = {
      {0.12, 0.08, 'click here', 'storehouse_click 1'},
      {0.5, 0.6, 'put it here', 'put 2 2'},
      {0.5, 0.6, 'click to rotate', 'rotate_path'},
      {0.55, 0.35, 'build a route to the sheepfold', 'empty'},
      {0.05, 0.8, 'when done, click play button', 'run'},
    }
  },
  [2] = {
    {1, 0, 0, 0, 0},
    {3},
    "── ──── ──1",
    tutorial = {
      {0.12, 0.08, 'not enough??', 'put 1 3'},
      {0.12, 0.08, 'not enough??', 'rotate_path'},
      {0.05, 0.8, 'let\'s play first', 'run'},
      {0, 0, '', 'delay 600'},
      {0.56, 0.55, 'drag the previous one here!', 'put 1 8'},
    }
  },
  [3] = {
    {0, 0, 2, 0, 2},
    {6},
    "    ┌1",
    "    │ ",
    "── ─  ",
    tutorial = {
      {0.12, 0.35, 'try the crossroads', 'storehouse_click 3'},
      {0.45, 0.65, 'put it next here', 'put 3 3'},
      {0.45, 0.65, 'rotate it', 'rotate_path'},
      {0.05, 0.8, 'let\'s try to play and see what happens', 'run'},
      {0, 0, '', 'delay 240'},
      {0.45, 0.65, 'the sheep are confused!', 'delay 480'},
      {0.45, 0.65, 'the sheep are confused!'},
      {0.05, 0.8, 'so let\'s go back and change a bit', 'stop'},
      {0.12, 0.65, 'this dog will help you', 'storehouse_click 5'},
      {0.45, 0.65, 'put it on the crossroads', 'put 3 3'},
      {0.45, 0.65, 'the sheep now know where to go', 'delay 480'},
      {0.45, 0.65, 'the sheep now know where to go'},
      {0.12, 0.35, 'you can do the rest!', 'empty'},
      {0.05, 0.8, 'click play when ready'},
    }
  },
  [4] = {
    {0, 0, 0, 0, 1},
    {4, 4, 4},
    "  ┌─1",
    "  │  ",
    "──┴─2",
    tutorial = {
      {0.2, 0.85, 'this time there are two flocks', 'delay 600'},
      {0.2, 0.85, 'this time there are two flocks'},
      {0.5, 0.65, 'we need a dog here and turn it during play', 'put 3 3'},
      {0.5, 0.65, 'we need a dog here and turn it during play'},
      {0.05, 0.8, 'play', 'run'},
      {0.5, 0.65, 'wait', 'delay 600'},
      {0.5, 0.65, 'click the dog to turn', 'rotate_dog', true},
      {0.5, 0.65, 'now the other flock go to their home'},
    }
  },
  [5] = {
    {4, 3, 2, 0, 2},
    {3, 1, 3},
    "    o 1",
    " ┌─┼   ",
    "  o    ",
    "  o   2",
    "─      ",
  },
}
