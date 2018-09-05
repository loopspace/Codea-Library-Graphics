-- Path object

local Path = class()

local PATH_STEP = 1
local PATH_RES = .05*.05
local PATH_RENDER = 0
local PATH_CREATE = 1
local PATH_POINTS = 2

function Path:init(t)
    t = t or {}
    self.style = t.style or {}
    self.lastPoint = vec2(0,0)
    self.elements = t.elements or {}
    if t.touchHandler then
        t.touchHandler:pushHandler(self)
    end
    
    self.touchpt = {}
    self.m = mesh()
end

function Path:deletePoints()
    self.elements = {}
    self.lastPoint = vec2(0,0)
end

function Path:draw()
    pushStyle()
    resetStyle()
    self:applyStyle(PATH_RENDER)
    self.m:draw()
    if self.edit then
        self:applyStyle(PATH_POINTS)
        local r = self.ptRadius
        local lpt
        pushStyle()
        noStroke()
        for k,v in ipairs(self.elements) do
            ellipse(v[2].x,v[2].y,r)
            if v[1] == "curve" then
                popStyle()
                line(lpt.x,lpt.y,v[2].x,v[2].y)
                line(v[3].x,v[3].y,v[4].x,v[4].y)
                pushStyle()
                noStroke()
                ellipse(v[3].x,v[3].y,r)
                ellipse(v[4].x,v[4].y,r)
                lpt = v[4]
            else
                lpt = v[2]
            end
        end
        popStyle()
    end
    popStyle()
end

function Path:generate()
    self:applyStyle(PATH_CREATE)
    local ver = {}
    local s,h
    for k,v in ipairs(self.elements) do
        ver,s,h = self:getPoints(v,ver,s,h)
    end
    if h then
        ver,s = HobbyPoints(ver,s,h)
    end
    self.lastPoint = s
    --debug:log({name = "path", message = "got called"})
    -- print("got called")
    self:makeMesh(ver)
end

function Path:applyStyle(t)
    local s = self.style or {}
    if t == PATH_CREATE then
        self.linewidth = s.linewidth or 5
        self.blur = s.blur or 1
        self.smooth = s.smooth or false
        self.drawColour = s.drawColour or Colour.svg.Black
    elseif t == PATH_RENDER then
    elseif t == PATH_POINTS then
        self.ptRadius = s.pointRadius or 15
        local l = s.pointLineWidth or 3
        strokeWidth(l)
        local l = s.pointLineCap or SQUARE
        lineCapMode(l)
    end
end

function Path:addElement(e)
    table.insert(self.elements,e)
end

function Path:moveto(v)
    self:addElement({"move",v})
    self.lastPoint = v
end

function Path:lineto(v)
    self:addElement({"line",v})
    self.lastPoint = v
end

function Path:curveto(b,c,d)
    self:addElement({"curve",b,c,d})
    self.lastPoint = d
end

function Path:curvethrough(v)
    self:addElement({"hobby",v})
    self.lastPoint = v
end

function Path:getPoints(e,ver,s,h)
    local t = e[1]
    if h and t ~= "hobby" then
        ver,s = HobbyPoints(ver,s,h)
    end
    if t == "move" then
        table.insert(ver,{e[2]})
        return ver, e[2]
    elseif t == "line" then
        local n = e[2] - s
        n = n:rotate90()
        n = n/n:len()
        table.insert(ver,{s,n})
        table.insert(ver,{e[2],n})
        return ver,e[2]
    elseif e[1] == "curve" then
        return BezierPoints(ver,s,e[2],e[3],e[4])
    elseif e[1] == "hobby" then
        h = h or {}
        table.insert(h,e[2])
        return ver,s,h
    else
        return ver,s
    end
end

function Path:makeMesh(pts)
    local ver = {}
    local col = {}
    local l = self.linewidth/2
    local b = self.blur + l
    local s = false -- self.smooth
    local c = self.drawColour
    local ct = Colour.opacity(c,0)
    local p,n
    local m = 0
    for k,v in ipairs(pts) do
        if v[2] and n then
        table.insert(ver,p + l*n)
        table.insert(ver,p - l*n)
        table.insert(ver,v[1] + l*v[2])
        table.insert(ver,v[1] + l*v[2])
        table.insert(ver,v[1] - l*v[2])
        table.insert(ver,p - l*n)
        for i=1,6 do
            table.insert(col,c)
        end
    m = m + 6
        if s then
        table.insert(ver,p + l*n)
        table.insert(ver,p + b*n)
        table.insert(ver,v[1] + l*v[2])
        table.insert(ver,v[1] + l*v[2])
        table.insert(ver,v[1] + b*v[2])
        table.insert(ver,p + b*n)
        table.insert(ver,p - l*n)
        table.insert(ver,p - b*n)
        table.insert(ver,v[1] - l*v[2])
        table.insert(ver,v[1] - l*v[2])
        table.insert(ver,v[1] - b*v[2])
        table.insert(ver,p - b*n)
        for i=1,12 do
            table.insert(col,ct)
        end
        end
        end
        p,n = unpack(v)
        
    end
    self.m.vertices = ver
    self.m.colors = col
end

function Path:isTouchedBy(touch)
    local p = vec2(touch.x,touch.y)
    for k,v in ipairs(self.elements) do
        if p:distSqr(v[2]) < 625 then
            self.touchpt[touch.id] = v[2]
            self.edit = true
            return true
        end
        if v[1] == "curve" then
            if p:distSqr(v[3]) < 625 then
                self.touchpt[touch.id] = v[3]
                self.edit = true
                return true
            end
            if p:distSqr(v[4]) < 625 then
                self.touchpt[touch.id] = v[4]
                self.edit = true
                return true
            end
        end
    end
    self.edit = false
    return false
end

function Path:processTouches(g)
    local regenerate = false
    if g.updated then
        for k,t in ipairs(g.touchesArr) do
            if t.updated then
                regenerate = true
                self.touchpt[t.touch.id].x = 
                    self.touchpt[t.touch.id].x
                    + t.touch.deltaX
                self.touchpt[t.touch.id].y = 
                    self.touchpt[t.touch.id].y
                    + t.touch.deltaY
            end
            if t.touch.state == ENDED then
                self.touchpt[t.touch.id] = nil
            end
        end
        g:noted()
        if regenerate then
            self:generate()
        end
    end
    if g.type.ended then
        g:reset()
    end
end

function Path:setLineWidth(l)
    self.style.linewidth = l
end

function Path:setBlur(l)
    self.style.blur = l
end

function Path:setSmooth(l)
    self.style.smooth = l
end

function Path:setColour(c)
    self.style.drawColour = c
end

local function BezierPoints(pts,a,b,c,d)
    pts = pts or {}
    if not(type(a) == "table" and a.is_a and a:is_a(Bezier)) then
        a = Bezier(a,b,c,d)
    end
    local t = 0
    local r = PATH_RES
    local s = PATH_STEP
    local tpt = a
    table.insert(pts,{tpt,a:unitNormal(0)})
    local dis
    local p
    while t < 1 do
        dis = 0
        while dis < r do
            t = t + s
            p = a:point(t)
            dis = p:distSqr(tpt)
        end
        if t > 1 then
            t = 1
            p = d
        end
        table.insert(pts,{p,a:unitNormal(t)})
        tpt = p
    end
    return pts
end

local function HobbyPoints(ver,s,pts,extra)
    ver = ver or {}
    if #pts == 1 then
        local v = pts[1]
        if type(v) == "table" then
            v = v[1]
        end
        local n = v - s
        n = n:rotate90()
        n = n/n:len()
        table.insert(ver,{s,n})
        table.insert(ver,{v,n})
        return ver
    end
    local apts = {}
    table.insert(apts,s)
    for _,v in ipairs(pts) do
        table.insert(apts,v)
    end
    local bcurves = Hobby(apts,extra)
    for _,v in ipairs(bcurves) do
        ver = BezierPoints(v,ver)
    end
    return ver
end

if cmodule then
    return Path
else
    _G["Path"] = Path
end
