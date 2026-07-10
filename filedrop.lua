function love.directorydropped()

end
-- Callback function triggered when a directory is dragged and dropped onto the window.

function love.filedropped()

end
-- Callback function triggered when a file is dragged and dropped onto the window.

-------------- in love 12: ----------------

function love.dropbegan()

end
-- Callback function triggered when a file or folder is first dragged onto the window, before the user drops it.

function love.dropcompleted()

end
-- Callback function triggered when a file or folder is done being dragged and dropped into the window.

function love.dropmoved()

end
-- Callback function triggered when an in-progress file or folder drag-and-drop operation changes position.