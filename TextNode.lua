-- Text Node

if cmodule then
    Font,_,Textarea = unpack(cimport "Font",nil)
    Colour = cimport "Colour"
    UTF8 = cimport "utf8"
    cimport "Keyboard"
    --cimport "RoundedRect"
    cimport "ColourNames"
end

local TextNode = class(Textarea)

function TextNode:init(t)
    t = t or {}
    t.font = t.font or Font({name = "AmericanTypewriter", size = 12})
    t.width = t.width or "32em"
    t.height = t.height or "1lh"
    if t.fit == nil then
        t.fit = true
    end
    t.angle = t.angle or 0
    Textarea.init(self,t)
    self.keyboard = t.keyboard or "fullqwerty"
    self.ui = t.ui
    self:activate()
    self.edit = t.edit or true
    self.savecolour = self.colour
    self:setColour(Colour.opacity(Colour.svg.Black,50))
    self.ui:useKeyboard(self.keyboard,
        function(k) return self:processKey(k) end)
end

function TextNode:processTouches(g)
    if g.type.ended and g.type.tap and g.num == 2 then
        self:setEdit()
        g:reset()
        return
    end
    if g.updated then
        if g.num == 1 then
            local t = g.touchesArr[1]
        if self.edit then
            local td = 
                vec2(t.touch.deltaX,
                    t.touch.deltaY):rotate(-math.rad(self.angle))
            self:setSize({
                width = self.width + td.x,
                height = self.height + td.y,
                maxWidth = self.mwidth + td.x,
                maxHeight = self.mheight + td.y,
                })
        else
            self.anchor = nil
            self.opos = function() return self.x, self.y end
            self.x = self.x + t.touch.deltaX
            self.y = self.y + t.touch.deltaY
        end
            
        elseif g.num == 2 then
        local ta,tb = g.touchesArr[1],g.touchesArr[2]
        local sa,sb,ea,eb
        ea = --OrientationInverse(PORTRAIT,
            vec2(ta.touch.x,ta.touch.y)
        eb = --OrientationInverse(PORTRAIT,
            vec2(tb.touch.x,tb.touch.y)
        if ta.updated and ta.state ~= BEGAN then
            sa = --OrientationInverse(PORTRAIT,
            vec2(ta.touch.prevX,ta.touch.prevY)
        else
            sa = ea
        end
        if tb.updated and tb.state ~= BEGAN then
            sb = --OrientationInverse(PORTRAIT,
            vec2(tb.touch.prevX,tb.touch.prevY)
        else
            sb = eb
        end
        local o = vec2(self.x,self.y)
        local ang = (sb - sa):angleBetween(eb - ea)
        local sc = ((sb + sa)/2 - o):rotate(ang)
        local ec = (ea + eb)/2 - o
        self.angle = self.angle + math.deg(ang)
        self.anchor = nil
            self.opos = function() return self.x, self.y end
            self.x = self.x + ec.x - sc.x
            self.y = self.y + ec.y - sc.y
        end
    end
    g:noted()
    if g.type.ended and not g.type.tap then
        g:reset()
    end
end

function TextNode:processKey(k)
    if k == BACKSPACE then
        self:delChar()
    elseif k == RETURN then
        self:addChar(UTF8("\n"))
    else
        self:addChar(k)
    end
    return false
end

function TextNode:setEdit(e)
    if e == nil then
        e = not self.edit
    end
    if e then
        self.edit = true
        self.savecolour = self.colour
        self:setColour(Colour.opacity(Colour.svg.Black,50))
        self.ui:useKeyboard(self.keyboard,
                function(k) return self:processKey(k) end)
    else
        self.edit = false
        self:setColour(self.savecolour)
        self.ui:unuseKeyboard()
    end
end

if cmodule then
    return TextNode
else
    _G["TextNode"] = TextNode
end
