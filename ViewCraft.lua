-- View

--[[
The "View" class defines an object which handles positioning of
things in 3-dimensions and how they project to the 2-dimensional iPad
screen.  It handles transformations and certain other aspects that are
more to do with the surrounding View than a particular object in it.

In this class, the term "internal" refers to the 3-dimensional
representation of View.  The term "external" refers to things after
the projection to the plane of the iPad screen.
--]]

local View = class()

if cmodule then
    cimport "Coordinates"
    cimport "MathsUtilities"
    cimport "TouchUtilities"
    cimport "VecExt"
end

--[[
We need to know the user interface object as we want to have our own
menu for the user to choose various options.
--]] 

local function __quat(a,b,c,d)
    local q = quat()
    q.w = a
    q.x = b
    q.y = c
    q.z = d
    return q
end

function View:init(entity,ui,t,p)
    p = p or {}
    self.baseRotation = quat.angleAxis(0,vec3(1,0,0))
    self.orientRotation = __quat(1,0,0,0)
    self.intScale = 1
    self.extScale = 1
    self.fishEye = 1
    self.speed = 1/600
    self.origin = vec3(0,0,0)
    self.velocity = vec3(0,0,0)
    self.acceleration = 1
    self.friction = .2
    self.bgColour = color(0,0,0,255)
    self.eye = vec3(0,0,15)
    self.looking = -self.eye
    self.up = vec3(0,1,0)
    self.light = vec3(0,1,0)
    self.useGravity = true
    self.doTranslation = true
    self.rotation = self.baseRotation
    -- self.matrix = matrix()
    self.initials = {}
    self.ui = ui
    self.entity = entity
    self.camera = entity:get(craft.camera)
    for k,v in pairs(p) do
        self[k] = v
    end
    if self.useGravity then
        self.currentGravity = self.orientRotation:Gravity()
    else
        self.currentGravity = __quat(1,0,0,0)
    end

    if ui and Menu then
    local m = ui:addMenu({title = "View", attach = true})
    m:addItem({
        title = "Use Gravity",
        action = function()
            self:gravityOnOff()
            return true
        end,
        highlight = function()
            return self.useGravity
        end
    })
    ui:addHelp({title = "View", text = {"Instructions:",
    "Single tap: toggle the reaction to tilt",
    "Double tap: restore initial spatial settings",
    "Single swipe: rotate the object about an axis in the plane of the screen",
    "Double swipe: translate the object in 3-View",
    "Triple swipe: translate the projected image of the object",
    "Vertical pinch: scale the object in 3-View",
    "Horizontal pinch: scale the projected image"
    }}
    )
    end
    if t then
        t:pushHandler(self)
    end
    self:saveInitials()
end

--[[
Make sure we can get back to where we started.
--]]

function View:saveInitials()
    self.initials.baseRotation = self.baseRotation
    self.initials.intScale = self.intScale
    self.initials.extScale = self.extScale
    self.initials.origin = self.origin
    self.initials.eye = self.eye
    self.initials.currentGravity = self.currentGravity
    self.initials.fishEye = self.fishEye
    self.initials.light = self.light
end

--[[
Get us back to where we started.
--]]

function View:restoreInitials()
    self.baseRotation = self.initials.baseRotation
    self.intScale = self.initials.intScale
    self.extScale = self.initials.extScale
    self.origin = self.initials.origin
    self.eye = self.initials.eye
    self.currentGravity = self.initials.currentGravity
    self.fishEye = self.initials.fishEye
    self.light = self.initials.light
end

function View:reset()
    self:restoreInitials()
end

--[[
This is the main draw function.  It does not actually do much drawing
but rather sets up various things for use by other objects.
--]]

function View:update()
    self.orientRotation = quatRotationRate() * self.orientRotation 
    if self.angVelocity then
        if ElapsedTime - self.angvTime > 1 then
            self.angVelocity = nil
        else
            qa = self.angVelocity(ElapsedTime - self.angvTime)
            self.baseRotation = self.baseRotation * qa
        end
    end
    if self.doTranslation and self.moving then
        self.origin = self.origin + DeltaTime*self.velocity
    end
    local q = self.baseRotation * self:getGravity()
    local s = self.fishEye * self.intScale
    local o = self.origin
    local e = self.eye
    local up = self.up
    e = s*e^q + o
    up = up^q
    self.looking = o - e
    if self.moving then
        self.velocity = self.velocity 
                + DeltaTime * self.acceleration * (o-e)
                - DeltaTime * self.friction * self.velocity:len() * self.velocity
    end
    q = quat.lookRotation(o-e,up) --*__quat(1/math.sqrt(2),0,1/math.sqrt(2),0)
    self.entity.position = e
    self.entity.rotation = q
    -- self.entity.rotation = q:toquat()
    local fe = math.atan(self.fishEye)*180/math.pi

    self.camera.fieldOfView = fe
    if self.near then
        self.camera.nearPlane = self.near
        self.camera.farPlane = self.far        
    end

    -- self.matrix = q:tomatrix() * projectionMatrix()
end

--[[
If we are noticing gravity then this figures out the rotation defined
by our current gravity vector as a quatertion.
--]]

function View:getGravity()
    if self.useGravity then
        return self.currentGravity * self.orientRotation:Gravity()^""
    else
        return self.currentGravity
    end
end

--[[
This applies the current internal transformation to the given vector;
this is before stereographic projection has occured.
--]]

function View:applyIntTransformation(v)
    local q = self.baseRotation * self:getGravity()
    local s = self.fishEye * self.intScale
    local o = self.origin
    return s * (v^q + o)
end

function View:applyIntDirTransformation(v)
    local q = self.baseRotation * self:getGravity()
    local s = self.fishEye * self.intScale
    return s * v^q
end

function View:invertIntTransformation(v)
    local q = self.baseRotation * self:getGravity()
    local s = self.fishEye * self.intScale
    local o = self.origin
    q = q^""
    return (v / s - o)^q
end

function View:invertIntDirTransformation(v)
    local q = self.baseRotation * self:getGravity()
    local s = self.fishEye * self.intScale
    q = q^""
    return v^q / s
end

--[[
This applies the current external transformation to the given vector;
this is after stereographic projection has occured.
--]]

function View:applyExtTransformation(v)
    return (self.extScale/self.fishEye) * (v + self.extTranslate)
end

function View:applyExtDirTransformation(v)
    return (self.extScale/self.fishEye) * v
end

--[[
This projects the vector onto the screen, taking into account the
current internal and external transformations.
--]]

function View:Project(v)
    local u,w,r,l
    -- u = self.intScale * ((v + self.intTranslate)^self.rotation)
    u = self:applyIntTransformation(v)
        w = u + Vec3.e1
        w = w:stereoProject(self.eye) - u:stereoProject(self.eye)
        r = w:len()
        l = u:stereoLevel(self.eye)
        u = self:applyExtTransformation(u:stereoProject(self.eye))
        return {u,r,l,v:isInFront(self.eye)}
end

function View:ProjectDirection(v)
    local u
    u = self:applyIntDirTransformation(v)
    return u
end

--[[
This inverts the projection to the z-level of the second vector.
--]]

function View:invProject(v,w)
    local u,q,h
    u = v / self.extScale - self.extTranslate
    q = self.rotation -- is this right?
    w = self.intScale * (w^q + self.intTranslate)
    u = Vec3.stereoInvProject(u,self.eye,w.z)
    u = u / self.intScale - self.intTranslate
    q = q^""
    u = u^q
    return u
end

--[[
We should be pretty far down the "touch" queue so we take anything we
can.
--]]

function View:isTouchedBy(touch)
    return true
end

--[[
Our possible touches and their actions are:

Single tap: freeze or unfreeze the gravitational effect.

Double tap: restore stuff to initial conditions.

Single move: rotate View, if it is short then we carry on spinning
for a bit.

Pinch: scale View, either internally or externally

Double swipe: translate internally

Triple swipe: translate externally
--]]

function View:processTouches(g)
    if g.type.long and g.num == 1 then
        self:singleLongTap(g.touchesArr[1])
        if g.type.ended then
            g:reset()
        end
    elseif g.type.tap then
        if g.type.finished then
            if g.num == 1 then
                self:singleShortTap()
            elseif g.num == 2 then
                self:doubleTap()
            end
        end
    else
        if g.numactives == 1 then
            self:singleTouch(g.actives[1])
            if g.type.ended and g.type.short then
                 self:saveVelocity(g.actives[1])
            end
        elseif g.numactives == 2 then
            self:doubleTouch(g.actives[1],g.actives[2])
        elseif g.numactives == 3 then
            if not g.type.ViewTriple then
                g.type.ViewTripleType = self:isTriangle(
                    g.actives[1],
                    g.actives[2],
                    g.actives[3])
                g.type.ViewTriple = true
            end
            if g.type.ViewTripleType then
                self:triplePinch(
                    g.actives[1],
                    g.actives[2],
                    g.actives[3])
            else
                self:tripleSwipe(
                    g.actives[1],
                    g.actives[2],
                    g.actives[3])
            end
        end
        if g.type.ended then
            g:reset()
        end
    end
    g:noted()
    if g.type.finished then
        g:reset()
    end
end

--[[
Rotate View according to the movement, saving the velocity so that we
can carry on spinning for a bit if the total movement was short.
--]]

function View:singleTouch(thisTouch)
    local r,p,v,lp,lv,ox,oy,u,qa,qg,touch
    if not thisTouch.updated then
        return
    end
    touch = thisTouch.touch
    if touch.state == MOVING or touch.state == ENDED then
        r =RectAnchorOf(Screen,"width")/2
        ox,oy = RectAnchorOf(Screen,"centre")
        p = vec2(touch.prevX - ox,touch.prevY - oy)/r
        v = vec2(touch.x - ox,touch.y - oy)/r
        lv = v:lenSqr()
        lp = p:lenSqr()
        if lp > .9 or lv > .9 then
            return
        end
        p = vec3(p.x,p.y,math.sqrt(1 - lp))
        v = vec3(v.x,v.y,math.sqrt(1 - lv))
        qa = v:rotateTo(p)
        local b = SO3(self.eye,self.up)
        local qv = -qa.y*b[3] + qa.z*b[2] + qa.w*b[1]
        qa = __quat(qa.x,qv.x,qv.y,qv.z)
        qg = self:getGravity()
        self.baseRotation = self.baseRotation * qg * qa * qg^""
    end
end

function View:applyQuaternion(qa)
    local qg = self:getGravity()
    self.baseRotation = self.baseRotation * qg * qa * qg^""
end

--[[
Saves our velocity.
--]]

function View:saveVelocity(touch)
    local ft,t,dt,r,p,ox,oy,v,lp,lv,qa,qg
    ft = touch.firsttouch
    t = touch.touch
    dt = ElapsedTime - touch.createdat
    r = RectAnchorOf(Screen,"width")/2
    ox,oy = RectAnchorOf(Screen,"centre")
    p = vec2(ft.x - ox,ft.y - oy)/r
    v = vec2(t.x - ox,t.y - oy)/r
    v = p + (v-p)*2*DeltaTime/dt
    lp = p:lenSqr()
    lv = v:lenSqr()
    if lp < .9 and lv < .9 then
        -- raise both to sphere
        p = vec3(p.x,p.y,math.sqrt(1 - lp))
        v = vec3(v.x,v.y,math.sqrt(1 - lv))
        qa = v:rotateTo(p)
        local b = SO3(self.eye,self.up)
        local qv = -qa.y*b[3] + qa.z*b[2] + qa.w*b[1]
        qa = __quat(qa.x,qv.x,qv.y,qv.z)
        qg = self:getGravity()
        qa = qg * qa * qg^""
        self.angVelocity = qa:make_slerp(__quat(1,0,0,0))
        self.angvTime = ElapsedTime
        touch.container.interrupt = self
    end
end

--[[
This uses the "interrupt" feature of the touch controller so that if
we are rotating then the next touch stops us.
--]]

function View:interruption(t)
    if self.angVelocity then
        self.angVelocity = nil
        t.container.interrupt = nil
        return true
    else
        return false
    end
end

--[[
General handling of double touches
--]]

function View:doubleTouch(ta,tb)
    if not ta.updated and not tb.updated then
        return
    end
    local sa,sb,ea,eb,o,c,n,u,v,nml
    ea = vec2(ta.touch.x,ta.touch.y)
    eb = vec2(tb.touch.x,tb.touch.y)
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
    local ed = eb - ea
    local sd = sb - sa
    local el = ed:len()
    local sl = sd:len()
    local s = 1
    local theta = 0
    if sl > 0.001 and el > 0.001 then
        s = el/sl
        theta = ed:angleBetween(sd)
        if self.maxZoom then
            s = math.max(s,self.intScale/self.maxZoom)
        end
        if self.minZoom then
            s = math.min(s,self.intScale/self.minZoom)
        end
    end
    o = (eb + ea)/2

    c,nml = self.camera:screenToRay(o)
    u = nml:cross(self.up)
    v = u:cross(nml)
    o = self.origin
    c,n = self.camera:screenToRay(sa)
    sa = c + (o:dot(nml) - c:dot(nml))/n:dot(nml) * n
    c,n = self.camera:screenToRay(ea)
    ea = c + (o:dot(nml) - c:dot(nml))/n:dot(nml) * n
    c,n = self.camera:screenToRay(sb)
    sb = c + (o:dot(nml) - c:dot(nml))/n:dot(nml) * n
    c,n = self.camera:screenToRay(eb)
    eb = c + (o:dot(nml) - c:dot(nml))/n:dot(nml) * n
    
    ed = (eb + ea)/2
    sd = (sb + sa)/2
    local a = self.eye - ed
    a = a:normalize()
    local q = quat.angleAxis(theta,a)
    self.intScale = self.intScale / s
    local tr = ed - sd^q*s
    local qg = self:getGravity()
    local qa = qg * q * qg^""
    self.baseRotation = self.baseRotation * qa
    if self.doTranslation then
        self.origin = self.origin^qa - tr
    end
end
    



--[[
Triple touch handling - are the coordinates "triangular" or "linear"
--]]

function View:isTriangle(ta,tb,tc)
    local a = vec2(ta.touch.x,ta.touch.y)
    local b = vec2(tb.touch.x,tb.touch.y)
    local c = vec2(tc.touch.x,tc.touch.y)
    local phi = (b - a):angleBetween(c - a)
    local psi = (a - b):angleBetween(c - b)
    phi = phi - math.floor(phi/(2*math.pi))*2*math.pi
    if phi > math.pi then
        phi = 2*math.pi - phi
    end
    psi = psi - math.floor(psi/(2*math.pi))*2*math.pi
    if psi > math.pi then
        psi = 2*math.pi - psi
    end
    if phi > math.pi/2 
        or psi > math.pi/2 
        or phi + psi < math.pi/2
    then
        return false
    else
        return true
    end
end

--[[
A triple swipe to an external translation.
--]]

function View:tripleSwipe(ta,tb,tc)
    if not ta.updated and not tb.updated and not tc.updated then
        return
    end
    local ea,eb,ec,sa,sb,sc,ed,sd
    ea = vec2(ta.touch.x,ta.touch.y)
    eb = vec2(tb.touch.x,tb.touch.y)
    ec = vec2(tc.touch.x,tc.touch.y)
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
    if tc.updated then
        sc = vec2(tc.touch.prevX,tc.touch.prevY)
    else
        sc = ec
    end
    o = (ec + eb + ea)/2
    c,nml = self.camera:screenToRay(o)
    u = nml:cross(self.up)
    v = u:cross(nml)
    o = self.origin
    c,n = self.camera:screenToRay(sa)
    sa = c + (o:dot(nml) - c:dot(nml))/n:dot(nml) * n
    c,n = self.camera:screenToRay(ea)
    ea = c + (o:dot(nml) - c:dot(nml))/n:dot(nml) * n
    c,n = self.camera:screenToRay(sb)
    sb = c + (o:dot(nml) - c:dot(nml))/n:dot(nml) * n
    c,n = self.camera:screenToRay(eb)
    eb = c + (o:dot(nml) - c:dot(nml))/n:dot(nml) * n
    c,n = self.camera:screenToRay(sc)
    sc = c + (o:dot(nml) - c:dot(nml))/n:dot(nml) * n
    c,n = self.camera:screenToRay(ec)
    ec = c + (o:dot(nml) - c:dot(nml))/n:dot(nml) * n
    ed = (ec + eb + ea)/2
    sd = (sc + sb + sa)/2
    if self.doTranslation then
        self.origin = self.origin - ed + sd
    end
end

--[[
A triple pinch to alter the "fish eye" effect
--]]

function View:triplePinch(ta,tb,tc)
    local a = vec2(ta.touch.x,ta.touch.y)
    local b = vec2(tb.touch.x,tb.touch.y)
    local c = vec2(tc.touch.x,tc.touch.y)
    local pa,pb,pc
    if ta.updated then
        pa = vec2(ta.touch.prevX,ta.touch.prevY)
    else
        pa = a
    end
    if tb.updated then
        pb = vec2(tb.touch.prevX,tb.touch.prevY)
    else
        pb = b
    end
    if tc.updated then
        pc = vec2(tc.touch.prevX,tc.touch.prevY)
    else
        pc = c
    end
    local d = TriangleArea(a,b,c)
    local pd = TriangleArea(pa,pb,pc)
    self.fishEye = self.fishEye*(1+pd)/(1+d)
end

--[[
A single tap toggles the use of gravity.
--]]

function View:singleShortTap()
    self:gravityOnOff()
end

function View:singleLongTap(t)
    if t.touch.state == ENDED then
        self.moving = false
    else
        self.moving = true
    end
end

--[[
This is the actual toggle function.  As well as toggling the use, it
saves the current rotation so that the effect is to freeze the object.
--]]

function View:gravityOnOff()
    if self.useGravity then
        self.currentGravity = self:getGravity()
    else
        self.currentGravity = self.currentGravity * self.orientRotation:Gravity()
    end
    self.useGravity = not self.useGravity
end

--[[
This is the double tap function that calls the reset function.
--]]

function View:doubleTap()
    self:restoreInitials()
end

if cmodule then
    return View
else
    _G["ViewCraft"] = View
end
