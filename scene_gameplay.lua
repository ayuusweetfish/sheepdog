require 'utils'
local popcount4, ctz4, cellDog, cloneGrid = popcount4, ctz4, cellDog, cloneGrid

local Board = require 'board'
local buttons = require 'buttons'
local tutorial = require 'tutorial'

local sprites = require 'sprites'

local BORDER_PAD = 12
local ITEM_SIZE = 60
local ITEM_SPACE = 12
local STORE_WIDTH = ITEM_SIZE + BORDER_PAD * 2
local CELL_SIZE = 40

return function ()
  local s = {}

  local board = Board.create(4)
  local itemCount = {}

  local tutAreas = {}
  local tut = tutorial(board.tutorial, tutAreas)

  -- Selected storehouse item and feasible regions
  local selectedItem = -1
  local selectedValue = 0
  local selectedDrag = false  -- if true, should recover to (holdRow, holdCol) on failure
  local feasible = {}
  for r = 1, board.h do
    feasible[r] = {}
    for c = 1, board.w do feasible[r][c] = false end
  end

  local function editable(r, c)
    return
      r >= 1 and r <= board.h and
      c >= 1 and c <= board.w and
      board.gridInit[r][c] == Board.EMPTY
  end

  local function updateFeasiblility()
    if selectedItem >= 1 and selectedItem <= 4 then
      -- Path cells can be placed in any empty cell
      for r = 1, board.h do
        for c = 1, board.w do
          feasible[r][c] = (board.grid[r][c] == Board.EMPTY)
        end
      end
    elseif selectedItem == 5 then
      -- Dogs can be placed in junctions
      for r = 1, board.h do
        for c = 1, board.w do
          feasible[r][c] = (board.grid[r][c] >= Board.PATH and
            popcount4(board.grid[r][c]) >= 3 and
            cellDog(board.grid[r][c]) == 0)
        end
      end
    end
  end

  -- Animations on each cell, {row, column, type, remaining time}
  local cellAnim = {}
  local ANIM_TYPE_PUT = 1
  local ANIM_TYPE_REMOVE = 2
  local ANIM_TYPE_ROTATE = 3
  local ANIM_DUR = 120
  local function easeProgRem(t)
    local x = t / ANIM_DUR
    return (math.exp(8 * x) - 1) / (math.exp(8) - 1)
  end
  local function easeProg(t)
    return 1 - easeProgRem(t)
  end

  local btnsStorehouse = buttons()
  local itemSprites = {
    'path1', 'path2', 'path3', 'path4', 'ice-cream_1f368'
  }
  for i = 1, 5 do
    local sprite = love.graphics.newImage('res/' .. itemSprites[i] .. '.png')
    sprite:setFilter('nearest', 'nearest')
    btnsStorehouse.add(
      BORDER_PAD,
      BORDER_PAD + (ITEM_SIZE + ITEM_SPACE) * (i - 1),
      ITEM_SIZE, ITEM_SIZE,
      sprite,
      function ()
        if selectedItem == i then
          selectedItem = -1
          return
        end
        selectedItem = i
        selectedDrag = false
        if selectedItem == 1 then selectedValue = 1 + 4
        elseif selectedItem == 2 then selectedValue = 1 + 2
        elseif selectedItem == 3 then selectedValue = 1 + 2 + 4
        elseif selectedItem == 4 then selectedValue = 1 + 2 + 4 + 8
        elseif selectedItem == 5 then selectedValue = 1
        end
        updateFeasiblility()
        tut.emit('storehouse_click ' .. selectedItem)
      end
    )
    tutAreas['btn_storehouse ' .. i] = {
      BORDER_PAD,
      BORDER_PAD + (ITEM_SIZE + ITEM_SPACE) * (i - 1),
      ITEM_SIZE, ITEM_SIZE
    }
  end

  local function resetItemCount()
    for i = 1, 5 do
      itemCount[i] = board.itemCount[i]
      btnsStorehouse.enable(i, itemCount[i] > 0)
    end
  end
  resetItemCount()

  local boardRunning = false
  local boardRunProgress = 0

  -- Run button
  local runButton
  local savedGrid = {}
  local savedItemCount = {}
  local function updateRunButtonSprite()
    btnsStorehouse.sprite(runButton,
      boardRunning and 'res/black-left-pointing-double-triangle_23ea.png' or
      'res/black-right-pointing-triangle_25b6.png')
  end
  runButton = btnsStorehouse.add(
    BORDER_PAD, H - BORDER_PAD - 50, 50, 50,
    'res/black-right-pointing-triangle_25b6.png',
    function ()
      boardRunning = not boardRunning
      selectedItem = -1
      boardRunProgress = 0
      updateRunButtonSprite()
      if boardRunning then
        -- Save board state
        cloneGrid(savedGrid, board.grid)
        for i = 1, 5 do savedItemCount[i] = itemCount[i] end
        tut.emit('run')
      else
        board.reset()
        -- Restore board state
        cloneGrid(board.grid, savedGrid)
        for i = 1, 5 do
          itemCount[i] = savedItemCount[i]
          btnsStorehouse.enable(i, itemCount[i] > 0)
        end
        tut.emit('stop')
      end
    end
  )
  tutAreas['btn_run'] = {BORDER_PAD, H - BORDER_PAD - 50, 50, 50}

  -- Reset button
  btnsStorehouse.add(
    BORDER_PAD + 50, H - BORDER_PAD - 50, 50, 50,
    'res/leftwards-arrow-with-hook_21a9.png',
    function ()
      boardRunning = false
      updateRunButtonSprite()
      board.reset()
      resetItemCount()
    end
  )

  local xStart = (W + STORE_WIDTH) / 2 - CELL_SIZE * board.w / 2
  local yStart = H / 2 - CELL_SIZE * board.h / 2

  for r = 1, board.h do
    for c = 1, board.w do
      tutAreas['cell ' .. r .. ' ' .. c] = {
        xStart + (c - 1) * CELL_SIZE,
        yStart + (r - 1) * CELL_SIZE,
        CELL_SIZE, CELL_SIZE
      }
    end
  end

  local function cellPos(x, y)
    return math.floor((y - yStart) / CELL_SIZE) + 1,
           math.floor((x - xStart) / CELL_SIZE) + 1
  end

  local pinpointingItem = false
  local pinpointRow, pinpointCol = -1, -1

  local holdTime = -1
  local holdRow, holdCol = -1, -1

  local dragToStorehouse = false

  s.press = function (x, y)
    if tut.blocksInteractions(x, y) then return end
    if btnsStorehouse.press(x, y) then return end
    if x >= STORE_WIDTH then
      local r, c = cellPos(x, y)
      if selectedItem ~= -1 then
        pinpointingItem = true
      elseif (editable(r, c) and board.grid[r][c] ~= Board.EMPTY)
          or (r >= 1 and r <= board.h and c >= 1 and c <= board.w and
              cellDog(board.grid[r][c]) ~= 0)
      then
        holdTime = 0
        holdRow, holdCol = r, c
      end
    end
    s.move(x, y)
  end

  local function pathCellType(cell)
    local count = popcount4(cell)
    if count == 1 then return 0
    elseif count == 2 then
      if cell % 16 == 1 + 4 or cell % 16 == 2 + 8 then return 1
      else return 2 end
    elseif count == 3 then return 3
    elseif count == 4 then return 4
    end
    return -1
  end

  local pathCellRotationLookup = {
    [0] = 0, 0, math.pi / 2, 0,
    math.pi, 0, math.pi / 2, 0,
    -math.pi / 2, -math.pi / 2, -math.pi / 2, -math.pi / 2,
    math.pi, math.pi, math.pi / 2, 0
  }
  local function pathCellRotation(cell)
    return pathCellRotationLookup[cell % 16]
  end

  local function convertHoldToPinpoint()
    holdTime = -1
    pinpointingItem = true
    pinpointRow, pinpointCol = holdRow, holdCol
    selectedDrag = true

    local cell = board.grid[pinpointRow][pinpointCol]
    local dog = cellDog(cell)
    if dog ~= 0 then
      selectedItem = 5
      selectedValue = dog
      board.grid[pinpointRow][pinpointCol] = cell - dog * 16
    else
      selectedItem = pathCellType(cell)
      selectedValue = cell % 16
      board.grid[pinpointRow][pinpointCol] = Board.EMPTY
    end
    cellAnim[#cellAnim + 1] = {pinpointRow, pinpointCol, ANIM_TYPE_REMOVE, ANIM_DUR}
    updateFeasiblility()
  end

  local function rotateDogForPath(dog, cell)
    while bit.band(cell, bit.lshift(1, dog - 1)) == 0 do
      dog = dog % 4 + 1
    end
    return dog
  end

  s.move = function (x, y)
    if btnsStorehouse.move(x, y) then
      if x >= STORE_WIDTH and selectedItem >= 1 and selectedItem <= 5 then
        -- Treated as if the button has been triggered
        btnsStorehouse.trigger()
        -- Also, we are dragging now
        selectedDrag = true
        pinpointingItem = true
        holdRow, holdCol = -1, -1
      end
    end
    local r, c = cellPos(x, y)
    if pinpointingItem then
      pinpointRow, pinpointCol = r, c
      dragToStorehouse = (x < STORE_WIDTH or
        pinpointRow < -1 or pinpointRow > board.h + 2 or
        pinpointCol < -1 or pinpointCol > board.w + 2)
    elseif holdTime >= 0 then
      if r ~= holdRow or c ~= holdCol then
        convertHoldToPinpoint()
      end
    end
  end

  s.release = function (x, y)
    if btnsStorehouse.release(x, y) then return end
    if pinpointingItem then
      pinpointingItem = false
      pinpointRow, pinpointCol = cellPos(x, y)
      dragToStorehouse = (x < STORE_WIDTH or
        pinpointRow < -1 or pinpointRow > board.h + 2 or
        pinpointCol < -1 or pinpointCol > board.w + 2)
      local destFeasible =
        pinpointRow >= 1 and pinpointRow <= board.h and
        pinpointCol >= 1 and pinpointCol <= board.w and
        feasible[pinpointRow][pinpointCol]
      -- selectedDrag and holdRow == -1:
      -- this is the case when dragging out of the storehouse
      if not destFeasible then
        -- Prohibited cell. If the item has been dragged, recover it
        -- to the original position
        if selectedDrag then
          if dragToStorehouse then
            if holdRow ~= -1 then
              -- Remove from the board and back into the storehouse
              itemCount[selectedItem] = itemCount[selectedItem] + 1
              btnsStorehouse.enable(selectedItem, itemCount[selectedItem] > 0)
            end
            selectedItem = -1
            destFeasible = false
          elseif holdRow ~= -1 then -- Otherwise may be dragging out of the storehouse
            pinpointRow, pinpointCol = holdRow, holdCol
            destFeasible = true
          end
        end
      end
      -- Target location may be changed for recovery so re-check feasibility
      if destFeasible then
        -- Put item down
        if selectedItem >= 1 and selectedItem <= 4 then
          board.grid[pinpointRow][pinpointCol] = Board.PATH + selectedValue
        elseif selectedItem == 5 then
          local cell = board.grid[pinpointRow][pinpointCol]
          board.grid[pinpointRow][pinpointCol] =
            cell + rotateDogForPath(selectedValue, cell) * 16
        end
        if not selectedDrag or holdRow == -1 then
          itemCount[selectedItem] = itemCount[selectedItem] - 1
          btnsStorehouse.enable(selectedItem, itemCount[selectedItem] > 0)
        end
        cellAnim[#cellAnim + 1] = {pinpointRow, pinpointCol, ANIM_TYPE_PUT, ANIM_DUR}
        selectedItem = -1
        tut.emit('put ' .. pinpointRow .. ' ' .. pinpointCol)
        local max = 0
        for _, count in ipairs(itemCount) do
          if max < count then max = count end
        end
        if max == 0 then tut.emit('empty') end
      end
      if selectedDrag and holdRow == -1 then
        selectedItem = -1
      end
    elseif holdTime >= 0 then
      holdTime = -1
      -- Tapped. Rotate the item
      -- Rotate the dog if there is one, otherwise the path
      local cell = board.grid[holdRow][holdCol]
      local sides = cell % 16
      local dog = cellDog(cell)
      if dog >= 1 and dog <= 4 then
        local newDog = rotateDogForPath(dog % 4 + 1, cell)
        cell = cell + (newDog - dog) * 16
        tut.emit('rotate_dog ' .. holdRow .. ' ' .. holdCol)
      else
        local newSides = (sides * 2) % 16 + (bit.arshift(cell, 3) % 2)
        cell = cell + (newSides - sides)
        cellAnim[#cellAnim + 1] = {holdRow, holdCol, ANIM_TYPE_ROTATE, ANIM_DUR}
        tut.emit('rotate_path ' .. holdRow .. ' ' .. holdCol)
      end
      board.grid[holdRow][holdCol] = cell
    end
  end

  s.update = function ()
    btnsStorehouse.update()
    if holdTime >= 0 then
      holdTime = holdTime + 1
      -- Convert to a pinpoint if held for 0.5 second
      if holdTime >= 120 then
        convertHoldToPinpoint()
      end
    end
    -- Update animations
    local i = 1
    while i <= #cellAnim do
      cellAnim[i][4] = cellAnim[i][4] - 1
      if cellAnim[i][4] == 0 then
        -- Replace with the last item
        cellAnim[i] = cellAnim[#cellAnim]
        cellAnim[#cellAnim] = nil
      else
        i = i + 1
      end
    end
    -- Update board
    if boardRunning and not tut.blocksBoardUpdates() then
      board.update()
      boardRunProgress = boardRunProgress + 1
    end
    -- Update tutorial
    tut.update()
  end

  local function flockColour(n)
    if n == 1 then return 1.0, 0.7, 0.5
    elseif n == 2 then return 1.0, 0.5, 0.9
    else return 0.9, 0.9, 0.9
    end
  end

  local function drawSheep(sh)
    if sh.eta == 0 then
      local prog = sh.prog / Board.CELL_SUBDIV
      local r = sh.from[1] * (1 - prog) + sh.to[1] * prog
      local c = sh.from[2] * (1 - prog) + sh.to[2] * prog
      local xCen = xStart + (c - 0.5) * CELL_SIZE
      local yCen = yStart + (r - 0.5) * CELL_SIZE
      love.graphics.setColor(flockColour(sh.flock))
      love.graphics.circle('fill', xCen, yCen, 10)
    else
      -- Maybe draw sheep walking in?
    end
  end

  s.draw = function ()
    -- Grid
    for r = 1, board.h do
      for c = 1, board.w do
        if board.grid[r][c] == Board.OBSTACLE then
          love.graphics.setColor(0.8, 0.4, 0.4)
        elseif (r + c) % 2 == 0 then
          love.graphics.setColor(0.65, 0.85, 0.55)
        else
          love.graphics.setColor(0.55, 0.75, 0.48)
        end
        local xCell = xStart + (c - 1) * CELL_SIZE
        local yCell = yStart + (r - 1) * CELL_SIZE
        love.graphics.rectangle('fill', xCell, yCell, CELL_SIZE, CELL_SIZE)
        if board.grid[r][c] >= Board.PATH then
          local pts = {{0.5, 0}, {1, 0.5}, {0.5, 1}, {0, 0.5}}
          -- Draw path
          local ty = pathCellType(board.grid[r][c])
          if ty == 0 then
            -- TODO: Handle sheepfolds with one inlet
            love.graphics.setColor(1, 0.8, 0.6)
            love.graphics.setLineWidth(CELL_SIZE / 4)
            local dir = ctz4(board.grid[r][c] % 16)
            love.graphics.line(
              xCell + CELL_SIZE * 0.5, yCell + CELL_SIZE * 0.5,
              xCell + CELL_SIZE * pts[dir + 1][1],
              yCell + CELL_SIZE * pts[dir + 1][2])
          else
            local rotation = pathCellRotation(board.grid[r][c])
            for _, anim in ipairs(cellAnim) do
              if anim[1] == r and anim[2] == c and anim[3] == ANIM_TYPE_ROTATE then
                rotation = rotation - easeProgRem(anim[4]) * math.pi / 2
              end
            end
            love.graphics.setColor(1, 1, 1)
            sprites.draw('path' .. ty, xCell, yCell, rotation, CELL_SIZE, CELL_SIZE)
          end
          -- Draw dog
          local dog = cellDog(board.grid[r][c])
          if dog ~= 0 then
            local x1 = (pts[dog][1] - 0.5) * 0.7
            local y1 = (pts[dog][2] - 0.5) * 0.7
            love.graphics.setColor(1, 0.4, 0)
            love.graphics.setLineWidth(2)
            love.graphics.line(
              xCell + CELL_SIZE * 0.5,
              yCell + CELL_SIZE * 0.5,
              xCell + CELL_SIZE * (0.5 + x1),
              yCell + CELL_SIZE * (0.5 + y1)
            )
            love.graphics.line(
              xCell + CELL_SIZE * (0.5 + x1),
              yCell + CELL_SIZE * (0.5 + y1),
              xCell + CELL_SIZE * (0.5 + x1 - (x1 + y1) * 0.4),
              yCell + CELL_SIZE * (0.5 + y1 - (x1 + y1) * 0.4)
            )
            love.graphics.line(
              xCell + CELL_SIZE * (0.5 + x1),
              yCell + CELL_SIZE * (0.5 + y1),
              xCell + CELL_SIZE * (0.5 + x1 - (x1 - y1) * 0.4),
              yCell + CELL_SIZE * (0.5 + y1 + (x1 - y1) * 0.4)
            )
          end
          local ty = math.floor(board.grid[r][c] / Board.PATH)
          if ty >= Board.TYPE_SHEEPFOLD and ty <= Board.TYPE_SHEEPFOLD_MAX then
            love.graphics.setColor(flockColour(ty - Board.TYPE_SHEEPFOLD + 1))
            love.graphics.circle('fill',
              xCell + CELL_SIZE / 2, yCell + CELL_SIZE / 2, CELL_SIZE / 3)
          end
        end
      end
    end

    -- Put/remove animations
    for _, anim in ipairs(cellAnim) do
      if anim[3] == ANIM_TYPE_PUT or anim[3] == ANIM_TYPE_REMOVE then
        local sprite = (anim[3] == ANIM_TYPE_PUT and 'puff' or 'pop')
        local size = CELL_SIZE * (1.1 + easeProg(anim[4]) * 0.9)
        love.graphics.setColor(1, 1, 1,
          anim[4] / ANIM_DUR * (anim[3] == ANIM_TYPE_PUT and 0.3 or 0.7))
        sprites.draw(sprite,
          xStart + (anim[2] - 1) * CELL_SIZE + (CELL_SIZE - size) / 2,
          yStart + (anim[1] - 1) * CELL_SIZE + (CELL_SIZE - size) / 2,
          0, size, size)
      end
    end

    -- Feasible regions
    if selectedItem ~= -1 then
      for r = 1, board.h do
        for c = 1, board.w do
          if feasible[r][c] then
            love.graphics.setColor(0, 1, 0, 0.5)
            love.graphics.rectangle('fill',
              xStart + (c - 1) * CELL_SIZE,
              yStart + (r - 1) * CELL_SIZE,
              CELL_SIZE, CELL_SIZE)
          end
        end
      end
    end

    -- Pinpoint indicators
    if pinpointingItem then
      local alpha   -- Opacity of the shadow sprite
      if dragToStorehouse then
        -- Item will be moved back to the storehouse if dropped here
        love.graphics.setColor(0.9, 0.5, 0.4, 0.1)
        alpha = 0.2
      elseif pinpointRow >= 1 and pinpointRow <= board.h and
         pinpointCol >= 1 and pinpointCol <= board.w and
         feasible[pinpointRow][pinpointCol]
      then
        -- Feasible position
        love.graphics.setColor(0.8, 0.8, 0.4, 0.6)
        alpha = 0.6
      else
        -- Item will be restored to original position if dropped here
        love.graphics.setColor(0.9, 0.5, 0.4, 0.6)
        alpha = 0.2
      end
      local xCell = xStart + (pinpointCol - 1) * CELL_SIZE
      local yCell = yStart + (pinpointRow - 1) * CELL_SIZE
      love.graphics.rectangle('fill', xCell, 0, CELL_SIZE, yCell)
      love.graphics.rectangle('fill', xCell, yCell + CELL_SIZE, CELL_SIZE, H - (yCell + CELL_SIZE))
      love.graphics.rectangle('fill',
        STORE_WIDTH,
        yStart + (pinpointRow - 1) * CELL_SIZE,
        W - STORE_WIDTH, CELL_SIZE
      )
      -- Item image
      love.graphics.setColor(1, 1, 1, alpha)
      sprites.draw(itemSprites[selectedItem],
        xStart + (pinpointCol - 1) * CELL_SIZE,
        yStart + (pinpointRow - 1) * CELL_SIZE,
        selectedItem <= 4 and pathCellRotation(selectedValue) or 0,
        CELL_SIZE, CELL_SIZE)
    end

    for _, sh in ipairs(board.sheep) do drawSheep(sh) end

    -- Storehouse buttons
    -- First, indicator
    if selectedItem ~= -1 and not selectedDrag then
      love.graphics.setColor(0.6, 1, 0.7)
      love.graphics.rectangle('fill',
        BORDER_PAD,
        BORDER_PAD + (ITEM_SIZE + ITEM_SPACE) * (selectedItem - 1),
        ITEM_SIZE, ITEM_SIZE)
    end
    btnsStorehouse.draw()

    -- Text
    love.graphics.setColor(0, 0, 0)
    for i = 1, 5 do
      love.graphics.print(tostring(itemCount[i]),
        BORDER_PAD + ITEM_SIZE,
        BORDER_PAD + (ITEM_SIZE + ITEM_SPACE) * (i - 1)
      )
    end

    -- Progress indicator
    local xInd = STORE_WIDTH + 80
    local yInd = H - 32
    local scaleInd = (W - xInd - 20) / 30
    local pfxSum = 0
    for _, flock in ipairs(board.sheepFlocks) do
      local newSum = pfxSum + flock[2]
      for i = pfxSum, newSum - 1 do
        if flock[1] ~= -1 then
          love.graphics.setColor(flockColour(flock[1]))
          love.graphics.circle('fill', xInd + (i + 0.5) * scaleInd, yInd, 12)
        else
          love.graphics.setColor(0.9, 0.9, 0.9)
          love.graphics.setLineWidth(1)
          love.graphics.circle('line', xInd + (i + 0.5) * scaleInd, yInd, 12)
        end
      end
      pfxSum = newSum
    end
    love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
    love.graphics.setLineWidth(10)
    local xProg = xInd + math.min(boardRunProgress / Board.CELL_SUBDIV, pfxSum) * scaleInd
    love.graphics.line(xProg, yInd - 12, xProg, yInd + 12)

    tutAreas['prog_ind'] = {xInd, yInd - 12, pfxSum * scaleInd, 24}

    -- Tutorial, if any
    tut.draw()

    love.graphics.setColor(1, 1, 1)
  end

  return s
end
