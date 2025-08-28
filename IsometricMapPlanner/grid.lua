-- grid.lua
local grid = {}
grid.tiles = {}
grid.grid_size = 20

-- External dependencies (set later in main)
grid.grass = nil
grid.dirt = nil
grid.block_width = 0
grid.block_height = 0
grid.block_depth = 0
grid.grid_x = 0
grid.grid_y = 0

function grid.init()
    for x = 1, grid.grid_size do
        grid.tiles[x] = {}
        for y = 1, grid.grid_size do
            grid.tiles[x][y] = { tile_type = 1, height = 0 }
        end
    end
end

function grid.draw(camera_x, camera_y, zoom)
    for x = 1, grid.grid_size do
        for y = 1, grid.grid_size do
            local tile = grid.tiles[x][y]
            local height = tile.height
            local screenX = grid.grid_x + ((y - x) * (grid.block_width / 2))
            local baseY = grid.grid_y + ((x + y) * (grid.block_depth / 2)) - (grid.block_depth * (grid.grid_size / 2)) - grid.block_depth

            local full_blocks = math.floor(height)
            local has_fraction = height % 1 ~= 0

            -- Always draw base grass block
            love.graphics.draw(grid.grass, screenX, baseY)

            -- Draw additional full grass blocks for height > 1
            for h = 1, full_blocks do
                local screenY = baseY - h * grid.block_depth
                love.graphics.draw(grid.grass, screenX, screenY)
            end

            -- Draw a half block (dirt) if there is a fractional part
            if has_fraction then
                local screenY = baseY - (full_blocks + 1) * grid.block_depth
                love.graphics.draw(grid.dirt, screenX, screenY)
            end
        end
    end
end




function grid.screenToGrid(world_x, world_y)
    local ox = world_x - grid.grid_x
    local oy = world_y - grid.grid_y + (grid.block_depth * (grid.grid_size / 2)) + grid.block_depth

    local ty = ((ox / (grid.block_width / 2)) + (oy / (grid.block_depth / 2))) / 2
    local tx = ((oy / (grid.block_depth / 2)) - (ox / (grid.block_width / 2))) / 2

    return tx, ty
end

function grid.isPointInTile(px, py, tileX, tileY)
    local tile = grid.tiles[tileX] and grid.tiles[tileX][tileY]
    if not tile then return false end

    local height_offset = tile.height * grid.block_depth

    local centerX = grid.grid_x + ((tileY - tileX) * (grid.block_width / 2))
    local centerY = grid.grid_y + ((tileX + tileY) * (grid.block_depth / 2)) - (grid.block_depth * (grid.grid_size / 2)) - grid.block_depth

    local dx = px - centerX - grid.block_width / 2
    local dy = py - centerY - grid.block_depth / 2

    dx = dx / (grid.block_width / 2)
    dy = dy / (grid.block_height)

    return math.abs(dx) + math.abs(dy) <= 1
end

function grid.handleClick(world_x, world_y)
    local txf, tyf = grid.screenToGrid(world_x, world_y)
    local candidates = {
        {math.floor(txf), math.floor(tyf)},
        {math.ceil(txf), math.floor(tyf)},
        {math.floor(txf), math.ceil(tyf)},
        {math.ceil(txf), math.ceil(tyf)}
    }

    for _, pair in ipairs(candidates) do
        local tx, ty = pair[1], pair[2]
        if grid.tiles[tx] and grid.tiles[tx][ty] and grid.isPointInTile(world_x, world_y, tx, ty) then
            local tile = grid.tiles[tx][ty]
            if love.keyboard.isDown("lshift") then
                grid.tiles[tx][ty].height = grid.tiles[tx][ty].height + 0.5
                print(string.format("Increased height at [%d, %d] to %.1f", tx, ty, tile.height))
            elseif love.keyboard.isDown("lctrl") then
                grid.tiles[tx][ty].height = math.max(0, grid.tiles[tx][ty].height - 0.5)
                print(string.format("Decreased height at [%d, %d] to %.1f", tx, ty, tile.height))
            else
                grid.tiles[tx][ty].tile_type = (grid.tiles[tx][ty].tile_type == 1) and 2 or 1
                print(string.format("Changed tile type at [%d, %d]", tx, ty))
            end
            break
        end
    end
end

function grid.exportToFile(filename)
    local lines = {}
    for x = 1, grid.grid_size do
        for y = 1, grid.grid_size do
            local tile = grid.tiles[x][y]
            table.insert(lines, string.format("%d %d %d %.1f", x, y, tile.tile_type, tile.height))
        end
    end

    local file = love.filesystem.newFile(filename, "w")
    file:write(table.concat(lines, "\n"))
    file:close()
    print("Grid exported to " .. filename)
    print(love.filesystem.getSaveDirectory())
end

function grid.importFromFile(filename)
    if not love.filesystem.getInfo(filename) then
        print("File not found: " .. filename)
        return
    end

    for line in love.filesystem.lines(filename) do
        local x, y, tile_type, height = line:match("(%d+)%s+(%d+)%s+(%d+)%s+([%d%.]+)")
        x = tonumber(x)
        y = tonumber(y)
        tile_type = tonumber(tile_type)
        height = tonumber(height)

        if grid.tiles[x] and grid.tiles[x][y] then
            grid.tiles[x][y].tile_type = tile_type
            grid.tiles[x][y].height = height
        end
    end

    print("Grid imported from " .. filename)
end

return grid
