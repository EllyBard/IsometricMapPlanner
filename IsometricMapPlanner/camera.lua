-- camera.lua
local camera = {}

camera.x = 0
camera.y = 0
camera.zoom = 1
camera.zoom_speed = 0.1
camera.min_zoom = 0.5
camera.max_zoom = 5

camera.isDragging = false
camera.dragStartX = 0
camera.dragStartY = 0
camera.cameraStartX = 0
camera.cameraStartY = 0

function camera.update()
    if camera.isDragging then
        local mx, my = love.mouse.getPosition()
        camera.x = camera.cameraStartX + (mx - camera.dragStartX)
        camera.y = camera.cameraStartY + (my - camera.dragStartY)
    end
end

function camera.mousepressed(x, y, button)
    if button == 2 then
        camera.isDragging = true
        camera.dragStartX = x
        camera.dragStartY = y
        camera.cameraStartX = camera.x
        camera.cameraStartY = camera.y
    end
end

function camera.mousereleased(x, y, button)
    if button == 2 then
        camera.isDragging = false
    end
end

function camera.wheelmoved(x, y)
    if y == 0 then return end
    local old_zoom = camera.zoom
    camera.zoom = math.max(camera.min_zoom, math.min(camera.max_zoom, camera.zoom + y * camera.zoom_speed))

    local mx, my = love.mouse.getPosition()
    local world_x = (mx - camera.x) / old_zoom
    local world_y = (my - camera.y) / old_zoom
    camera.x = mx - world_x * camera.zoom
    camera.y = my - world_y * camera.zoom
end

return camera
