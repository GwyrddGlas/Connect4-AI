local darkMode = true
local BackgroundAudioVolume = 0.01 --set to 0 for off

local BackgroundAudio 
local spriteRed, spriteYellow
local spriteWinner, spriteLoser

local function v4(r,g,b,a)
    return {r=r, g=g, b=b, a=a}
end

local function getGridCell(x, y)
    local width = love.graphics.getWidth() / 7
    local height = love.graphics.getHeight() / 7
    local cellX = math.floor(x / width) + 1
    local cellY = math.floor(y / height) + 1
    return cellX, cellY
end

local countersRed = {}
local countersYellow = {}
local currentPlayer = "Y"

local function createYellowCounterInCell(cellX, cellY)
    -- Convert grid cell to pixel position
    local width = love.graphics.getWidth() / 7
    local height = love.graphics.getHeight() / 7
    local posX = (cellX - 1) * width
    local posY = (cellY - 1) * height
    -- Add the counter to the list
    table.insert(countersYellow, {x = posX, y = posY})
    currentPlayer = "R"
end

local function createRedCounterInCell(cellX, cellY)
    local width = love.graphics.getWidth() / 7
    local height = love.graphics.getHeight() / 7
    local posX = (cellX - 1) * width
    local posY = (cellY - 1) * height
    table.insert(countersRed, {x = posX, y = posY})
    currentPlayer = "Y"
end

--reusing functions from tictactoe
local function containsSymbol(array, cellX, cellY)
    for _, pos in ipairs(array) do
        local posX, posY = getGridCell(pos.x, pos.y)  -- Convert back to grid coordinates
        if posX == cellX and posY == cellY then
            return true
        end
    end
    return false
end

local function isCellEmpty(cellX, cellY)
    return not containsSymbol(countersRed, cellX, cellY) and not containsSymbol(countersYellow, cellX, cellY)
end

local function isBoardFull()
    for x = 1, 7 do
        if isCellEmpty(x, 1) then
            return false
        end
    end
    return true
end

local function drawMap()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local backgroundColour = darkMode and v4(30/255, 40/255, 55/255, 1) or v4(1, 1, 1, 1) 
    love.graphics.setColor(backgroundColour.r, backgroundColour.g, backgroundColour.b, backgroundColour.a)  -- Background color
    
    love.graphics.rectangle("fill", 0, 0, width, height)
    love.graphics.setColor(0, 0, 0, 1)  -- Black color for the grid
    -- Draw vertical grid lines
    for i = 1, 6 do
        local xPos = i * width / 7
        love.graphics.rectangle("fill", xPos - 5, 0, 5, height)
    end
    -- Draw horizontal grid lines
    for i = 1, 6 do
        local yPos = i * height / 7
        love.graphics.rectangle("fill", 0, yPos - 5, width, 5)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

local function checkHorizontal(symbolArray, y)
    for x = 1, 3 do
        if not containsSymbol(symbolArray, x, y) then
            return false
        end
    end
    return true
end

local function checkVertical(symbolArray, x)
    for y = 1, 3 do
        if not containsSymbol(symbolArray, x, y) then
            return false
        end
    end
    return true
end

local function checkHorizontal(symbolArray)
    for y = 1, 7 do
        for x = 1, 4 do
            if containsSymbol(symbolArray, x, y) and containsSymbol(symbolArray, x+1, y) and 
            containsSymbol(symbolArray, x+2, y) and containsSymbol(symbolArray, x+3, y) then
                return true
            end
        end
    end
    return false
end

local function checkVertical(symbolArray)
    for x = 1, 7 do
        for y = 1, 4 do
            if containsSymbol(symbolArray, x, y) and containsSymbol(symbolArray, x, y+1) and 
            containsSymbol(symbolArray, x, y+2) and containsSymbol(symbolArray, x, y+3) then
                return true
            end
        end
    end
    return false
end

local function checkDiagonal(symbolArray)
    -- Check diagonal from top-left to bottom-right
    for x = 1, 4 do
        for y = 1, 4 do
            if containsSymbol(symbolArray, x, y) and containsSymbol(symbolArray, x+1, y+1) and
            containsSymbol(symbolArray, x+2, y+2) and containsSymbol(symbolArray, x+3, y+3) then
                return true
            end
        end
    end

    -- Check diagonal from top-right to bottom-left
    for x = 7, 4, -1 do
        for y = 1, 4 do
            if containsSymbol(symbolArray, x, y) and containsSymbol(symbolArray, x-1, y+1) and
            containsSymbol(symbolArray, x-2, y+2) and containsSymbol(symbolArray, x-3, y+3) then
                return true
            end
        end
    end
    return false
end

local function checkForWin(symbol)
    local symbolArray = (symbol == 'Y') and countersYellow or countersRed
    return checkHorizontal(symbolArray) or checkVertical(symbolArray) or checkDiagonal(symbolArray)
end

local isMoveMade = false
local isGameOver = false

local winner = false
local loser = false 

local aiDelay = 1 
local aiDelayTimer = 0

local function aiFindWinningMove(symbolArray)
    for x = 1, 7 do
        for y = 1, 6 do
            if isCellEmpty(x, y) then
                local tempCounters = {}
                for _, v in ipairs(symbolArray) do
                    table.insert(tempCounters, {x = v.x, y = v.y})
                end

                table.insert(tempCounters, {x = (x - 1) * (love.graphics.getWidth() / 7), y = (y - 1) * (love.graphics.getHeight() / 7)})
                
                local win = checkForWin('Y', tempCounters)

                if win then
                    return x, y
                end
            end
        end
    end
    return nil 
end


local function aiMovement()
    local winX, winY = aiFindWinningMove(countersYellow)
    if winX then
        createYellowCounterInCell(winX, winY)
        isMoveMade = true
        return
    end

    local blockX, blockY = aiFindWinningMove(countersRed)
    if blockX then
        createYellowCounterInCell(blockX, blockY)
        isMoveMade = true
        return
    end

    local availableColumns = {}

    for x = 1, 7 do
        for y = 7, 1, -1 do  
            if isCellEmpty(x, y) then
                table.insert(availableColumns, {x = x, y = y})
                break
            end
        end
    end

    if #availableColumns > 0 then
        local choice = availableColumns[math.random(#availableColumns)]
        createYellowCounterInCell(choice.x, choice.y) 
        isMoveMade = true
    end
end


local function resetGame()
    countersRed = {}
    countersYellow = {}

    currentPlayer = "Y"
    isGameOver = false
    winner = false
    loser = false

    aiDelayTimer = 0
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 and not isGameOver then
        local cellX, cellY = getGridCell(x, y)
        for row = 7, 1, -1 do
            if isCellEmpty(cellX, row) then
                if currentPlayer == "Y" then
                    createYellowCounterInCell(cellX, row)
                    --print("Placed yellow counter at column " .. cellX .. ", row " .. row)
                    isMoveMade = true
                elseif currentPlayer == "R" then
                    createRedCounterInCell(cellX, row)
                    --print("Placed red counter at column " .. cellX .. ", row " .. row)
                    isMoveMade = true
                end
                break
            end
        end
    end
end

function love.keypressed(key)
    if key == "r" then --R to reset
        resetGame()
    end
end

function love.load()
    spriteRed = love.graphics.newImage("sprites/red.png")
    spriteYellow = love.graphics.newImage("sprites/yellow.png")
    spriteLoser = love.graphics.newImage("sprites/loser.png")
    spriteWinner = love.graphics.newImage("sprites/winner.png")
    BackgroundAudio = love.audio.newSource("audio/Chill Pulse-Talk.mp3", "static")
    BackgroundAudio:play()
    BackgroundAudio:setLooping(true)
end

function love.update(dt)
    if not isGameOver then
        if currentPlayer == 'Y' and aiDelayTimer <= 0 then
            aiMovement() 
            currentPlayer = 'R'
            aiDelayTimer = aiDelay  
        elseif currentPlayer == 'Y' then
            aiDelayTimer = aiDelayTimer - dt
        end
            if isMoveMade then
                if currentPlayer == 'R' and checkForWin('Y') then
                    loser = true
                    isGameOver = true
                elseif currentPlayer == 'Y' and checkForWin('R') then
                    winner = true
                    isGameOver = true
                elseif isBoardFull() then --end game if board is full
                    isGameOver = true
                end
                isMoveMade = false
            end
        if BackgroundAudioVolume > 0 then
            BackgroundAudio:setVolume(BackgroundAudioVolume)
        end
    end
end

function love.draw()
    drawMap()

    local cellWidth = love.graphics.getWidth() / 7
    local cellHeight = love.graphics.getHeight() / 7

    for _, v in ipairs(countersRed) do
        local scaleWidth = cellWidth / spriteRed:getWidth()
        local scaleHeight = cellHeight / spriteRed:getHeight()
        love.graphics.draw(spriteRed, v.x, v.y, 0, scaleWidth, scaleHeight)
    end

    for _, v in ipairs(countersYellow) do
        local scaleWidth = cellWidth / spriteRed:getWidth()
        local scaleHeight = cellHeight / spriteRed:getHeight()
        love.graphics.draw(spriteYellow, v.x, v.y, 0, scaleWidth, scaleHeight)
    end

    local screenWidth = love.graphics.getWidth() / 2
    local screenHeight = love.graphics.getHeight() / 2

    if winner and spriteWinner ~= nil then
        love.graphics.draw(spriteWinner, screenWidth/3, screenHeight/2)
    end
    
    if loser and spriteLoser ~= nil then
        love.graphics.draw(spriteLoser, screenWidth/3, screenHeight/2)
    end
end