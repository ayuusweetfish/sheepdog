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
    {2, 1, 0, 0, 0, 0},
    {6},
    "  1 ",
    "    ",
    ">   ",
    tutorial = {
      {-1, 'btn_storehouse 1'},
      {0.14, 0.08, '从仓库中取出一个道路格子', 'storehouse_click 1'},
      {-1, 'cell 3 2'},
      {0.5, 0.875, '放在这里', 'put 3 2'},
      {-1, 'cell 3 2', nil, nil, {instant = true}},
      {0.5, 0.875, '点击以旋转', 'rotate_path 3 2'},
      {0.55, 0.2, '建造一条通往羊圈的道路\n接下来就交给你啦！', 'empty'},
      {-2, 'btn_run'},
      {0.05, 0.765, '完成后就让小羊回到羊圈吧', 'run'},
    }
  },
  [2] = {
    {0, 0, 2, 0, 2, 0},
    {6},
    "    1 ",
    "    │ ",
    ">─ ─  ",
    tutorial = {
      {-1, 'btn_storehouse 3'},
      {0.14, 0.35, '交叉路口格子', 'storehouse_click 3'},
      {-1, 'cell 3 3'},
      {0.45, 0.55, '放置在这里', 'put 3 3'},
      {-1, 'cell 3 3', nil, nil, {instant = true}},
      {0.45, 0.55, '点击旋转', 'rotate_path 3 3'},
      {-1, 'btn_run'},
      {0.05, 0.76, '小羊能顺利通行吗？', 'run'},
      {0, 0, '', 'delay 540'},
      {0.45, 0.4, '小羊还不太会认路呢！', 'delay 480'},
      {-1, 'btn_stop'},
      {0.45, 0.4, '小羊还不太会认路呢！', nil, {instant = true}},
      {0.05, 0.76, '需要我们做些改动', 'stop'},
      {-1, 'btn_storehouse 5'},
      {0.22, 0.08, '牧羊犬是小羊的好伙伴', 'storehouse_click 5'},
      {-1, 'cell 3 3'},
      {0.45, 0.55, '交叉路口需要放置牧羊犬引路', 'put 3 3'},
      {0.45, 0.4, '道路上出现的脚印表示\n牧羊犬指引小羊向右前进', 'delay 480'},
      {0.45, 0.4, '道路上出现的脚印表示\n牧羊犬指引小羊向右前进', nil, {instant = true}},
      {-2, 'btn_storehouse 3'},
      {-2, 'btn_storehouse 5'},
      {0.17, 0.35, '接下来就交给你啦！', 'empty'},
      {-2, 'btn_run'},
      {0.05, 0.76, '完成后就让小羊回到羊圈吧', 'run'},
    }
  },
  [3] = {
    {2, 2, 2, 0, 2, 0},
    {4},
    "      ",
    ">  o A",
    "      ",
    tutorial = {
      {-2, 'cell 2 5'},
      {0.7, 0.2, '南北方向的羊圈\n同样只能从中间一格进入', 'put 2 5'},
    },
  },
  [4] = {
    {0, 0, 0, 0, 1, 0},
    {4, 3, 4},
    "  1   ",
    "  │   ",
    ">─┴──B",
    "      ",
    tutorial = {
      {-1, 'prog_ind'},
      {0.27, 0.2, '两群小羊各四只，\n需要回到各自的羊圈', 'delay 900'},
      {-1, 'cell 1 4'},
      {-1, 'cell 2 6'},
      {0.4, 0.45, '羊圈颜色与\n小羊头上小花的颜色对应', 'delay 1080'},
      {-1, 'btn_storehouse 5'},
      {-1, 'cell 3 3'},
      {0.5, 0.78, '在这里放置牧羊犬', 'put 3 3'},
      {-1, 'btn_run'},
      {0, 0, '', 'run'},
      {0.5, 0.78, '第一群小羊顺利抵达红色羊圈……', 'delay 1080'},
      {-1, 'cell 3 3'},
      {0.5, 0.78, '点击改变牧羊犬指引的方向', 'rotate_dog 3 3', {blocksBoard = true}},
      {0.5, 0.78, '第二群小羊可以回到黄色羊圈了！'},
    }
  },
  [5] = {
    {4, 3, 1, 0, 2, 0},
    {6, 4, 6},
    "       ",
    "    o A",
    " ┌─┼   ",
    "  o    ",
    "  o   B",
    ">      ",
  },
  [6] = {
    {0, 0, 0, 0, 1, 1},
    {4, 4, 4},
    "  1  2 ",
    "  ┼  ┼ ",
    "  │  │ ",
    ">─┴──┘ ",
    tutorial = {
      {-1, 'btn_storehouse 6'},
      {0.22, 0.2, '喜乐蒂牧羊犬可以在\n小羊前进的过程中移动', 'storehouse_click 6'},
      {-1, 'cell 2 3', nil, 'put 2 3'},
      {-1, 'btn_storehouse 5', nil, 'storehouse_click 5'},
      {-1, 'cell 4 3', nil, 'put 4 3'},
      {-1, 'btn_run', nil, 'run'},
      {0, 0, '', 'delay 1200'},
      {-1, 'cell 4 3'},
      {0.45, 0.61, '旋转', 'rotate_dog 4 3', {blocksBoard = true}},
      {0, 0, '', 'delay 900'},
      {-1, 'cell 2 3'},
      {-1, 'cell 2 6'},
      {0.65, 0.67, '将喜乐蒂牧羊犬拖动到此处', 'put 2 6', {blocksBoard = true}},
    },
  },
  [7] = {
    {5, 1, 2, 0, 1, 1},
    {4, 4, 4},
    " 1  2 ",
    "      ",
    "  oo  ",
    " ├oo  ",
    ">  ─  ",
  },
  [8] = {
    {0, 0, 0, 0, 0, 1},
    {2, 3, 2, 3, 6},
    "  1   3  ",
    ">─┴───┴─B",
    "  oo   o ",
    tutorial = {
      {0, 0, '', 'run_progress 1440 2'},
      {-1, 'cell 2 3'},
      {-1, 'cell 2 7'},
      {0.6, 0.65, '牧羊犬被移动时，会保留原来的方向', 'put 2 7', {blocksBoard = true}},
    },
  },
  [9] = {
    {0, 0, 0, 0, 0, 1},
    {2, 4, 2, 10, 2},
    "     2 o",
    "  oo │  ",
    ">┬───┤  ",
    " │   │  ",
    " └─C └─A",
    "        ",
    tutorial = {
      {0, 0, '', 'empty'},
      {0, 0, '', 'run_progress 600 0'},
      {-1, 'cell 3 2'},
      {-1, 'cell 3 6'},
      {0.6, 0.25, '如果原本的方向不存在道路，\n牧羊犬会顺时针旋转', 'put 3 6', {blocksBoard = true}},
    },
  },
  [10] = {
    {4, 3, 2, 0, 0, 1},
    {2, 4, 2, 4, 2},
    " 1     ",
    "     B ",
    ">      ",
    "oo    C",
    " o     ",
  },
  [11] = {
    {10, 10, 10, 10, 10, 10},
    {4, 2, 4, 2, 4, 2, 4},
    "        ",
    "        ",
    ">       ",
    "        ",
    "     o  ",
    "        ",
    tutorial = {
      {0.3, 0.5, '恭喜通关啦！', 'delay 800'},
    },
  },
  [91] = {
    {0, 0, 0, 0, 0, 0},
    {10},
    "         ",
    ">       A",
    "         ",
  },
  [92] = {
    {0, 1, 0, 0, 0, 0},
    {10},
    "    ",
    ">─A ",
    "    ",
  },
  [93] = {
    {0, 0, 0, 0, 0, 0},
    {10},
    ">┐ ",
    " │ ",
    " │ ",
    " │ ",
    " │ ",
    " │ ",
  },
  [94] = {
    {0, 0, 0, 0, 1, 0},
    {10},
    "  1  ",
    ">─┼──",
  },
}
