require 'utils'
local popcount4, ctz4, cellDog, cloneGrid = popcount4, ctz4, cellDog, cloneGrid

local utf8 = require 'utf8'

local levels = require 'levels'

local Board = {
  -- cell types
  EMPTY = 0,
  OBSTACLE = 1,
  OBSTACLE_SHEEPFOLD = 2,

  PATH = 256,
  -- bits 0, 1, 2, 3: path N/E/S/W
  -- bits 4, 5, 6, 7: dog (4-bit integer, lower 2b = direction, upper 2b = type)
  -- higher bits: type

  TYPE_ORDINARY_PATH = 1,
  TYPE_SHEEPFOLD = 5, -- flock index = type - TYPE_SHEEPFOLD + 1
  TYPE_SHEEPFOLD_MAX = 5 + 16 - 1,

  TYPE_MAX = 32,
  ENTRY = 8192, -- PATH * TYPE_MAX

  CELL_SUBDIV = 120,
}

local MOVE = {
  [0] = {-1, 0}, {0, 1}, {1, 0}, {0, -1}
}
local function move(from, dir)
  return from[1] + MOVE[dir][1], from[2] + MOVE[dir][2]
end

function Board.create(level)
  local levelData = levels[level]
  if levelData == nil then error('No such level') end

  local itemCount = levelData[1]

  -- {flock index, count}
  local sheepFlocks = {}
  for i, val in ipairs(levelData[2]) do
    sheepFlocks[i] = {
      i % 2 == 1 and math.ceil(i / 2) or -1,
      val
    }
  end

  local sheep = {}
  -- flock: flock index
  -- eta: time until arrival
  -- from: {row, col}
  -- to: {row, col}
  -- dir: 0-3 = N/E/S/W
  -- prog: 0 = at <from>, Board.CELL_SUBDIV = at <to>
  -- sheepfold: whether already in the sheepfold
  -- wrongSheepfold: whether in a wrong sheepfold
  -- confused: whether confused

  local w, h = utf8.len(levelData[3]), #levelData - 2
  local gridInit = {}
  local entryRow = -1
  for r = 1, h do
    local row = {}
    gridInit[r] = row
    if utf8.len(levelData[r + 2]) ~= w then
      error('Incorrect number of characters in row ' .. tostring(r))
    end
    for _, char in utf8.codes(levelData[r + 2]) do
      local map = {
        [' '] = Board.EMPTY,
        ['o'] = Board.OBSTACLE,
        ['>'] = Board.PATH * Board.TYPE_ORDINARY_PATH + 2 + 8 + Board.ENTRY,
        ['─'] = Board.PATH * Board.TYPE_ORDINARY_PATH + 2 + 8,
        ['│'] = Board.PATH * Board.TYPE_ORDINARY_PATH + 1 + 4,
        ['┌'] = Board.PATH * Board.TYPE_ORDINARY_PATH + 2 + 4,
        ['┐'] = Board.PATH * Board.TYPE_ORDINARY_PATH + 4 + 8,
        ['└'] = Board.PATH * Board.TYPE_ORDINARY_PATH + 1 + 2,
        ['┘'] = Board.PATH * Board.TYPE_ORDINARY_PATH + 8 + 1,
        ['├'] = Board.PATH * Board.TYPE_ORDINARY_PATH + 1 + 2 + 4,
        ['┤'] = Board.PATH * Board.TYPE_ORDINARY_PATH + 4 + 8 + 1,
        ['┬'] = Board.PATH * Board.TYPE_ORDINARY_PATH + 2 + 4 + 8,
        ['┴'] = Board.PATH * Board.TYPE_ORDINARY_PATH + 8 + 1 + 2,
        ['┼'] = Board.PATH * Board.TYPE_ORDINARY_PATH + 1 + 2 + 4 + 8,
        ['1'] = Board.PATH * (Board.TYPE_SHEEPFOLD + 0) + 4,
        ['2'] = Board.PATH * (Board.TYPE_SHEEPFOLD + 1) + 4,
        ['3'] = Board.PATH * (Board.TYPE_SHEEPFOLD + 2) + 4,
        ['4'] = Board.PATH * (Board.TYPE_SHEEPFOLD + 3) + 4,
        ['A'] = Board.PATH * (Board.TYPE_SHEEPFOLD + 0) + 8,
        ['B'] = Board.PATH * (Board.TYPE_SHEEPFOLD + 1) + 8,
        ['C'] = Board.PATH * (Board.TYPE_SHEEPFOLD + 2) + 8,
        ['D'] = Board.PATH * (Board.TYPE_SHEEPFOLD + 3) + 8,
      }
      char = utf8.char(char)
      row[#row + 1] = map[char]
      if char == '>' then entryRow = r end
    end
  end
  if entryRow == -1 then error('No entry!') end

  -- Mark obstacles by sheepfolds
  for r = 1, h do
    for c = 1, w do
      local cell = gridInit[r][c]
      local ty = math.floor(cell / Board.PATH) % Board.TYPE_MAX
      if ty >= Board.TYPE_SHEEPFOLD and ty <= Board.TYPE_SHEEPFOLD_MAX then
        if bit.band(cell, 4) ~= 0 then
          -- Down-facing
          if c - 1 < 1 or c + 1 > w then error('Insufficient space for sheepfold') end
          gridInit[r][c - 1] = Board.OBSTACLE_SHEEPFOLD
          gridInit[r][c + 1] = Board.OBSTACLE_SHEEPFOLD
        else
          if r - 1 < 1 or r + 1 > h then error('Insufficient space for sheepfold') end
          gridInit[r - 1][c] = Board.OBSTACLE_SHEEPFOLD
          gridInit[r + 1][c] = Board.OBSTACLE_SHEEPFOLD
        end
      end
    end
  end

  local grid = {}

  local function reset()
    -- Reset grid
    cloneGrid(grid, gridInit)
    -- Reset sheep
    for k = 1, #sheep do sheep[k] = nil end
    local eta = 1
    for _, flock in ipairs(sheepFlocks) do
      if flock[1] ~= -1 then
        for i = 1, flock[2] do
          sheep[#sheep + 1] = {
            flock = flock[1],
            eta = (eta + (i - 1)) * Board.CELL_SUBDIV
          }
        end
      end
      eta = eta + flock[2]
    end
  end
  reset()

  local function update()
    -- index: flock * w * h + r * w + c, value: true
    local occupy = {}
    local flockLargestETA = {}

    for _, sh in ipairs(sheep) do
      if sh.eta > 0 then
        sh.eta = sh.eta - 1
        if sh.eta == 0 then
          -- Appear, if not blocked
          if not occupy[sh.flock * w * h + entryRow * w + 1] then
            sh.from = {entryRow, 0}
            sh.to = {entryRow, 1}
            sh.dir = 1
            sh.prog = 0
            sh.sheepfold = false
            sh.wrongSheepfold = false
            sh.confused = false
          else
            sh.eta = 1
          end
        end
        -- Ensure that current sheep has an ETA no smaller than
        -- that of any previous one in the same flock + CELL_SUBDIV
        local largest = flockLargestETA[sh.flock]
        if largest ~= nil and sh.eta < largest + Board.CELL_SUBDIV then
          sh.eta = largest + Board.CELL_SUBDIV
        end
        flockLargestETA[sh.flock] = sh.eta
      else
        local confused = false
        if sh.prog < Board.CELL_SUBDIV then
          sh.prog = sh.prog + 1
        end
        -- Arrived at destination?
        -- This check is repeated for stuck ones
        if sh.prog == Board.CELL_SUBDIV then
          -- Current cell
          local cell = grid[sh.to[1]][sh.to[2]]

          -- Move
          local dir = -1
          local ty = math.floor(cell / Board.PATH) % Board.TYPE_MAX
          if ty == Board.TYPE_ORDINARY_PATH then
            -- Ordinary path
            local count = popcount4(cell)
            if count == 2 then
              -- Go to the other outlet
              dir = ctz4(bit.bxor(cell % 16, bit.lshift(1, (sh.dir + 2) % 4)))
            else
              -- Check for the dog
              local dog = cellDog(cell)
              if dog ~= 0 then
                dir = dog % 4
                -- Not going back
                if (dir + 2) % 4 == sh.dir then
                  dir = -1
                  confused = true
                end
              else
                confused = true
              end
            end

          elseif ty >= Board.TYPE_SHEEPFOLD and ty <= Board.TYPE_SHEEPFOLD_MAX then
            -- Sheepfold
            local flock = ty - Board.TYPE_SHEEPFOLD + 1
            if sh.flock == flock then
              sh.sheepfold = true
            else
              sh.wrongSheepfold = true
            end
          end

          -- Check for viability
          if dir ~= -1 then
            local r1, c1 = move(sh.to, dir)

            -- Destination has no corresponding inlet?
            if r1 < 1 or r1 > h or c1 < 1 or c1 > w or
                grid[r1][c1] < Board.PATH or
                bit.band(grid[r1][c1] % 16, bit.lshift(1, (dir + 2) % 4)) == 0
            then
              dir = -1
              confused = true

            -- Blocked by another sheep in the same flock?
            elseif occupy[sh.flock * w * h + r1 * w + c1] then
              dir = -1
            end
          end
          -- Move
          if dir ~= -1 then
            local r1, c1 = move(sh.to, dir)
            sh.dir = dir
            sh.from = sh.to
            sh.to = {r1, c1}
            sh.prog = 0
          end
        end
        sh.confused = confused
      end
      -- Mark destination cell as occupied
      if not sh.sheepfold and sh.to ~= nil then
        if occupy[sh.flock * w * h + sh.to[1] * w + sh.to[2]] then print('!!!') end
        occupy[sh.flock * w * h + sh.to[1] * w + sh.to[2]] = true
      end
    end
  end

  return {
    w = w, h = h,
    gridInit = gridInit,
    entryRow = entryRow,
    sheepFlocks = sheepFlocks,
    itemCount = itemCount,
    grid = grid,
    sheep = sheep,
    update = update,
    reset = reset,
    tutorial = levelData.tutorial,
  }
end

return Board
