local Marquee = {}

Marquee.HOLD = 1.0
Marquee.STEP = 0.25

-- Each scrolling row gets its own phase.
-- This allows multiple marquees to run independently.
local phases = {}

local function clock()
    local timer = love and love.timer and love.timer.getTime
    return timer and timer() or 0
end

-- Pure, so a test can step it without a clock.
function Marquee.at(text, maxChars, elapsed)
    text = text or ""

    local over = #text - maxChars
    if over <= 0 then
        return text
    end

    local span = Marquee.HOLD * 2 + over * Marquee.STEP
    local now = elapsed % span

    local offset

    if now < Marquee.HOLD then
        offset = 0

    elseif now < Marquee.HOLD + over * Marquee.STEP then
        offset = math.floor(
            (now - Marquee.HOLD) / Marquee.STEP
        )

    else
        offset = over
    end

    return text:sub(offset + 1, offset + maxChars)
end

-- `key` identifies the scrolling row.
-- Each key has its own independent cycle.
function Marquee.scroll(text, maxChars, key)
    if not text or #text <= maxChars then
        return text or ""
    end

    key = key or "__default"

    local now = clock()
    local phase = phases[key]

    if not phase then
        phase = {
            start = now
        }
        phases[key] = phase
    end

    return Marquee.at(
        text,
        maxChars,
        now - phase.start
    )
end

function Marquee.clip(text, maxChars)
    return (text or ""):sub(1, maxChars)
end

-- Optional: restart one specific marquee.
function Marquee.reset(key)
    if key then
        phases[key] = nil
    end
end

-- Optional: reset all marquees.
function Marquee.resetAll()
    phases = {}
end

return Marquee