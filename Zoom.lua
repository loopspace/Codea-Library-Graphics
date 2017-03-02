-- 2D Zoom

local Zoom = class()

if cmodule then
    cimport "Coordinates"
end

function Zoom:init(t)
    if t then
        t:pushHandler(self)
    end
    self.ll = vec2(0,0)
    self.mid = vec2(0,0)
    self.size = vec2(1,1)
    -- self.aspect = true
end

function Zoom:draw()
    scale(self.size.x,self.size.y)
    translate(self.ll.x,self.ll.y)
end

function Zoom:isTouchedBy(touch)
    self.inTouch = true
    return true
end

function Zoom:reset()
    self.ll = vec2(0,0)
    self.mid = vec2(0,0)
    self.size = vec2(1,1)
end

function Zoom:resetTranslation()
    self.ll = vec2(0,0)
    self.mid = vec2(0,0)
end

function Zoom:resetScale()
    local v = vec2(RectAnchorOf(Screen,"centre"))
    v.x = v.x * (self.size.x - 1)
    v.y = v.y * (self.size.y - 1)
    self.size = vec2(1,1)
    self.ll.x = self.ll.x / self.size.x
    self.ll.y = self.ll.y / self.size.y
    self.ll = self.ll + v
end

function Zoom:zoom(s)
    self.size = self.size * s
    self.ll = self.ll/s + vec2(RectAnchorOf(Screen,"centre")) * (1/s - 1)
end

function Zoom:compose(z)
    self.size.x = self.size.x*z.size.x
    self.size.y = self.size.y*z.size.y
    self.ll.x = self.ll.x/z.size.x + z.ll.x
    self.ll.y = self.ll.y/z.size.y + z.ll.y
end

function Zoom:preCompose(z)
    self.ll.x = z.ll.x/self.size.x + self.ll.x
    self.ll.y = z.ll.y/self.size.y + self.ll.y
    self.size.x = self.size.x*z.size.x
    self.size.y = self.size.y*z.size.y
end

function Zoom:processTouches(g)
    if g.updated then
        if g.type.ended and g.type.tap and g.num == 2 then
            self:reset()
            g:reset()
            return
        end
    if g.numactives == 1 then
        local dx = g.actives[1].touch.deltaX/self.size.x
        local dy = g.actives[1].touch.deltaY/self.size.y
        self.ll = self.ll + vec2(dx,dy)
    elseif g.numactives == 2 then
        local ta = g.actives[1]
        local tb = g.actives[2]
        local ea = vec2(ta.touch.x,ta.touch.y)
        local eb = vec2(tb.touch.x,tb.touch.y)
        local sa,sb
        if ta.updated then
            sa = vec2(ta.touch.prevX,ta.touch.prevY)
        else
            sa = ea
        end
        if tb.updated then
            sb = vec2(tb.touch.prevX,tb.touch.prevY)
        else
            sb = eb
        end
        local sc = (sa + sb)/2
        sc.x = sc.x / self.size.x
        sc.y = sc.y / self.size.y
        local sl = (sb - sa):len()
        local el = (eb - ea):len()
        self.size = self.size * el / sl
        local ec = (ea + eb)/2
        ec.x = ec.x / self.size.x
        ec.y = ec.y / self.size.y
        self.ll = self.ll + ec - sc
        self.mid = self.mid + ec - sc
    end
    end
    if self.onAdjust then
        self:onAdjust()
    end
    if g.type.finished then
        if self.afterAdjust then
            self:afterAdjust()
        end
        self.inTouch = false
        g:reset()
    else
        g:noted()
    end
end

function Zoom:fromScreen(v)
    local u = vec2(0,0)
    u.x = v.x / self.size.x - self.ll.x
    u.y = v.y / self.size.y - self.ll.y
    return u
end

function Zoom:toScreen(v)
    local u = vec2(0,0)
    u.x = (v.x + self.ll.x) * self.size.x
    u.y = (v.y + self.ll.y) * self.size.y
    return u
end

function Zoom:transformTouch(t)
    local tt = {}
    local v = self:fromScreen(t)
    tt.x = v.x
    tt.y = v.y
    v = self:fromScreen(vec2(t.prevX,t.prevY))
    tt.prevX = v.x
    tt.prevY = v.y
    tt.deltaX = tt.x - v.x
    tt.deltaY = tt.y - v.y
    for _,u in ipairs({"state","tapCount","id"}) do
        tt[u] = t[u]
    end
    return tt
end

function Zoom:transformObject(ob)
    local f = ob.isTouchedBy
    ob.isTouchedBy = function(s,t)
        t = self:transformTouch(t)
        return f(s,t)
    end
    local f = ob.processTouches
    local tf = function (t)
        return self:transformTouch(t)
    end
    ob.processTouches = function(s,g)
        g:transformTouches(tf)
        return f(s,g)
    end
end
    
if cmodule then
    return Zoom
else
    _G["Zoom"] = Zoom
end
