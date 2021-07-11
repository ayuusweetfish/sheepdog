--[[
format for each level:
  {items}   items: I, L, T, +, dog
  {sheep}   flock 1 length, rest length, flock 2 length, etc.
  "grid"
    space = empty
    o = obstacle
    1234 = sheepfold with entrance facing down
    ABCD = sheepfold with entrance facing left
    box drawing characters = fixed paths
      ─ │ ┌ ┐ └ ┘ ├ ┤ ┬ ┴ ┼
]]
return {
  [1] = {
    {2, 1, 0, 0, 0},
    {6},
    "  1 ",
    "    ",
    ">   ",
    tutorial = {
      {-1, 'btn_storehouse 1'},
      {0.12, 0.08, 'take it', 'storehouse_click 1'},
      {-1, 'cell 3 2'},
      {0.5, 0.6, 'put it here', 'put 3 2'},
      {-1, 'cell 3 2', nil, nil, {instant = true}},
      {0.5, 0.6, 'click to rotate', 'rotate_path 3 2'},
      {0.55, 0.32, 'build a route to the sheepfold\nyou can do the rest!', 'empty'},
      {0.05, 0.8, 'when done, click play button', 'run'},
    }
  },
  [2] = {
    {1, 0, 0, 0, 0},
    {3},
    "ooooooooooo",
    ">─ ──── ──A",
    "ooooooooooo",
    tutorial = {
      {-1, 'btn_storehouse 1'},
      {0.12, 0.08, 'not enough??', 'storehouse_click 1'},
      {-1, 'cell 2 3'},
      {0.35, 0.4, 'try anyway', 'put 2 3'},
      {-1, 'cell 2 3', nil, nil, {instant = true}},
      {0.35, 0.4, 'try anyway', 'rotate_path 2 3', {instant = true}},
      {-1, 'btn_run'},
      {0.05, 0.8, 'let\'s play first', 'run'},
      {0, 0, '', 'delay 1080'},
      {-1, 'cell 2 3'},
      {-1, 'cell 2 8'},
      {0.56, 0.55, 'drag the previous one here!', 'put 2 8'},
    }
  },
  [3] = {
    {0, 0, 2, 0, 2},
    {6},
    "    1 ",
    "    │ ",
    ">─ ─  ",
    tutorial = {
      {-1, 'btn_storehouse 3'},
      {0.12, 0.35, 'try the crossroads', 'storehouse_click 3'},
      {-1, 'cell 3 3'},
      {0.45, 0.65, 'put it next here', 'put 3 3'},
      {-1, 'cell 3 3', nil, nil, {instant = true}},
      {0.45, 0.65, 'rotate it', 'rotate_path 3 3'},
      {-1, 'btn_run'},
      {0.05, 0.8, 'let\'s try to play and see what happens', 'run'},
      {0, 0, '', 'delay 540'},
      {0.45, 0.65, 'the sheep are confused!', 'delay 480'},
      {-1, 'btn_run'},
      {0.45, 0.65, 'the sheep are confused!', nil, {instant = true}},
      {0.05, 0.8, 'so let\'s go back and change a bit', 'stop'},
      {-1, 'btn_storehouse 5'},
      {0.12, 0.65, 'the dog will help you', 'storehouse_click 5'},
      {-1, 'cell 3 3'},
      {0.45, 0.65, 'put it on the crossroads', 'put 3 3'},
      {0.45, 0.65, 'the sheep now know where to go', 'delay 480'},
      {0.45, 0.65, 'the sheep now know where to go', nil, {instant = true}},
      {0.12, 0.35, 'you can do the rest!', 'empty'},
      {0.05, 0.8, 'click play when ready'},
    }
  },
  [4] = {
    {0, 0, 0, 0, 1},
    {4, 3, 4},
    "  1   ",
    "  │   ",
    ">─┴──B",
    "      ",
    tutorial = {
      {-1, 'prog_ind'},
      {0.2, 0.85, 'this time there are two flocks', 'delay 900'},
      {-1, 'btn_storehouse 5'},
      {-1, 'cell 3 3'},
      {0.5, 0.65, 'we need a dog here', 'put 3 3'},
      {-1, 'btn_run'},
      {0, 0, '', 'run'},
      {0.5, 0.65, 'wait', 'delay 580'},
      {-1, 'cell 3 3'},
      {0.5, 0.65, 'click the dog to turn', 'rotate_dog 3 3', {blocksBoard = true}},
      {0.5, 0.65, 'now the other flock go to their home'},
    }
  },
  [5] = {
    {4, 3, 2, 0, 2},
    {3, 1, 3},
    "       ",
    "    o A",
    " ┌─┼   ",
    "  o    ",
    "  o   B",
    ">      ",
  },
  [6] = {
    {0, 0, 0, 0, 0},
    {10},
    "                             ",
    ">                           1",
    "                             ",
  },
  [7] = {
    {0, 1, 0, 0, 0},
    {10},
    "  1 ",
    ">─  ",
  },
  [8] = {
    {0, 0, 0, 0, 0},
    {10},
    ">┐ ",
    " │ ",
    " │ ",
    " │ ",
    " │ ",
    " │ ",
  },
}
