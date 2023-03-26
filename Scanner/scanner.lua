local MAX_RADIUS = 8
local WIDTH, HEIGTH = term.getSize()
local BUTTON_LENGTH = 7
local block_list = require("block_settings")



---------------------------------- RETURN LEN OF NUMBER ----------------------------------
local function get_num_len(num)
    local counter = 1
    if num < 0 then
        num = num * -1
        counter = 2
    end
    while true do
        if num == 0 then
            break
        end
        num = math.floor(num / 10)
        counter = counter + 1
    end
    return counter
end


---------------------------------- RENDER MAP ----------------------------------
local function render_map(layer)
    for x = 0, MAX_RADIUS * 2, 1 do
        for z = 0, MAX_RADIUS * 2, 1 do
            local block_settings
            block_settings = block_list[layer[x][z]] or block_list["unknown:unknown"]

            term.setCursorPos(WIDTH - MAX_RADIUS * 2 + x, z + 3)
            term.setTextColor(block_settings.color)
            term.setBackgroundColor(block_settings.bg_color)
            term.write(block_settings.char)
        end
    end
end


---------------------------------- RENDER LIST ----------------------------------
local function render_list(counter)
    local current_pos = 3
   ----------------- RENDER LIST -----------------
    local f = fs.open("unknown_blocks.txt", "w")
    for _, block in ipairs(counter) do
        local block_full_name = block[1]
        local amount = block[2]
        local block_settings
        term.setCursorPos(1, current_pos)

        if block_list[block_full_name] then
            block_settings = block_list[block_full_name]
        else
            f.write(block_full_name.."\n")
            block_settings = block_list["unknown:unknown"]
        end
        term.setTextColor(block_settings.color)
        term.setBackgroundColor(block_settings.bg_color)
        term.write(block_settings.char)

        term.setCursorPos(3, current_pos)
        term.setTextColor(colors.black)
        term.setBackgroundColor(colors.white)
        term.write(amount)
        if current_pos == HEIGTH then
            break
        end
        current_pos = current_pos + 1
    end
    f.close()
end


---------------------------------- RENDER HEADER ----------------------------------  
local function render_header(full_name)
    local mod = ""
    local name = ""
    if full_name then
        for m, n in string.gmatch(full_name, '([%w_]+):([%w_]+)') do
            mod = m
            name = n
            break
        end
    end
    name = name:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end):gsub("_", " ")

    term.setCursorPos(1, 1)
    term.setTextColor(colors.black)
    term.setBackgroundColor(colors.white)
    term.write(name)
    term.setCursorPos(1, 2)
    term.write(mod)
end


---------------------------------- RENDER BUTTONS ----------------------------------
local function render_buttons(layer)
    ------- CLOSE -------
    term.setCursorPos(WIDTH, 1)
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.red)
    term.write("X")

    ------- REFRESH -------
    term.setTextColor(colors.black)
    term.setBackgroundColor(colors.white)
    term.setCursorPos(WIDTH - 6, 2)
    term.write("REFRESH")

    term.setTextColor(colors.black)
    term.setBackgroundColor(colors.white)

    ------- PREV LAYER -------
    if layer ~= -MAX_RADIUS then
        term.setCursorPos(1, HEIGTH)
        term.write("\25 Layer")
    end

    ------- NEXT LAYER -------
    if layer ~= MAX_RADIUS then
        term.setCursorPos(WIDTH - BUTTON_LENGTH + 1, HEIGTH)
        term.write("Layer \24")
    end

    ------- LAYER NUM -------
    term.setCursorPos(math.floor((WIDTH - get_num_len(layer)) / 2) + 2, HEIGTH)
    term.write(layer)
end


---------------------------------- RENDER SCREEN ----------------------------------
local function render(layers, layer, layers_counter, selected_block)
    term.setBackgroundColor(colors.black)
    term.clear()
    render_map(layers[layer])
    render_list(layers_counter[layer])
    render_header(selected_block)
    render_buttons(layer - MAX_RADIUS)
end


---------------------------------- INITIALIZE MAP ----------------------------------
local function initialize()
    local layers = {}
    local layers_counter = {}
    for i=0, MAX_RADIUS * 2, 1 do
        layers[i] = {}
        for j=0, MAX_RADIUS * 2, 1 do
            layers[i][j] = {}
            for k=0, MAX_RADIUS * 2, 1 do
                layers[i][j][k] = "miecraft:air"
            end
        end
        layers_counter[i] = {}
    end
    ----------------- ADD PLAYER TO MAP -----------------
    layers[math.ceil(MAX_RADIUS)][math.ceil(MAX_RADIUS)][math.ceil(MAX_RADIUS)] = "minecraft:player"
    layers[math.ceil(MAX_RADIUS) + 1][math.ceil(MAX_RADIUS)][math.ceil(MAX_RADIUS)] = "minecraft:player"
    return layers, layers_counter
end


---------------------------------- SCAN AND CREATE MAP ----------------------------------
local function scan()
    local geo = peripheral.wrap("back")
    local data = geo.scan(MAX_RADIUS)
    while not data do
        data = geo.scan(MAX_RADIUS)
    end
    local layers, layers_counter = initialize()

    for _, block in pairs(data) do
        if layers_counter[block.y + MAX_RADIUS][block.name] then
            layers_counter[block.y + MAX_RADIUS][block.name] = layers_counter[block.y + MAX_RADIUS][block.name] + 1
        else
            layers_counter[block.y + MAX_RADIUS][block.name] = 1
        end
        layers[block.y + MAX_RADIUS][block.x + MAX_RADIUS][block.z + MAX_RADIUS] = block.name
    end

    ----------------- SORT LIST -----------------
    for i, counter in pairs(layers_counter) do
        local sorted_count = {}
        for k, v in pairs(counter) do
            table.insert(sorted_count, {k, v})
        end
        table.sort(sorted_count, function (a, b) return a[2] > b[2] end)
        layers_counter[i] = sorted_count
    end
    return layers, layers_counter
end


---------------------------------- MAIN ----------------------------------
local function main()
    local layers, layers_counter = scan()
    local layer = MAX_RADIUS
    local selected_block
    if layers_counter[layer][1] then
        selected_block = layers_counter[layer][1][1]
    else
        selected_block = nil
    end
while true do
        render(layers, layer, layers_counter, selected_block)
        local event, button, x, y = os.pullEvent("mouse_click")
        if y == HEIGTH then
            if x <= BUTTON_LENGTH and layer > 0 then
                layer = layer - 1
                if layers_counter[layer][1] then
                    selected_block = layers_counter[layer][1][1]
                else
                    selected_block = nil
                end
            elseif x >= WIDTH - BUTTON_LENGTH + 1 and layer < MAX_RADIUS * 2 then
                layer = layer + 1
                if layers_counter[layer][1] then
                    selected_block = layers_counter[layer][1][1]
                else
                    selected_block = nil
                end
            end
        elseif y == 1 and x == WIDTH then
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.white)
            term.setCursorPos(1, 1)
            term.clear()
            break
        elseif y == 2 and x >= WIDTH - 6 then
            layers, layers_counter = scan()
            if layers_counter[layer][1] then
                selected_block = layers_counter[layer][1][1]
            else
                selected_block = nil
            end
    elseif y > 2 and y < HEIGTH - 1 and x == 1 then
            if layers_counter[layer][y - 2] then
                selected_block = layers_counter[layer][y - 2][1]
            end
        elseif y > 2 and y <= MAX_RADIUS * 2 + 3 and x >= WIDTH - MAX_RADIUS * 2 then
            selected_block = layers[layer][x - WIDTH + MAX_RADIUS * 2][y - 3]
        end
    end
end

main()