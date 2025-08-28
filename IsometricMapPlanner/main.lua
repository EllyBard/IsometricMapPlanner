-- main.lua
local grid = require("grid")
local camera = require("camera")

love.graphics.setDefaultFilter("nearest", "nearest")
local grass = love.graphics.newImage("tiles/isometric_test_grass.png")
local dirt = love.graphics.newImage("tiles/isometric_test_half_block.png")

-- Tile metrics
local block_width = grass:getWidth()
local block_height = grass:getHeight()
local block_depth = block_height / 2
local grid_x = love.graphics.getWidth() / 2
local grid_y = love.graphics.getHeight() / 2

function love.load()
    love.graphics.setBackgroundColor(0.3, 0.5, 0.8)

    -- Pass required external info to grid module
    grid.grass = grass
    grid.dirt = dirt
    grid.block_width = block_width
    grid.block_height = block_height
    grid.block_depth = block_depth
    grid.grid_x = grid_x
    grid.grid_y = grid_y

    grid.init()
end

function love.update(dt)
    camera.update()
end

function love.draw()
    love.graphics.push()
    love.graphics.translate(camera.x, camera.y)
    love.graphics.scale(camera.zoom)
    grid.draw(camera.x, camera.y, camera.zoom)

    -- Highlight hovered tile
    local mx, my = love.mouse.getPosition()
    local world_x = (mx - camera.x) / camera.zoom
    local world_y = (my - camera.y) / camera.zoom
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
            local screenX = grid_x + ((ty - tx) * (block_width / 2))
            local screenY = grid_y + ((tx + ty) * (block_depth / 2)) - (block_depth * (grid.grid_size / 2)) - block_depth - (grid.tiles[tx][ty].height * block_depth)

            love.graphics.setColor(1, 0, 0, 0.5)
            love.graphics.polygon("line", {
                screenX + block_width / 2, screenY,
                screenX + block_width,     screenY + block_depth / 2,
                screenX + block_width / 2, screenY + block_depth,
                screenX,                   screenY + block_depth / 2,
            })
            love.graphics.setColor(1, 1, 1)
            break
        end
    end

    love.graphics.pop()
end

function love.mousepressed(x, y, button)
    camera.mousepressed(x, y, button)
    if button == 1 then
        local world_x = (x - camera.x) / camera.zoom
        local world_y = (y - camera.y) / camera.zoom
        grid.handleClick(world_x, world_y)
    end
end

function love.mousereleased(x, y, button)
    camera.mousereleased(x, y, button)
end

function love.wheelmoved(x, y)
    camera.wheelmoved(x, y)
end

function love.keypressed(key)
    if key == "f5" then
        grid.exportToFile("saved_grid.txt")
    elseif key == "f6" then
        grid.importFromFile("saved_grid.txt")
    end
end