--Project: Library Graphics
--Version: 2.4
--Dependencies:
--Tabs: ChangeLog Main Bezier Explosion Path TextNode View Zoom Layout
--Comments:

VERSION = "2.4"
clearProjectData()
-- DEBUG = true
-- Use this function to perform your initial setup
cmodule "Library Graphics"
cmodule.path("Library Base", "Library UI", "Library Utilities", "Library Maths")
Font,_,Textarea = unpack(cimport "Font",nil)
Colour = cimport "Colour"
cimport "ColourNames"
--[[
UTF8 = cimport "utf8"
cimport "Keyboard"
--cimport "RoundedRect"
cimport "ColourNames"
--]]
__cmodule = cmodule
cmodule = nil
function setup()
    if AutoGist then
        autogist = AutoGist("Library Graphics","A library of classes and functions relating to graphical things.",VERSION)
        autogist:backup(true)
    end
    if not __cmodule then
        openURL("http://loopspace.mathforge.org/discussion/36/my-codea-libraries")
        print("You need to enable the module loading mechanism.")
        print("See http://loopspace.mathforge.org/discussion/36/my-codea-libraries")
        print("Touch the screen to exit the program.")
        draw = function()
        end
        touched = function()
            close()
        end
        return
    end
    --displayMode(FULLSCREEN_NO_BUTTONS)
    cmodule = __cmodule

    cimport "TestSuite"
    local Touches = cimport "Touch"
    local UI = cimport "UI"
    local Debug = cimport "Debug"
    local Colour = cimport "Colour"
    local View = cimport "View"
    --[[
    local Explosion = cimport "Explosion"
    local TextNode = cimport "TextNode"

    local Zoom = cimport "Zoom"
    Bezier,BezierList = unpack(cimport "Bezier")
    Arc,ArcList = unpack(cimport "Arc")
    --]]
    touches = Touches()
    touches:showTouches(true)
    ui = UI(touches)

    debug = Debug({ui = ui})
    ui:systemmenu()
    testsuite.initialise({ui = ui})

    debug:log({
        name = "Screen north west",
        message = function() local x,y = RectAnchorOf(Screen,"north west") return x .. ", " .. y end
    })
    --debug:activate()

    tn = TextNode({
        pos = function() return WIDTH/2,800 end,
        anchor = "centre",
        --angle = 30,
        ui = ui,
        fit = true,
        maxHeight = HEIGHT,
    })


    touches:pushHandler(tn)

    view = View(ui,touches)
    zoom = Zoom(touches)
    parameter.watch("view.baseRotation")

    shape = mesh()
    

    local x,y,z = 1,1,1
    shape.vertices = {
        vec3(x,0,0),
        vec3(0,y,0),
        vec3(0,0,z),
        vec3(0,0,0),
        vec3(0,y,0),
        vec3(0,0,z),
        vec3(x,0,0),
        vec3(0,0,0),
        vec3(0,0,z),
        vec3(x,0,0),
        vec3(0,y,0),
        vec3(0,0,0)
    }
    shape.colors = {
        Colour.svg.Red,
        Colour.svg.Green,
        Colour.svg.Blue,
        Colour.svg.White,
        Colour.svg.Green,
        Colour.svg.Blue,
        Colour.svg.Red,
        Colour.svg.White,
        Colour.svg.Blue,
        Colour.svg.Red,
        Colour.svg.Green,
        Colour.svg.White
    }

    --[[
    view.eye = vec3(5,0,0)
    view.range = .25

      ]]
    tw = {t = 0,s=0}
    ui:setTimer(5,function() tween(5,tw,{t = 1,s = 0}) return true end)
    ui:setTimer(12,function() tween(5,tw,{t = 1,s = 1}) return true end)
    ui:setTimer(18,function() tw = {t = 0,s = 1} return true end)
    ui:setTimer(19,function() tween(5,tw,{t = 1,s = 0}) return true end)

    explosion = Explosion({
        image = "Cargo Bot:Codea Icon",
        trails = true,
        centre = vec2(WIDTH/2,HEIGHT/2)
    })
    explosion:activate(5,15)
    --ui:addNotice({text = "Watch carefully"})

    strokeWidth(5)
    stroke(255, 0, 0, 255)
    --[[
    ncurves = {}
    local b
    blist = BezierList()
    for k=1,1000 do
        b = Bezier(vec2(100,100),
                    vec2(100,200),
                    vec2(200,100),
                    vec2(200,200)
                    )
        b:makeDrawable()
        table.insert(ncurves,b)
        --blist:addBezier(b)
    end
    --]]
    narcs = {}
    local b
    alist = ArcList()
    for k=1,10 do
        b = Arc(vec2(WIDTH/2,HEIGHT/2),
                    vec2(100,0),
                    vec2(0,100),
                    0,
                    math.rad(100)
                    )
        b:makeDrawable()
        table.insert(narcs,b)
        alist:addArc(b)
    end
    fps = {}
    for k=1,20 do
        table.insert(fps,1/60)
    end
    afps = 60
    parameter.watch("math.floor(20/afps)")
    --displayMode(FULLSCREEN)
    local width = 10

    pts = {vec2(width/2,0),
        vec2(width/2,3*HEIGHT-width/2),
        vec2(WIDTH - width/2,-2*HEIGHT+width/2),
        vec2(WIDTH - width/2,HEIGHT)}
    bpts = Bezier(pts)
    bpts:setStyle({
        scolour = color(171, 166, 23, 255),
        ecolour = color(84, 219, 231, 255)
    })
    --[[
    vcurves = {}
    local n = 200
    for k=1,n do
        table.insert(vcurves,{
            function(t) return vec2(0,HEIGHT*(1+math.sin(t + 2*math.pi*k/n))/2) end,
            function(t) return vec2(WIDTH/3,HEIGHT*(1+math.sin(t + 2*math.pi*(k+1)/n))/2) end,
            function(t) return vec2(2*WIDTH/3,HEIGHT*(1+math.sin(t + 2*math.pi*(k+2)/n))/2) end,
            function(t) return vec2(WIDTH,HEIGHT*(1+math.sin(t + 2*math.pi*(k+3)/n))/2) end
                })
    end
    --]]
    parameter.watch("math.floor(20/afps)")
    curves = {}
    hcurves = {}
    parameter.watch("#curves")
    --parameter.watch("#ncurves")
    tpts = {}
    cpts = {}
    bezierlist = BezierList()

    print(SQUARE)
    print(PROJECT)
    print(ROUND)
    parameter.watch("zoom.ll")
    shape = mesh()
    shape.shader = lighting()
    shape.shader.light = vec3(1,1,1):normalize()
    shape.shader.ambient = .5
    shape.shader.useTexture = 0
    local number = 4
    shape:addCylinder({
                centre = vec3(0,-1,0),
                height = 2,
                radius = 1,
                startAngle = 180,
                deltaAngle = 90,
    faceted = false,
                size = number
    })
    shape:addCylinder({
                centre = vec3(0,1,0),
                height = 2,
                radius = 1,
    faceted = false,
                size = 4*number
    })
    hpts = {
        vec2(300,200),
        vec2(400,300),
        vec2(200,500),
        vec2(200,100)
    }
    hcurves = Hobby(hpts,{closed = true})
    local cpts = {}
    for k,v in ipairs(hpts) do
        table.insert(cpts,v)
    end
    table.insert(cpts,hpts[1])
    table.insert(cpts,hpts[2])
    ccurves = Hobby(cpts)
    sc = Bezier(vec2(100,700),vec2(200,800),vec2(300,700),vec2(200,700))
    parameter.number("splitpt",0,1,.3)
end

function draw()
    touches:draw()
    background(75, 104, 90, 255)
    strokeWidth(4)
    for k,v in ipairs(hcurves) do
        v:draw()
    end
    strokeWidth(2)
    stroke(0, 0, 0, 255)
    for k,v in ipairs(ccurves) do
        v:draw()
    end
    noStroke()
    fill(0, 242, 255, 255)
    for k,v in ipairs(hpts) do
        ellipse(v.x,v.y,5)
    end
    strokeWidth(4)
    stroke(0, 4, 255, 255)
    sc:draw()
    strokeWidth(2)
    sca,scb = sc:split(splitpt)
    stroke(255, 234, 0, 255)
    sca:draw()
    stroke(0, 217, 255, 255)
    scb:draw()
    --[==[
    table.remove(fps,1)
    table.insert(fps,DeltaTime)
    afps = 0
    for k,v in ipairs(fps) do
        afps = afps + v
    end

    -- zoom:draw()
    rectMode(CORNER)
    fill(119, 84, 84, 255)
    rect(0,0,WIDTH,HEIGHT)
    --[[
    strokeWidth(5)

    stroke(151, 115, 115, 255)
    for i=1,3 do
        line(pts[i].x,pts[i].y,pts[i+1].x,pts[i+1].y)
    end
    fill(160, 172, 22, 255)
    noStroke()
    for i = 1,4 do
        ellipse(pts[i].x,pts[i].y,20)
    end
    --]]
    strokeWidth(5)
    stroke(255, 255, 255, 255)
    for k,v in ipairs(narcs) do
        -- v:draw()
        -- arc(v.params)
    end
    alist:draw()
    --bezier(pts)
    --[=[
    bpts:draw()
    stroke(81, 255, 0, 255)
    bezier(vec2(10,10),vec2(WIDTH/2,2*HEIGHT-20),vec2(WIDTH-10,10))
    for k,v in ipairs(curves) do
        --v:draw()
    end
    stroke(0, 0, 0, 255)
    strokeWidth(3)
    for k,v in ipairs(hcurves) do
        v:draw()
    end
    bezierlist:draw()
    noStroke()
    for k,v in ipairs(cpts) do
        ellipse(v.x,v.y,15)
    end

    noSmooth()
    smooth()
    strokeWidth(50)
    lineCapMode(ROUND)
    stroke(255, 255, 255, 255)
    --line(0,HEIGHT/2,100,HEIGHT/2)
    --stroke(0, 27, 255, 255)
    bezier(vec2(200,HEIGHT/2),vec2(300,HEIGHT/2))
    strokeWidth(5)
    stroke(240, 4, 4, 255)
    --bezier(vec2(200,HEIGHT/2-100),vec2(200,HEIGHT/2+100))
    --bezier(vec2(300,HEIGHT/2-100),vec2(300,HEIGHT/2+100))
    bezier(vec2(200,200),vec2(300,300),vec2(400,200))
    stroke(0, 0, 0, 255)
    bezier(vec2(200,HEIGHT/2),vec2(300,HEIGHT/2))

    --[[
    for _,v in ipairs(vcurves) do
        bezier({v[1](ElapsedTime),v[2](ElapsedTime),v[3](ElapsedTime),v[4](ElapsedTime)})
    end
    --]]
    touches:show()
    --]=]
    explosion:draw()
    resetMatrix()
    viewMatrix(matrix())
    ortho()
    --]==]
    --[[
    view:draw()
    shape.shader.invModel = viewMatrix()
    shape:draw()
    --]]
    
end
--[=[
function touched(touch)
    local tv = vec2(touch.x,touch.y)
    if touch.state == BEGAN then
        mpoint = nil
        for k,v in ipairs(cpts) do
            if v:distSqr(tv) < 900 then
                mpoint = k
            end
        end
        if not mpoint then
        table.insert(tpts,vec2(touch.x,touch.y))
        table.insert(cpts,vec2(touch.x,touch.y))
        if #tpts == 3 then
            local a,b,aa,bb
            a,b,th = QuickHobby(tpts,th)
            aa = a:clone()
            bb = b:clone()
            aa:setStyle({width = 8, colour = color(75, 104, 90, 255)})
            bb:setStyle({width = 8, colour = color(75, 104, 90, 255)})
            table.remove(curves)
            table.remove(curves)
            table.insert(curves,aa)
            table.insert(curves,a)
            table.insert(curves,bb)
            table.insert(curves,b)
            table.remove(tpts,1)
            bezierlist:updateBezier(a,blist[1],blist[2]-1)
            blist = bezierlist:addBezier(b)
        elseif #tpts == 2 then
            cvs = QHobby(tpts)
            curves = {}
            for _,v in ipairs(cvs) do
                vv = v:clone()
                vv:setStyle({width = 8, colour = color(75, 104, 90, 255)})
                table.insert(curves,vv)
                table.insert(curves,v)
                blist = bezierlist:addBezier(v)
            end
        end
        end
    elseif mpoint then
        cpts[mpoint] = tv
        if mpoint == #cpts then
            tpts[#tpts] = tv
        elseif mpoint == #cpts - 1 then
            tpts[1] = tv
        end
    end
    if touch.state == ENDED then
        --if #cpts > 2 then
            hcurves = Hobby(cpts)
        --end
        if mpoint then
            local cvs,vv
            cvs, th = QHobby(cpts)
            curves = {}
            for _,v in ipairs(cvs) do
                vv = v:clone()
                vv:setStyle({width = 8, colour = color(75, 104, 90, 255)})
                table.insert(curves,vv)
                table.insert(curves,v)
            end
        end
    end
end

-- This function gets called once every frame
function draw()
    -- process touches and taps
    table.remove(fps,1)
    table.insert(fps,DeltaTime)
    afps = 0
    for k,v in ipairs(fps) do
        afps = afps + v
    end
    touches:draw()
    background(34, 47, 53, 255)
    tn:draw()
    pushMatrix()
    view:draw()
    vm = viewMatrix()
    --[[
    qt = qslp(tw.t)
    qt = qt*qlp(tw.s)
    modelMatrix(qt:tomatrix())
    perspective(40,WIDTH/HEIGHT)
    camera(10,10,10,0,0,0,0,1,0)
    --]]
    shape:draw()
    popMatrix()
    resetMatrix()
    viewMatrix(matrix())
    ortho()
    strokeWidth(5)
    stroke(255, 0, 0, 255)
    for k,v in ipairs(curves) do
        v:draw()
    end
    explosion:draw()
    ui:draw()
    debug:draw()
    touches:show()
end
--]=]
function touched(touch)
    touches:addTouch(touch)
end

function orientationChanged(o)
    if ui then
         ui:orientationChanged(o)
    end
end

function fullscreen()
end

function reset()
end
