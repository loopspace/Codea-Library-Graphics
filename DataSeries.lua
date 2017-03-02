-- Data Series

local DataSeries = class()

if cmodule then
    Colour = cimport "Colour"
end

function DataSeries:init(name, length, min, max, symbol, symbolsize, thick, clr, value)
    self.name = name
    self.symbol = symbol
    self.symbolsize = symbolsize
    self.nextpt = 0
    self.length = length
    self.lineclr = clr
    self.linethick = thick
    self.points = {}
    self.min = min
    self.max = max
    if self.min < 0 and self.max > 0 then
        self.axis = true
        self.acolour = Colour.shade(self.lineclr,50)
    end
    self.value = value
end

function DataSeries:addValue(y)
    self.nextpt = self.nextpt + 1
    if self.nextpt > self.length then
        self.nextpt = 1
    end
    self.points[self.nextpt] = vec2(i, y)
end

function DataSeries:update()
    if self.value then
        self:addValue(self.value())
    end
end

function DataSeries:addBreak()
    self.nextpt = self.nextpt + 1
    if self.nextpt > self.length then
        self.nextpt = 1
    end
    self.points[self.nextpt] = nil
end

function DataSeries:draw(frame)
    pushStyle()
    local ox, oy, w, h, x, y, p, dx, dy
    
    strokeWidth(self.linethick)
    w = frame.x2 - frame.x1
    h = frame.y2 - frame.y1
    dx = w / (self.length + 1)
    dy = h / (self.max - self.min)
    pushMatrix()
    translate(frame.x1, frame.y1)
    clip(frame.x1, frame.y1, w, h)
    if self.axis then 
        stroke(self.acolour)
        line(0,-self.min*dy,w,-self.min*dy)
    end
    ox = 0
    x = 0
    stroke(self.lineclr)
    for i = self.nextpt + 1, self.length do
        x = x + dx
        p = self.points[i]
        if p ~= nil then
            y = (p.y - self.min) * dy
            if ox > 0 then
                line(ox,oy,x,y)
            end
            ox = x
            oy = y
            if self.symbol == 1 then
                noFill()
                ellipse(x, y, self.symbolsize)
            end
        else
            ox = 0
        end
    end

    for i = 1, self.nextpt do
        x = x + dx
        p = self.points[i]
        if p ~= nil then
            y = (p.y - self.min) * dy
            if ox > 0 then
                line(ox,oy,x,y)
            end
            ox = x
            oy = y
            if self.symbol == 1 then
                noFill()
                ellipse(x, y, self.symbolsize)
            end
        else
            ox = 0
        end
    end
    popMatrix()
    noClip()
    popStyle()
end

if cmodule then
    return DataSeries
else
    _G["DataSeries"] = DataSeries
end


