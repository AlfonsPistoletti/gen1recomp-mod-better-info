local M = {}

function M.loadDataFile(mod, relPath)
    local text = mod:read(relPath)
    local chunk = assert(load(text, "@" .. relPath))
    return chunk()
end