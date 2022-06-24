local chest = peripheral.find("minecraft:chest")
local modem = peripheral.find("modem")
local turtleName = modem.getNameLocal()

local args = {...}
local project = args[1]
local bottomLayer = args[2]
local topLayer = args[3]
local building = {}
local layers = 1

function calc(layer, ini) --calculates required blocks
    local counts = {[0] = 0, [1] = 0, [2] = 0, [4] = 0, [8] = 0,
                    [16] = 0, [32] = 0, [64] = 0, [128] = 0,
                    [256] = 0, [512] = 0, [1024] = 0, [2048] = 0,
                    [4096] = 0, [8192] = 0, [16384] = 0, [32768] = 0}
    local res = {}
    for _, row in pairs(layer) do
        for _, num in ipairs(row) do
            counts[num] = counts[num] + 1
        end
    end
    for key, value in pairs(ini) do
        res[value] = counts[key]
    end
    return res
end

function gather(blocks)
    local emptySlots = 16
    while true do
        for slot, item in pairs(chest.list()) do
            if item ~= nil and blocks[item.name] ~= nil and blocks[item.name] ~= 0 then
                local transfered = chest.pushItems(turtleName, slot, blocks[item.name])
                blocks[item.name] = blocks[item.name] - transfered
                emptySlots = emptySlots - 1
            end
            if emptySlots == 0 then
                break
            end
        end
        if emptySlots ~= 16 then
            break
        end
        print("I need some materials:")
        for name, amount in pairs(blocks) do
            if amount ~= 0 then
                print(name.." "..amount)
            end
        end
        print("Press any key when added materials.")
        os.pullEvent("key")
        print("Continuing...")
    end
    return blocks
end

function home(block, row, curLevel)
    turtle.turnRight()
    turtle.turnRight()
    for i = 1, block, 1 do
        turtle.forward()
    end
    turtle.turnRight()
    for i = 1, row - 1, 1 do
        turtle.forward()
    end
    turtle.turnLeft()
    for i = 1, curLevel - 1, 1 do
        turtle.down()
    end
    turtle.turnRight()
    turtle.turnRight()
end

function spot(block, row, curLevel)
    for i = 1, curLevel - 1, 1 do
        turtle.up()
    end
    turtle.turnRight()
    for i = 1, row - 1, 1 do
        turtle.forward()
    end
    turtle.turnLeft()
    for i = 1, block, 1 do
        turtle.forward()
    end
end

function blocksLeft(blocks)
    for _, amount in pairs(blocks) do
        if amount ~= 0 then
            return true
        end
    end
    return false
end

function selectBlock(name)
    for i = 1, 16, 1 do
        local item = turtle.getItemDetail(i)
        if item ~= nil and item.name == name then
            turtle.select(i)
            return true
        end
    end
    return false
end

function empty()
    for i = 1, 16, 1 do
        if turtle.getItemDetail(i) ~= nil then
            return false
        end
    end
    return true
end

function refuel(layer)
    local fuelNeeded = 0
    for _, row in pairs(layer) do
        for _, _ in pairs(row) do
            fuelNeeded = fuelNeeded + 1
        end
    end
    fuelNeeded = fuelNeeded * 2.1 + 200
    if turtle.getFuelLevel() < fuelNeeded then
        while true do
            print("Add some fuel ("..(fuelNeeded - turtle.getFuelLevel()).." left) and perss any button.")
            os.pullEvent("key")
            for i = 1, 16, 1 do
                turtle.select(i)
                turtle.refuel()
            end
            if fuelNeeded < turtle.getFuelLevel() then
                break
            end
        end
    end
end

function build(layer, ini, curLevel)
    local blocks = calc(layer, ini)
    refuel(layer)
    while true do
        blocks = gather(blocks)
        for i = 1, curLevel - 1, 1 do
            turtle.up()
        end
        local colLen = 0
        for rowN, row in pairs(layer) do
            local rowLen = 0
            for blockN, block in pairs(row) do
                turtle.forward()
                if empty() then
                    home(blockN, rowN, curLevel)
                    blocks = gather(blocks)
                    spot(blockN, rowN, curLevel)
                end
                if selectBlock(ini[block]) then
                    turtle.placeDown()
                end
                if blockN > rowLen then
                    rowLen = blockN
                end
            end
            turtle.turnRight()
            turtle.turnRight()
            for i = 1, rowLen, 1 do
                turtle.forward()
            end
            if rowN > colLen then
                colLen = rowN
            end
            turtle.turnLeft()
            turtle.forward()
            turtle.turnLeft()
        end
        home(0, colLen + 1, curLevel)
        if not blocksLeft(blocks) then
            break
        end
    end
end


if  project == nil then
    print("Bad argument #1. String project name required.")
    return
end
if bottomLayer ~= nil then
    bottomLayer = tonumber(bottomLayer)
    if bottomLayer < 1 then
        print("Bad argument #2. Number bottom level is wrong.")
    end
end
if topLayer ~= nil then
    topLayer = tonumber(topLayer)
    if topLayer < bottomLayer then
        print("Bad argument #3. Number top level is wrong.")
    end
end

while true do
    local image = project.."/"..project.."_"..layers..".img"
    if fs.exists(image) then
        table.insert(building, paintutils.loadImage(image))
        layers = layers + 1
    else
        layers = layers - 1
        break
    end
end

if layers == 0 then
    print("There are no layer files.")
    return
end
if not fs.exists(project.."/"..project..".ini") then
    print("There is no ini file.")
    return
end

local blocks = io.lines(project.."/"..project..".ini")
if bottomLayer == nil then
    bottomLayer = 1
end
if topLayer == nil then
    topLayer = layers
end

for i = 1, bottomLayer - 1, 1 do
    blocks()
end

for layer = bottomLayer, topLayer do
    local ini = blocks()
    if ini == nil then
        break
    end
    build(building[layer], textutils.unserialise(ini), layer)
    for slot = 1, 16, 1 do
        chest.pullItems(turtleName, slot)
    end
end
