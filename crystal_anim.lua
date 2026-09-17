-- Best-effort front-sprite animation for numbered PNG frame sequences,
-- the layout the "Crystal Animated Sprites with Shiny Visuals" mod ships
-- its art in (front/<variant>/<dex>/001.png, 002.png, ...).
--
-- better_info replaces DexEntryMenu and SummaryMenu outright (mod.content
-- .screens:override), so that mod's own animation hooks -- which patch
-- the ORIGINAL DexEntryMenu/SummaryMenu modules' update() -- never run
-- against our replacement screens. The static frame-1 image still shows
-- up fine, because it is resolved through the shared "pokemon.sprite"
-- hook both mods go through (src.pokemon.Sprites.path); only the
-- per-frame advance is missing.
--
-- Rather than depend on that mod's internals, this reopens the same
-- numbered-file convention starting from the frame-1 path our own sprite
-- load already resolved, so it degrades safely to a static sprite when
-- that mod (or any other frame-numbered art) isn't present: a path with
-- no "NNN.png" suffix, or only one frame on disk, is left untouched.
local M = {}

local FPS = 12          -- matches that mod's own front-sprite frame rate
local MAX_FRAMES = 64   -- matches its own per-species frame cap

local frameCache = {}   -- frame directory -> { images... } | false

local function frameParts(path)
    if type(path) ~= "string" then return nil end
    local normalized = path:gsub("\\", "/")
    local dir, num = normalized:match("^(.*/)(%d%d%d)%.png$")
    if not dir then return nil end
    return dir, tonumber(num)
end

-- Every frame image in the numbered sequence `path` (the resolved frame-1
-- path) belongs to, or nil when it isn't part of one. Cached per directory,
-- so the probe (bounded by MAX_FRAMES failed loads) runs once per
-- species/variant no matter how many screens ask for it. frame1Image lets
-- the caller hand over the image it already loaded for frame 1 instead of
-- loading it a second time.
function M.resolveFrames(path, frame1Image)
    local dir, num = frameParts(path)
    if not dir or num ~= 1 then return nil end

    local hit = frameCache[dir]
    if hit ~= nil then return hit or nil end

    local images = { frame1Image }
    for i = 2, MAX_FRAMES do
        local ok, img = pcall(love.graphics.newImage,
            ("%s%03d.png"):format(dir, i))
        if not (ok and img) then break end
        images[i] = img
    end

    local out = #images > 1 and images or false
    frameCache[dir] = out
    return out or nil
end

-- The frame `frames` should show right now. LOOP (the default, `once`
-- falsy) cycles forever at FPS, matching the animated-sprite mod's own
-- pace. PLAY ONCE runs from `startTime` through the frames a single time
-- and holds the last one, mirroring that mod's own PLAY ONCE behavior
-- (main.lua's advanceAnim: `anim.frame = #anim.durations; anim.done =
-- true`) -- see playOnce() below for where the flag comes from.
function M.frameForTime(frames, startTime, once)
    local t = (love.timer and love.timer.getTime and love.timer.getTime()) or 0
    local n = #frames
    if once then
        local elapsed = math.max(0, t - (startTime or t))
        local idx = math.floor(elapsed * FPS) + 1
        return frames[math.min(idx, n)]
    end
    return frames[math.floor(t * FPS) % n + 1]
end

-- Whether the "Crystal Animated Sprites with Shiny Visuals" mod's own
-- ANIMATIONS option (options_screen.lua's crystalAnimations row) is set
-- to PLAY ONCE. Read straight off the save -- the same field that mod's
-- row itself writes to and reads from -- so this needs no dependency on
-- that mod's exports, and reads as LOOP (false) with no effect at all
-- when that mod isn't installed (the field is simply never set).
function M.playOnce(game)
    return (game and game.save and game.save.options
        and game.save.options.crystalAnimations) == "once"
end

return M
