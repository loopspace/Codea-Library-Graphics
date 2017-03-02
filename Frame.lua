-- Frame

-- ====================
-- Frame 
-- ver. 0.1
-- a simple rectangle to act as a base for controls
-- ====================

local Frame = class()

function Frame:init(x1, y1, x2, y2)
    self.x1 = x1
    self.x2 = x2
    self.y1 = y1
    self.y2 = y2
end

function Frame:draw()
    pushStyle()
    rectMode(CORNERS)
    rect(self.x1, self.y1, self.x2, self.y2)
    popStyle()
end

function Frame:gloss()
    local i, t, r, y
    pushStyle()
    fill(255, 255, 255, 255)
    rectMode(CORNERS)
    rect(self.x1, self.y1, self.x2, self.y2)
    r = (self.y2 - self.y1) / 2
    for i = 1 , r do
        t = 255 - i 
        stroke(t, t, t, 255)
        y = (self.y1 + self.y2) / 2
        line(self.x1, y + i, self.x2, y + i)
        line(self.x1, y - i, self.x2, y - i)
    end
    popStyle()
end


function Frame:touched(touch)
    if touch.x >= self.x1 and touch.x <= self.x2 then
        if touch.y >= self.y1 and touch.y <= self.y2 then
            return true
        end
    end
    return false
end

function Frame:midx()
    return (self.x1 + self.x2) / 2
end
    
function Frame:midy()
    return (self.y1 + self.y2) / 2
end

if cmodule then
    return Frame
else
    _G["Frame"] = Frame
end

