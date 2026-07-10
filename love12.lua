function love.sensorupdated() end
-- Called when the in-device sensor is updated.

----------------------------------------------------------------------------

function love.audiodisconnected() end
-- Called when the active audio device is disconnected.

----------------------------------------------------------------------------

function love.dropbegan() end
-- Callback function triggered when a file or folder is first dragged onto the window, before the user drops it.

function love.dropcompleted() end
-- Callback function triggered when a file or folder is done being dragged and dropped into the window.

function love.dropmoved() end
-- Callback function triggered when an in-progress file or folder drag-and-drop operation changes position.

function love.localechanged() end
-- Callback function triggered when the user's system locale preferences have changed.
