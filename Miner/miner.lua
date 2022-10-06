local args = {...}
local FORWARD = 1
local BACK    = 2
local UP      = 3
local DOWN    = 4
local LEFT    = 5
local RIGHT   = 6
local MAX_SLOTS = 14
local BUCKET_SLOT = 15
local CHEST_SLOT = 16
local listOres = {"minecraft:coal_ore", "minecraft:deepslate_coal_ore",
                  "minecraft:iron_ore", "minecraft:deepslate_iron_ore",
                  "minecraft:copper_ore", "minecraft:deepslate_copper_ore",
                  "minecraft:gold_ore", "minecraft:deepslate_gold_ore",
                  "minecraft:redstone_ore", "minecraft:deepslate_redstone_ore",
                  "minecraft:emerald_ore", "minecraft:deepslate_emerald_ore",
                  "minecraft:lapis_ore", "minecraft:deepslate_lapis_ore",
                  "minecraft:diamond_ore", "minecraft:deepslate_diamond_ore",
                  "minecraft:nether_gold_ore", "minecraft:nether_quartz_ore",
                  "minecraft:ancient_debris"}



if (fs.exists("eldest.log")) then fs.delete("eldest.log") end
if (fs.exists("old.log")) then fs.move("old.log", "eldest.log") end
if (fs.exists("new.log")) then fs.move("new.log", "old.log") end
local log = fs.open("new.log", "a")


function newLogEntry(text)
    log.writeLine("Day "..os.day().." - "..textutils.formatTime(os.time(), true)..": "..text)
    log.flush()
end

function drink(dir)
    local exist, block
    if dir == UP then
        exist, block = turtle.inspectUp()
    elseif dir == DOWN then
        exist, block = turtle.inspectDown()
    else
        exist, block = turtle.inspect()
    end
    if exist == false or block.name ~= "minecraft:lava" then
        return
    end
    turtle.select(BUCKET_SLOT)
    turtle.equipRight()
    if dir == UP then
        turtle.placeUp()
    elseif dir == DOWN then
        turtle.placeDown()
    else
        turtle.place()
    end
    turtle.equipRight()
    turtle.refuel()
    turtle.select(1)
end


function go(dir)
    if dir == BACK then
        turtle.turnLeft()
        turtle.turnLeft()
    end
    if dir == LEFT then turtle.turnLeft() end
    if dir == RIGHT then turtle.turnRight() end

    for i=1, 16 do
        if dir == UP then
            drink(UP)
            turtle.digUp()
            if turtle.up() == true then
                return true
            end
        elseif dir == DOWN then
            drink(DOWN)
            turtle.digDown()
            if turtle.down() == true then
                return true
            end
        else
            drink(FORWARD)
            turtle.dig()
            if turtle.forward() == true then
                return true
            end
        end
    end
    return false
end


function inList(exist, block)
    if exist == false then return false end

    for _, name in ipairs(listOres) do
        if name == block.name then
            return true
        end
    end
    return false
end


function mine()
    local depth = 0
    while go(DOWN) do
        newLogEntry("Level "..depth..".")
        for i=1, 4 do
            drink(FORWARD)
            if inList(turtle.inspect()) then
                turtle.dig()
            end
            turtle.turnLeft()
        end
        depth = depth + 1
    end
    newLogEntry("Going up.")
    for i=1, depth do
        go(UP)
    end
end


function eat()
    if turtle.getFuelLevel() > 5000 then
        newLogEntry("Fed up with coal.")
        return
    end

    for i=1, MAX_SLOTS do
        local detail = turtle.getItemDetail(i)
        if detail ~= nil and detail.name == "minecraft:coal" then
            newLogEntry("Eating coal from "..i.." slot.")
            turtle.select(i)
            turtle.refuel()
        end
    end
    turtle.select(1)
end


function drop()
    turtle.select(CHEST_SLOT)
    turtle.placeDown()
    for i=1, MAX_SLOTS do
        turtle.select(i)
        turtle.dropDown()
    end
    turtle.select(CHEST_SLOT)
    turtle.digDown()
    turtle.select(1)
end


function nextMine()
    go(FORWARD)
    go(FORWARD)
    turtle.turnRight()
    go(FORWARD)
    turtle.turnLeft()
end


function shaft()
    if turtle.getFuelLevel() < 500 then
        print("Not enough fuel.\nAvailable: "..turtle.getFuelLevel().."\nRequired: 500.")
        newLogEntry("Not enough fuel. Fuel level is "..turtle.getFuelLevel())
        return false
    end
    newLogEntry("Starting a shaft.")
    mine()
    newLogEntry("Shaft complete.")
    newLogEntry("Refueling.")
    eat()
    newLogEntry("Dropping stuff.")
    drop()
    return true
end



newLogEntry("Checking for ores.json.")
if (fs.exists("ores.json")) then
    local file = fs.open("ores.json", "r")
    listOres = textutils.unserialiseJSON(file.readAll())
    file.close()
    newLogEntry("New list is loaded.")
else
    print("File \"ores.json\" is missing. I will mine default minecraft ores.")
    newLogEntry("Default list is used.")
end

newLogEntry("Checking for dimensions.")
local length = 3
local width = 3
if args[1] ~= nil and args[2] ~= nil and tonumber(args[1]) > 0 and tonumber(args[2]) > 0 then
    length = tonumber(args[1])
    width = tonumber(args[2])
    newLogEntry("New dimensions.\nLength is: "..length..".\nWidth is: "..width..".")
else
    print("No dimension sizes were entered or bad input. I will use default dimensions.")
    newLogEntry("Default dimensions are used.")
end

newLogEntry("Starting to work on a field "..length.."x"..width..".")
for i = 1, width do
    for j = 1, length - 1 do
        shaft()
        nextMine()
    end
    shaft()
    if i == width then break end

    if i % 2 == 1 then turtle.turnRight() else turtle.turnLeft() end
    nextMine()
    if i % 2 == 1 then turtle.turnRight() else turtle.turnLeft() end
end

newLogEntry("Going back to start.")
if width % 2 == 1 then
    turtle.turnLeft()
    turtle.turnLeft()
    for i = 1, length - 1 do
        nextMine()
    end
end
turtle.turnRight()
for i = 1, width - 1 do
    nextMine()
end

newLogEntry("Work is done.")
log.close()