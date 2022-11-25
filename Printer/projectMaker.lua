--          programm for making building blueprints          --

local args = {...}
local projectName = args[1]
local path = fs.getDir(shell.getRunningProgram())

-- takes a color from blueprint and asigns a building block to it from user input
local function appendIni(pathIni)
    local image = paintutils.loadImage(pathIni)
    local ini = {}
    for _, row in pairs(image) do
        for _, block in pairs(row) do
            if ini[block] == nil and block ~= 0 then
                term.setTextColor(block)
                if block == 32768 then
                    term.setBackgroundColor(1)
                end
                write("Enter block name for "..colors.toBlit(block).." minecraft:")
                ini[block] = "minecraft:"..io.read()
                if block == 32768 then
                    term.setBackgroundColor(32768)
                end
            end
        end
    end
    term.setTextColor(1)
    return textutils.serialise(ini, {compact = true})
end


-- main part----------------------------------------------------------------------------
if projectName == nil then
    print("Bad argument #1. String project name required.")
    return
end

if fs.isDir(projectName) then
    print("Project with such name already exists.")
    return
end

fs.makeDir(path.."/blueprints/"..projectName)
local file = fs.open(path.."/blueprints/"..projectName.."/"..projectName..".ini", "a")
local iterator = 1

-- starts paint for drawing a blueprint layer by layer and writes data to a file
while true do
    shell.run("/rom/programs/fun/advanced/paint", projectName.."/"..projectName.."_"..iterator..".img")
    if not fs.exists(path.."/blueprints/"..projectName.."/"..projectName.."_"..iterator..".img") then
        break
    end

    file.writeLine(appendIni(path.."/blueprints/"..projectName.."/"..projectName.."_"..iterator..".img"))
    file.flush()
    iterator = iterator + 1
end

file.close()