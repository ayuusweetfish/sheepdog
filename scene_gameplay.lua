require 'utils'
local popcount4, ctz4, cellDog, cloneGrid = popcount4, ctz4, cellDog, cloneGrid

local Board = require 'board'
local buttons = require 'buttons'
local tutorial = require 'tutorial'

local sprites = require 'sprites'

local BORDER_PAD_X = 48
local BORDER_PAD_Y = 24
local ITEM_SIZE = 64
local ITEM_SPACE = 36
local BUTTON_SPACE = 24
local ITEM_SURROUND_SPACE = 10
local STORE_WIDTH = ITEM_SIZE + BORDER_PAD_X * 2

local sceneGameplay
sceneGameplay = function (levelIndex)
  local s = {}
  levelIndex = levelIndex or 4

  local board = Board.create(levelIndex)
  local itemCount = {}

  local cellSizeVert = H * 0.75 * (1 - math.exp(-0.4 * (board.h - 0.6))) / board.h
  local cellSizeHorz = (W - STORE_WIDTH) * 0.95 * (1 - math.exp(-0.4 * (board.w - 0.6))) / board.w
  local CELL_SIZE = math.min(cellSizeVert, cellSizeHorz)

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

  -- Animations on each cell, {row, column, type, remaining time, args...}
  local cellAnim = {}
  local ANIM_TYPE_PUT = 1
  local ANIM_TYPE_REMOVE = 2
  local ANIM_TYPE_ROTATE_PATH = 3
  local ANIM_TYPE_ROTATE_DOG = 4  -- args = isHalfCycle (true if 1/2 cycle, false if 1/4)
  local ANIM_DUR = 120
  local function easeProgRem(t)
    local x = t / ANIM_DUR
    return (math.exp(8 * x) - 1) / (math.exp(8) - 1)
  end
  local function easeProg(t)
    return 1 - easeProgRem(t)
  end

  -- Number of rotations on each cell
  -- For I-shaped paths, this increments by 2 every half-cycle
  -- For +-shaped paths, this increments by 1 every quarter-cycle
  -- Irrelevant for other shapes
  local rotationCount = {}
  for r = 1, board.h do
    rotationCount[r] = {}
    for c = 1, board.w do rotationCount[r][c] = 0 end
  end

  -- Sheep animations, {type, time, args...}
  -- type: question, exclamation, delight
  -- question/exclamation: args = {}
  -- delight: args = isHorizontal, offsetInCells, speedInCellsPerStep, movingRangeMultiplier
  local sheepAnim = {}
  local ANIM_TYPE_QUESTION = 1
  local ANIM_TYPE_EXCLAMATION = 2
  local ANIM_TYPE_DELIGHT = 3
  local ANIM_TYPE_QUESTION_FADE = 4

  local btnsStorehouse = buttons()
  local itemSprites = {
    'path_1', 'path_2', 'path_3', 'path_4', 'dog'
  }
  for i = 1, 5 do
    local sprite = love.graphics.newImage('res/' .. itemSprites[i] .. '.png')
    sprite:setFilter('nearest', 'nearest')
    btnsStorehouse.add(
      BORDER_PAD_X,
      BORDER_PAD_Y + (ITEM_SIZE + ITEM_SPACE) * (i - 1),
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
      BORDER_PAD_X,
      BORDER_PAD_Y + (ITEM_SIZE + ITEM_SPACE) * (i - 1),
      ITEM_SIZE, ITEM_SIZE
    }
  end

  -- Text objects for count display
  local textCount = {}

  local function resetItemCount()
    for i = 1, 5 do
      itemCount[i] = board.itemCount[i]
      btnsStorehouse.enable(i, itemCount[i] > 0)
    end
  end
  resetItemCount()

  local boardRunning = false
  local boardRunProgress = 0
  local boardDoubleSpeed = false

  -- Run button
  local runButton, resetButton
  local savedGrid = {}
  local savedItemCount = {}
  local savedRotationCount = {}
  local function updateButtonIcons()
    if boardRunning then
      btnsStorehouse.sprite(runButton, 'res/black-left-pointing-double-triangle_23ea.png')
      if boardDoubleSpeed then
        btnsStorehouse.sprite(resetButton, 'res/ice-cream_1f368.png')
      else
        btnsStorehouse.sprite(resetButton, 'res/black-right-pointing-triangle_25b6.png')
      end
    else
      btnsStorehouse.sprite(runButton, 'res/black-right-pointing-triangle_25b6.png')
      btnsStorehouse.sprite(resetButton, 'res/leftwards-arrow-with-hook_21a9.png')
    end
  end
  local function runButtonHandler()
    boardRunning = not boardRunning
    selectedItem = -1
    boardRunProgress = 0
    if boardRunning then
      boardDoubleSpeed = false
      -- Save board state
      cloneGrid(savedGrid, board.grid)
      cloneGrid(savedRotationCount, rotationCount)
      for i = 1, 5 do savedItemCount[i] = itemCount[i] end
      tut.emit('run')
    else
      board.reset()
      -- Restore board state
      cloneGrid(board.grid, savedGrid)
      cloneGrid(rotationCount, savedRotationCount)
      for i = 1, 5 do
        itemCount[i] = savedItemCount[i]
        btnsStorehouse.enable(i, itemCount[i] > 0)
      end
      -- Stop sheep animations
      for k in pairs(sheepAnim) do sheepAnim[k] = nil end
      tut.emit('stop')
    end
    updateButtonIcons()
  end
  runButton = btnsStorehouse.add(
    BORDER_PAD_X, H - BORDER_PAD_Y - ITEM_SIZE, ITEM_SIZE, ITEM_SIZE,
    'res/black-right-pointing-triangle_25b6.png',
    runButtonHandler
  )
  tutAreas['btn_run'] = {BORDER_PAD_X, H - BORDER_PAD_Y - ITEM_SIZE, ITEM_SIZE, ITEM_SIZE}

  -- Reset button
  resetButton = btnsStorehouse.add(
    BORDER_PAD_X, H - BORDER_PAD_Y - ITEM_SIZE * 2 - BUTTON_SPACE,
    ITEM_SIZE, ITEM_SIZE,
    'res/leftwards-arrow-with-hook_21a9.png',
    function ()
      if boardRunning then
        -- Double speed
        boardDoubleSpeed = not boardDoubleSpeed
      else
        -- Reset
        boardRunning = true
        runButtonHandler()  -- Trigger a board state reset
        board.reset()
        resetItemCount()
        for r = 1, board.h do
          for c = 1, board.w do rotationCount[r][c] = 0 end
        end
      end
      updateButtonIcons()
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
      -- Moving path
      -- Is any sheep going here?
      local sheepComing = false
      for _, sh in ipairs(board.sheep) do
        if sh.to ~= nil and sh.to[1] == pinpointRow and sh.to[2] == pinpointCol then
          sheepComing = true
          break
        end
      end
      if sheepComing then
        -- Cancel
        pinpointingItem = false
        selectedItem = -1
        return
      end
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
      if x >= STORE_WIDTH and
          btnsStorehouse.selected() >= 1 and
          btnsStorehouse.selected() <= 5
      then
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
          rotationCount[pinpointRow][pinpointCol] = 0
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
        cellAnim[#cellAnim + 1] = {
          holdRow, holdCol, ANIM_TYPE_ROTATE_DOG, ANIM_DUR,
          (dog + 2) % 4 == newDog % 4
        }
        tut.emit('rotate_dog ' .. holdRow .. ' ' .. holdCol)
      else
        local newSides = (sides * 2) % 16 + (bit.arshift(cell, 3) % 2)
        cell = cell + (newSides - sides)
        cellAnim[#cellAnim + 1] = {holdRow, holdCol, ANIM_TYPE_ROTATE_PATH, ANIM_DUR}
        tut.emit('rotate_path ' .. holdRow .. ' ' .. holdCol)
        if newSides == 10 then
          rotationCount[holdRow][holdCol] = (rotationCount[holdRow][holdCol] + 2) % 4
        elseif newSides == 15 then
          rotationCount[holdRow][holdCol] = (rotationCount[holdRow][holdCol] + 1) % 4
        end
      end
      board.grid[holdRow][holdCol] = cell
    end
  end

  -- Time after the finishing criterion has been met
  local gameFinishTimer = -1

  s.update = function ()
    btnsStorehouse.update()
    if holdTime >= 0 then
      holdTime = holdTime + 1
      -- Convert to a pinpoint if held for 0.5 second
      if holdTime >= 120 then
        convertHoldToPinpoint()
      end
    end
    -- Update cell animations
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
      if boardDoubleSpeed then
        board.update()
        boardRunProgress = boardRunProgress + 1
      end
      -- Update sheep animations
      for _, sh in ipairs(board.sheep) do
        local a = sheepAnim[sh]
        local curAnim = (a == nil and 0 or a[1])
        if sh.sheepfold and curAnim ~= ANIM_TYPE_DELIGHT then
          sheepAnim[sh] = {
            ANIM_TYPE_DELIGHT, 0,
            (bit.band(board.grid[sh.to[1]][sh.to[2]], 4) ~= 0),
            0, math.random() < 0.5 and -1e-6 or 1e-6,
            1.05 + (math.random() - 0.5) * 0.2
          }
        elseif sh.wrongSheepfold and curAnim ~= ANIM_TYPE_EXCLAMATION then
          sheepAnim[sh] = {ANIM_TYPE_EXCLAMATION, 0}
        elseif sh.confused and curAnim ~= ANIM_TYPE_QUESTION then
          sheepAnim[sh] = {ANIM_TYPE_QUESTION, 0}
        end
        if curAnim == ANIM_TYPE_QUESTION and not sh.confused then
          sheepAnim[sh] = {ANIM_TYPE_QUESTION_FADE, 0}
        end
      end
      for _, a in pairs(sheepAnim) do
        if a[1] == ANIM_TYPE_DELIGHT then
          local v = math.abs(a[5])
          if v < 0.4 / 240 then v = v + (math.random() + 0.1) * (0.03 / 240)
          else v = v + (math.random() * 2 - 1) * (0.01 / 240) end
          if v > 0.7 / 240 then v = 1.1 / 240 - v end
          if a[5] < 0 then v = -v end
          local x = a[4] + v
          if x > 1 then x, v = 2 - x, -v
          elseif x < -1 then x, v = -2 - x, -v end
          a[4] = x
          a[5] = v
        end
        a[2] = a[2] + 1
      end
    end
    -- Update tutorial
    tut.update()
    -- Check whether all sheep are in correct sheepfolds
    if gameFinishTimer == -1 then
      local sheepNotArrived = false
      for _, sh in ipairs(board.sheep) do
        if not sh.sheepfold then
          sheepNotArrived = true
          break
        end
      end
      if not sheepNotArrived then
        -- Game finish
        gameFinishTimer = 0
      end
    else
      gameFinishTimer = gameFinishTimer + 1
      if gameFinishTimer == 480 then
        _G['replaceScene'](sceneGameplay(levelIndex + 1))
      end
    end
  end

  local function flockColour(n)
    if n == 1 then return 1.0, 0.7, 0.5
    elseif n == 2 then return 1.0, 0.5, 0.9
    else return 0.9, 0.9, 0.9
    end
  end

  local DIR_STRING = {[0] = 'back', [1] = 'right', [2] = 'front', [3] = 'left'}

  local function drawSheep(index, sh)
    local r, c
    if sh.eta == 0 then
      local prog = sh.prog / Board.CELL_SUBDIV
      r = sh.from[1] * (1 - prog) + sh.to[1] * prog
      c = sh.from[2] * (1 - prog) + sh.to[2] * prog
    else
      r = board.entryRow
      c = -sh.eta / Board.CELL_SUBDIV
    end
    local xCen = xStart + (c - 0.5) * CELL_SIZE
    local yCen = yStart + (r - 0.5) * CELL_SIZE
    -- Animation
    local spriteDir = sh.dir or 1
    local icon = nil
    local xIcon, yIcon, wIcon, hIcon, opacity
    local a = sheepAnim[sh]
    if a ~= nil then
      if a[1] == ANIM_TYPE_DELIGHT then
        local offs = a[4]
        -- Smoothing
        offs = a[6] * math.sin(offs * math.pi / 2)
        if a[3] then  -- Horizontal?
          xCen = xCen + offs * CELL_SIZE
          spriteDir = (a[5] > 0 and 1 or 3)
        else
          yCen = yCen + offs * CELL_SIZE
          spriteDir = (a[5] > 0 and 2 or 0)
        end
      end
      if a[1] == ANIM_TYPE_DELIGHT or
         a[1] == ANIM_TYPE_QUESTION or
         a[1] == ANIM_TYPE_EXCLAMATION
      then
        local x = a[2] / 180
        local prog = 1
        if x < 1 then
          prog = math.exp(-10 * x) * math.sin((2 * x - 0.2) * math.pi / 0.4) + 1
        end
        if a[1] == ANIM_TYPE_DELIGHT then
          icon = (boardRunProgress % 120 < 60 and 'flowers_1' or 'flowers_2')
          xIcon = xCen - CELL_SIZE * 0.7
          yIcon = yCen - CELL_SIZE * 1.0
          opacity = math.min(1, a[2] / 40)
          if a[2] >= 300 then
            if a[2] < 340 then opacity = (340 - a[2]) / 40
            else icon = nil end
          end
          wIcon = CELL_SIZE * 1.4
          hIcon = CELL_SIZE * 0.7
        else
          icon = (a[1] == ANIM_TYPE_QUESTION and 'question_mark' or 'exclamation_mark')
          xIcon = xCen - CELL_SIZE * 0.1
          yIcon = yCen - prog * CELL_SIZE * 1.4
          wIcon = CELL_SIZE * 0.9
          hIcon = CELL_SIZE * 0.9
          opacity = math.min(1, prog)
        end
      elseif a[1] == ANIM_TYPE_QUESTION_FADE then
        icon = 'question_mark'
        prog = math.min(1, a[2] / 40)
        xIcon = xCen - CELL_SIZE * 0.1
        yIcon = yCen - CELL_SIZE * 1.4
        wIcon = CELL_SIZE * 0.9
        hIcon = CELL_SIZE * 0.9
        opacity = 1 - prog
      end
    end
    -- Draw the sheep
    love.graphics.setColor(1, 1, 1)
    local rate = math.sin((boardRunProgress + index * 123) / 50)
    local w = 1 + rate * 0.01
    local h = 1 - rate * 0.02
    w = CELL_SIZE * (spriteDir % 2 == 0 and 0.95 or 1.125) * w
    h = CELL_SIZE * 0.9 * h
    sprites.draw('sheep_' .. sh.flock .. '_' .. DIR_STRING[spriteDir],
      xCen - w / 2, yCen + CELL_SIZE * 0.05 - h, 0, w, h)
    -- Draw the icon if there is one
    if icon ~= nil then
      love.graphics.setColor(1, 1, 1, opacity)
      sprites.draw(icon, xIcon, yIcon, 0, wIcon, hIcon)
    end
  end

  s.draw = function ()
    -- Background
    local backgroundScale = 0.4
    local xBackground
    xBackground = W - 450 * backgroundScale
    sprites.draw('background_upperright',
      xBackground, 0,
      0, 450 * backgroundScale, 250 * backgroundScale)
    while xBackground > 0 do
      xBackground = xBackground - 540 * backgroundScale
      sprites.draw('background_upperleft',
        xBackground, 0,
        0, 540 * backgroundScale, 250 * backgroundScale)
    end
    local backgroundLowerWidth = 1000 * backgroundScale
    local backgroundLowerHeight = 750 * backgroundScale
    for x = 1, math.ceil(W / backgroundLowerWidth) do
      for y = 1, math.ceil(H / backgroundLowerHeight) do
        sprites.draw('background_lower',
          (x - 1) * backgroundLowerWidth,
          (y - 1) * backgroundLowerHeight + 250 * backgroundScale,
          0, backgroundLowerWidth, backgroundLowerHeight)
      end
    end
    -- Border
    local pad = CELL_SIZE * 0.1
    love.graphics.setColor(0.1, 0.3, 0.1, 0.6)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle('line',
      xStart - pad, yStart - pad, CELL_SIZE * board.w + pad * 2, CELL_SIZE * board.h + pad * 2)
    love.graphics.setColor(1, 1, 1)
    -- Grid
    for r = 1, board.h do
      for c = 1, board.w do
        local xCell = xStart + (c - 1) * CELL_SIZE
        local yCell = yStart + (r - 1) * CELL_SIZE
        if board.grid[r][c] == Board.OBSTACLE then
          sprites.draw('bush_1',
            xCell - CELL_SIZE * 0.1,
            yCell - CELL_SIZE * 0.2,
            0, CELL_SIZE * 1.2, CELL_SIZE * 1.2)
        end
        if board.grid[r][c] >= Board.PATH then
          local pts = {{0.5, 0}, {1, 0.5}, {0.5, 1}, {0, 0.5}}
          -- Draw path
          local ty = pathCellType(board.grid[r][c])
          if ty == 0 then
            -- Sheepfolds with one inlet
            --[[
            love.graphics.setColor(1, 0.8, 0.6)
            love.graphics.setLineWidth(CELL_SIZE / 4)
            local dir = ctz4(board.grid[r][c] % 16)
            love.graphics.line(
              xCell + CELL_SIZE * 0.5, yCell + CELL_SIZE * 0.5,
              xCell + CELL_SIZE * pts[dir + 1][1],
              yCell + CELL_SIZE * pts[dir + 1][2])
            ]]
          else
            local rotation = pathCellRotation(board.grid[r][c])
            for _, anim in ipairs(cellAnim) do
              if anim[1] == r and anim[2] == c and anim[3] == ANIM_TYPE_ROTATE_PATH then
                rotation = rotation - easeProgRem(anim[4]) * math.pi / 2
              end
            end
            rotation = rotation + rotationCount[r][c] * math.pi / 2
            love.graphics.setColor(1, 1, 1)
            sprites.draw('path_' .. ty, xCell, yCell, rotation, CELL_SIZE, CELL_SIZE)
            -- Entry?
            if bit.band(board.grid[r][c], Board.ENTRY) ~= 0 then
              sprites.draw('start_mark',
                xCell + CELL_SIZE * 0.2, yCell - CELL_SIZE * 0.6,
                0, CELL_SIZE * 0.75, CELL_SIZE * 0.9)
            end
          end
          -- Draw dog
          local dog = cellDog(board.grid[r][c])
          if dog ~= 0 then
            love.graphics.setColor(1, 1, 1)
            local rotation = (dog - 1) * math.pi / 2
            for _, anim in ipairs(cellAnim) do
              if anim[1] == r and anim[2] == c and anim[3] == ANIM_TYPE_ROTATE_DOG then
                rotation = rotation -
                  easeProgRem(anim[4]) * math.pi * (anim[5] and 1.0 or 0.5)
              end
            end
            sprites.draw('footprints',
              xCell + CELL_SIZE * 0.4, yCell,
              rotation,
              CELL_SIZE * 0.2, CELL_SIZE * 0.5,
              0.5, 1
            )
          end
        end
      end
    end
    -- Entry leading cells
    local xEntry = xStart
    local yEntry = yStart + (board.entryRow - 1) * CELL_SIZE
    for i = 1, 10 do
      sprites.draw('path_1',
        xEntry - i * CELL_SIZE, yEntry, math.pi / 2, CELL_SIZE, CELL_SIZE)
    end
    -- Dogs on the grid
    for r = 1, board.h do
      for c = 1, board.w do
        if cellDog(board.grid[r][c]) ~= 0 then
          sprites.draw('dog',
            xStart + (c - 1) * CELL_SIZE + CELL_SIZE * 0.6,
            yStart + (r - 1) * CELL_SIZE - CELL_SIZE * 0.3,
            0, CELL_SIZE * 0.7, CELL_SIZE * 0.7)
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
            love.graphics.setColor(1, 1, 0, 0.4)
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
        love.graphics.setColor(0.8, 0.8, 0.4, 0.4)
        alpha = 0.6
      else
        -- Item will be restored to original position if dropped here
        love.graphics.setColor(0.9, 0.5, 0.4, 0.4)
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

    -- Sheep in the sheepfolds
    for i, sh in ipairs(board.sheep) do
      if sh.sheepfold then drawSheep(i, sh) end
    end
    -- Sheepfolds
    love.graphics.setColor(1, 1, 1)
    for r = 1, board.h do
      for c = 1, board.w do
        local ty = math.floor(board.grid[r][c] / Board.PATH)
        if ty >= Board.TYPE_SHEEPFOLD and ty <= Board.TYPE_SHEEPFOLD_MAX then
          -- Draw sheepfold
          local index = (ty - Board.TYPE_SHEEPFOLD + 1)
          sprites.draw('fence_' .. index,
            xStart + (c - 2) * CELL_SIZE,
            yStart + (r - 1) * CELL_SIZE,
            (bit.band(board.grid[r][c], 4) ~= 0 and 0 or math.pi / 2),
            CELL_SIZE * 3, CELL_SIZE
          )
        end
      end
    end
    -- Sheep not in the sheepfolds
    for i, sh in ipairs(board.sheep) do
      if not sh.sheepfold then drawSheep(i, sh) end
    end

    -- Storehouse buttons
    -- First, background
    love.graphics.setColor(0.45, 0.25, 0.1, 0.75)
    -- love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
    love.graphics.rectangle('fill', 0, 0, STORE_WIDTH, H)
    -- Then, indicator
    for i = 1, 5 do
      if selectedItem == i and not selectedDrag then
        love.graphics.setColor(0.6, 1, 0.7)
      else
        love.graphics.setColor(0.9, 0.9, 0.9)
      end
      love.graphics.rectangle('fill',
        BORDER_PAD_X - ITEM_SURROUND_SPACE,
        BORDER_PAD_Y + (ITEM_SIZE + ITEM_SPACE) * (i - 1) - ITEM_SURROUND_SPACE,
        ITEM_SIZE + ITEM_SURROUND_SPACE * 2,
        ITEM_SIZE + ITEM_SURROUND_SPACE * 2)
    end

    -- Buttons themselves
    btnsStorehouse.draw()

    -- Text
    for i = 1, 5 do
      local text = textCount[itemCount[i]]
      if text == nil then
        text = love.graphics.newText(_G['font_Mali'], tostring(itemCount[i]))
        textCount[itemCount[i]] = text
      end
      local textSize = 24
      local xText = BORDER_PAD_X
        + ITEM_SIZE + ITEM_SURROUND_SPACE - textSize
      local yText = BORDER_PAD_Y + (ITEM_SIZE + ITEM_SPACE) * (i - 1)
        + ITEM_SIZE + ITEM_SURROUND_SPACE - textSize
      love.graphics.setColor(0.2, 0.2, 0.2, 0.75)
      love.graphics.rectangle('fill', xText, yText, textSize, textSize)
      local textScale = 0.75
      love.graphics.setColor(0.95, 0.95, 0.95)
      love.graphics.draw(text,
        xText + (textSize - text:getWidth() * textScale) / 2, yText - 2,
        0, textScale, textScale
      )
    end

    -- Frames around buttons
    for i = 1, 5 do
      love.graphics.setColor(0.5, 0.3, 0.1)
      love.graphics.setLineWidth(3)
      love.graphics.rectangle('line',
        BORDER_PAD_X - ITEM_SURROUND_SPACE,
        BORDER_PAD_Y + (ITEM_SIZE + ITEM_SPACE) * (i - 1) - ITEM_SURROUND_SPACE,
        ITEM_SIZE + ITEM_SURROUND_SPACE * 2,
        ITEM_SIZE + ITEM_SURROUND_SPACE * 2)
    end

    -- Progress indicator
    local xInd = STORE_WIDTH + 48
    local yInd = H - 48
    local scaleInd = (W - xInd - 20) / 20
    local hInd = 48
    local pfxSum = 0
    for _, flock in ipairs(board.sheepFlocks) do
      local newSum = pfxSum + flock[2]
      for i = pfxSum, newSum - 1 do
        if flock[1] ~= -1 then
          love.graphics.setColor(1, 1, 1)
          sprites.draw('sheep_' .. flock[1] .. '_front',
            xInd + (i + 0.5) * scaleInd - hInd / 2,
            yInd - hInd / 2, 0, hInd, hInd)
        else
          love.graphics.setColor(0, 0, 0, 0.3)
          love.graphics.setLineWidth(1)
          love.graphics.circle('line', xInd + (i + 0.5) * scaleInd, yInd, hInd * 0.9 / 2)
        end
      end
      pfxSum = newSum
    end
    love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
    love.graphics.setLineWidth(10)
    local xProg = xInd + math.min(boardRunProgress / Board.CELL_SUBDIV, pfxSum) * scaleInd
    love.graphics.line(xProg, yInd - hInd / 2, xProg, yInd + hInd / 2)

    tutAreas['prog_ind'] = {xInd, yInd - hInd / 2, pfxSum * scaleInd, hInd}

    -- Tutorial, if any
    tut.draw()

    love.graphics.setColor(1, 1, 1)
  end

  return s
end

return sceneGameplay
