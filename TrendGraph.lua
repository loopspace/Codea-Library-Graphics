-- Trend Graph

local TrendGraph = class()

if cmodule then
    Frame = cimport "Frame"
    DataSeries = cimport "DataSeries"
    Colour = cimport "Colour"
end

function TrendGraph:init(t)
    self.outer = Frame(t.x, t.y, t.x + t.width, t.y + t.height)
    self.inner = Frame(t.x + 20, t.y + 10, t.x + t.width - 10, t.y + t.height - 20)
    self.title = t.title or ""
    self.font = t.font or "Copperplate"
    self.fontSize = t.fontSize or 16
    self.colour = t.colour or Colour.svg.SlateGray
    self.icolour = Colour.tint(self.colour,50)
    self.rate = t.rate or 1
    self.series = {}
    self.xlabel = ""
    self.ylabel = ""
    font(self.font)
    fontSize(self.fontSize)
    local w,h = textSize(self.title)
    self.titlex = self.outer:midx() - w/2
    self.titley = self.outer.y2 - h - 5
    self.frame = 0
end

function TrendGraph:addSeries(name, len, min, max, sym, size, thick, clr, value)
    local i
    i = #self.series
    self.series[i + 1] = DataSeries(name, len, min, max, sym, size, thick, clr, value)
end

function TrendGraph:draw(pts)
    pushMatrix()
    pushStyle()
    self.frame = self.frame + 1
    fill(self.colour)
    self.outer:draw()
    stroke(253, 3, 3, 255)
    fill(self.icolour)
    self.inner:draw()
    fill(0, 0, 0, 255)
    noSmooth()
    font(self.font)
    fontSize(self.fontSize)
    textMode(CORNER)
    text(self.title,self.titlex,self.titley)
    for s, series in ipairs(self.series) do
        if self.frame%self.rate == 0 and not self.paused then
            series:update()
        end
        series:draw(self.inner, self.min, self.max)
    end
    popMatrix()
    popStyle()
end

function TrendGraph:pause(p)
    self.paused = p
    for s, series in ipairs(self.series) do
        series:addBreak()
    end
end

if cmodule then
    return TrendGraph
else
    _G["TrendGraph"] = TrendGraph
end
