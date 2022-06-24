local forward = 1
local back    = 2
local up      = 3
local down    = 4
local left    = 5
local right   = 6
local list = {"minecraft:coal_ore", "minecraft:deepslate_coal_ore",
              "minecraft:iron_ore", "minecraft:deepslate_iron_ore",
              "minecraft:copper_ore", "minecraft:deepslate_copper_ore",
              "minecraft:gold_ore", "minecraft:deepslate_gold_ore",
              "minecraft:redstone_ore", "minecraft:deepslate_redstone_ore",
              "minecraft:emerald_ore", "minecraft:deepslate_emerald_ore",
              "minecraft:lapis_ore", "minecraft:deepslate_lapis_ore",
              "minecraft:diamond_ore", "minecraft:deepslate_diamond_ore",
              "minecraft:nether_gold_ore", "minecraft:nether_quarz_ore",
              "minecraft:ancient_debris"}
local MAX_SLOTS = 14
local BUCKET_SLOT = 15
local CHEST_SLOT = 16

if (fs.exists("ores.json")) then
    local file = file.open("ores.json", "r")
    list = textutils.unserialiseJSON(file.readAll())
    file.close()
else
    print("List of ores not found. I will mine default minecraft ores.")
end

function drink(dir)
    local exist, block
    if dir == up then
        exist, block = turtle.inspectUp()
    elseif dir == down then
        exist, block = turtle.inspectDown()
    else
        exist, block = turtle.inspect()
    end
    if exist == false or block.name ~= "minecraft:lava" then
        return
    end
    turtle.select(BUCKET_SLOT)
    turtle.equipRight()
    if dir == up then
        turtle.placeUp()
    elseif dir == down then
        turtle.placeDown()
    else
        turtle.place()
    end
    turtle.equipRight()
    turtle.refuel()
    turtle.select(1)
end


function go(dir)
    if dir == back then
        turtle.turnLeft()
        turtle.turnLeft()
    end
    if dir == left then
        turtle.turnLeft()
    end
    if dir == right then
        turtle.turnRight()
    end
    for i=1, 16 do
        if dir == up then
            drink(up)
            turtle.digUp()
            if turtle.up() == true then
                return true
            end
        elseif dir == down then
            drink(down)
            turtle.digDown()
            if turtle.down() == true then
                return true
            end
        else
            drink(forward)
            turtle.dig()
            if turtle.forward() == true then
                return true
            end
        end
    end
    return false
end


function inList()
    local exist, block = turtle.inspect()
    if exist == false then
        return false
    end
    for _, name in ipairs(list) do
        if name == block.name then
            return true
        end
    end
    return false
end


function mine()
    local counter = 0
    while true do
        if not go(down) then
            break
        end
        for i=1, 4 do
            drink(forward)
            if inList() then
                turtle.dig()
            end
            turtle.turnLeft()
        end
        counter = counter + 1
    end
    for i=1, counter do
        go(up)
    end
end


function eat()
    if turtle.getFuelLevel() > 5000 then
        return
    end
    for i=1, MAX_SLOTS do
        if turtle.getItemDetail(i).name == "minecraft:coal" then
            turtle.refuel()
        end
    end
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
    go(forward)
    go(forward)
    go(forward)
end

for i=1, 10 do
    mine()
    eat()
    drop()
    nextMine()
end

