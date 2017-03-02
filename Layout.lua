-- Layout and Block
local Layout = class()
local Block = class()

if cmodule then
    Rectangle = cimport "Rectangle"
    cimport "MathsUtilities"
    cimport "Coordinates"
end

function Layout:init(t)
    self.blocks = {}
    self.touchHandler = t.touchHandler
    self.touches = t.touchHandler:pushHandlers()
    self.orientation = t.orientation or PORTRAIT
    self.touchables = {}
end

function Layout:draw()
    if not self.active then
        return
    end
    pushMatrix()
    TransformOrientation(self.orientation)
    for _,v in ipairs(self.blocks) do
        v:draw()
    end
    popMatrix()
end

function Layout:addBlock(t)
    local b = Block(t,self)
    table.insert(self.blocks,b)
    local th = self.touchHandler:registerHandler(b)
    table.insert(self.touchables,1,th)
    if self.active then
        table.insert(self.touches,1,th)
    end
    return b
end

function Layout:activate()
    for k,v in ipairs(self.touchables) do
        table.insert(self.touches,v)
    end
    self.active = true
end

function Layout:deactivate()
    for k,_ in ipairs(self.touches) do
        self.touches[k] = nil
    end
    self.active = false
end

function Block:init(t,l)
    local rt = {}
    rt[t.anchor] = t.position
    local a
    self.orientation = t.orientation or CurrentOrientation
    if self.orientation == LANDSCAPE_LEFT 
        or self.orientation == LANDSCAPE_RIGHT then
        a = 3/4
    else
        a = 4/3
    end
    local s
    if t.width then
        s = vec2(1,a)*t.width
    elseif t.height then
        s = vec2(1/a,1)*t.height
    else
        s = vec2(1,a)*WIDTH
    end
    rt.size = s
    local r = Rectangle(rt)
    self.rectangle = r
    self:setContents(t.contents)
    self.size = s
    local o = USOrientation(self.orientation,vec2(0,0))
    local x = USOrientation(self.orientation,vec2(1,0)) - o
    local y = USOrientation(self.orientation,vec2(0,1)) - o
    local w,h = RectAnchorOf(Portrait,"size")
    local oo = r.ll + vec2(s.x*o.x,s.y*o.y)
    local xx = vec2(s.x*x.x,s.y*x.y)/w
    local yy = vec2(s.x*y.x,s.y*y.y)/h
    self.matrix = matrix(
        xx.x,xx.y,0,0,
        yy.x,yy.y,0,0,
        0,0,1,0,
        oo.x,oo.y,0,1
    )
    self.clip = t.clip
    self.touchTransform = function(v)
        v = TransformTouch(l.orientation,v)
        v = vec2(v.x,v.y) - oo
        v = v.x * vec2(yy.y,-xx.y) + v.y * vec2(-yy.x,xx.x)
        v = v / (xx.x*yy.y - xx.y*yy.x)
        return v
        end
end

local matrixStack = {}

local function pushMatrices()
    table.insert(matrixStack,{modelMatrix(),
                              viewMatrix(),
                              projectionMatrix()})
end

local function popMatrices()
    local m = table.remove(matrixStack)
    modelMatrix(m[1])
    viewMatrix(m[2])
    projectionMatrix(m[3])
end

local function resetMatrices()
    modelMatrix(matrix())
    viewMatrix(matrix())
    ortho()
end

function Block:draw()
    if self.clip then
    clip(self.rectangle.ll.x,self.rectangle.ll.y,
         self.rectangle.size.x,self.rectangle.size.y)
    end
    pushMatrices()
    local opm = projectionMatrix()
    local pm = opm:inverse()*self.matrix*opm
    local oproj,oper,oorth = projectionMatrix,perspective,ortho
    _G["projectionMatrix"] = function(m)
        if m then
            oproj(m*pm)
        else
            m = oproj()*pm:inverse()
            return m
        end
    end
    _G["perspective"] = function(...)
        oper(...)
        projectionMatrix(oproj())
    end
    _G["ortho"] = function(...)
        oorth(...)
        projectionMatrix(oproj())
    end
    projectionMatrix(opm)
    local cOrientation = {CurrentOrientation,WIDTH,HEIGHT}
    _G["CurrentOrientation"], _G["WIDTH"],_G["HEIGHT"] = PORTRAIT, RectAnchorOf(Portrait,"size")
    self.contents:draw()
    _G["CurrentOrientation"], _G["WIDTH"],_G["HEIGHT"] = unpack(cOrientation)
    _G["projectionMatrix"], _G["perspective"], _G["ortho"] = oproj,oper,oorth
    popMatrices()
    if self.clip then
    clip()
    end
end

function Block:isTouchedBy(touch)
    local v = self.rectangle:anchor("south west")
    if touch.x < v.x then
        return false
    end
    if touch.y < v.y then
        return false
    end
    v = self.rectangle:anchor("north east")
    if touch.x > v.x then
        return false
    end
    if touch.y > v.y then
        return false
    end
    return true
end

function Block:processTouches(g)
    if self.action then
        self.action(g)
    end
end

function Block:passTouchesTo(v)
    if type(v) == "table" then
    if type(v.isTouchedBy) == "function" then
    local f = v.isTouchedBy
    local w,h = RectAnchorOf(Portrait,"size")
    self.isTouchedBy = function(s,t)
        t = TransformTouch(self.touchTransform,t)
        if t.x < 0 then
            return false
        end
        if t.x > w then
            return false
        end
        if t.y < 0 then
            return false
        end
        if t.y > h then
            return false
        end
        return f(v,t)
    end
    self.isTouchedBySave = self.isTouchedBy
    local ff = v.processTouches
    self.processTouches = function(s,g)
        g:transformTouches(self.touchTransform)
        return ff(v,g)
    end
    end
    end
end

function Block:ignoreTouches()
    self.isTouchedBy = function() return false end
end

function Block:noticeTouches()
    self.isTouchedBy = self.isTouchedBySave
end

function Block:anchor(a)
    return self.rectangle:anchor(a)
end

function Block:setContents(c)
    if c then
        self.contents = c
        self:passTouchesTo(self.contents)
    end
end

if cmodule then
    return {Layout, Block}
else
    _G["Layout"] = Layout
    _G["Block"] = Block
end
