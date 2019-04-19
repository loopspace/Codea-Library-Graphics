-- Snowfall

local potshader

if cmodule then
    cimport "Bezier"
end

Snowfall = class()
function Snowfall:init(w,h,s)
    w = w or WIDTH
    h = h or HEIGHT
    s = s or 1
    self.w = w
    self.h = h
    self.speed =s
    local ptpx = ContentScaleFactor
    local size = ptpx*vec2(w,h)
    local deltaX = 1
    local bdry = 2/ptpx -- twice boundary width
    local div = mesh()
    div:addRect(w/2,h/2,w,h)
    local cs = shader()
    cs.vertexProgram,cs.fragmentProgram = potshader("u = 0.; v = -3.;")
    local fs = shader()
    fs.vertexProgram,fs.fragmentProgram = potshader("u = -10.*y; v = -50.+10.*x;")
    local vs = shader()
    vs.vertexProgram,vs.fragmentProgram = potshader(
        --"float l = length(vec2(x,y)); l = l * l; u = x + x/l + .5; v = y - y/l + .5;"
        --"u = 10.*cos((x+y)*3.1415*10.); v = -50.+  sin((x-y)*3.1415*10.);"
        "float l = length(vec2(x,y)); u = max(1.-2.*l,0.)*(-10.*y/l); v = -3. + max(1.-2.*l,0.)*10.*x/l;"
    )
    local tempa = image(w,h)
    setContext(tempa)
    div.shader = cs
    div:draw()
    setContext()
    local tempb = image(w,h)
    setContext(tempb)
    div.shader = vs
    div:draw()
    setContext()
    local tempc = image(w,h)
    vs = shader()
    vs.vertexProgram,vs.fragmentProgram = potshader(
        "float l = 1.4*length(vec2(x,y)); l = l * l * l * l; u = -50.*(1. - (x*x - y*y)/l); v = 50.*2.*x*y/l;"
    )
    setContext(tempc)
    div.shader = vs
    div:draw()
    setContext()
    local affine = mesh()
    affine:addRect(w/2,h/2,w,h)
    affine.shader = cimport "Affine"() --shader("Documents:Affine")
    affine.shader.texture1 = tempa
    affine.shader.texture2 = tempb
    affine.shader.texture3 = tempc
    affine.shader.weight = {0,1,0,0,0,0,0,0}
    self.velocity_src = image(w,h)
    self.velocity = image(w,h)
    setContext(self.velocity_src)
    affine:draw()
    setContext()
    self.swirls = {}
    self.vpt = function() return vec2(math.random(0,w),math.random(0,h)) end
    local vn, vcgen, vcpath
    for k=1,3 do
        vn = vec2(w/2,h/2) + self.vpt()
        vcgen = QHobbyGenerator(vec2(w/2,h/2),vn)
        vn = vn + self.vpt()
        vcpath = vcgen(vn)
        table.insert(self.swirls,{
            generator = vcgen,
            path = vcpath,
            time = 0,
            img = image(w,h)
        })
    end
    self.vaffine = mesh()
    self.vaffine:addRect(w/2,h/2,w,h)
    self.vaffine.shader = cimport "Affine"() -- shader(velshader())
    self.vaffine.shader.texture1 = self.swirls[1].img
    self.vaffine.shader.texture2 = self.swirls[2].img
    self.vaffine.shader.texture3 = self.swirls[3].img
    self.vaffine.shader.texture4 = tempa
    self.vaffine.shader.weight = {1,1,0,-1,0,0,0,0}

    self.advect = mesh()
    self.advect:addRect(w/2,h/2,w,h)
    self.advect.shader = cimport "Advect"() --shader("Documents:Advect")
    self.advect.shader.size = size
    self.advect.shader.deltaX = deltaX
    self.dye = image(w,h)
    self.temp = image(w,h)
    --drop_dye()

    self.render = mesh()
    self.render:addRect(w/2,h/2,w,h)
    self.render.shader = shader("Filters:Blur")
    self.render.shader.conWeight = 1/9
    self.render.shader.conPixel = 2*vec2(1/size.x,1/size.y)
    self.falling = true

end

function Snowfall:draw()
    pushMatrix()
    pushStyle()
    blendMode(NORMAL)
    if self.falling then
        self:drop_dye()
    end
    self:adjust_velocity()
    self:do_advect()
    translate(self.w/2,self.h/2)
    scale(1.1)
    translate(-self.w/2,-self.h/2)
    self.render.texture = self.dye
    blendMode(SRC_ALPHA,ONE)
    self.render:draw()
    popStyle()
    popMatrix()
end

function Snowfall:update()
    pushMatrix()
    pushStyle()
    blendMode(NORMAL)
    if self.falling then
        self:drop_dye()
    end
    self:adjust_velocity()
    self:do_advect()
    self.render.texture = self.dye
    popStyle()
    popMatrix()
end

function Snowfall:redraw(b)
    pushMatrix()
    pushStyle()
    translate(self.w/2,self.h/2)
    scale(1.1)
    translate(-self.w/2,-self.h/2)
    if b ~= false then
        blendMode(SRC_ALPHA,ONE)
    end
    self.render:draw()
    popStyle()
    popMatrix()
end

function Snowfall:adjust_velocity()
    local w,h = self.w,self.h
    local vpos, vtgt
    for k,v in ipairs(self.swirls) do
        vpos = v.path:point(v.time)
        vtgt = v.path:tangent(v.time)
        v.time = v.time + DeltaTime/vtgt:len()*500
        if v.time > 1 then
            local vn = vpos + self.vpt()
            v.path = v.generator(vn)
            v.time = 0
        end
        vpos.x = vpos.x%w
        vpos.y = vpos.y%h
        setContext(v.img)
        background(0,0,0,0)
        pushStyle()
        -- blendMode(MULTIPLY)
        spriteMode(CORNER)
        pushMatrix()

        translate(vpos:unpack())
        scale((-1)^k,1,1)
        sprite(self.velocity_src)
        translate(-w,0)
        sprite(self.velocity_src)
        translate(0,-h)
        sprite(self.velocity_src)
        translate(w,0)
        sprite(self.velocity_src)
        popMatrix()
        popStyle()
        setContext()
    end
    setContext(self.velocity)
    background(0,0,0,0)

    self.vaffine:draw()
    setContext()
end

function Snowfall:do_advect()
    local w,h = self.w,self.h    
    noSmooth()
    pushStyle()
    setContext(self.temp)
    background(0, 0, 0, 0)
    self.advect.shader.deltaTime = 1*self.speed
    self.advect.shader.velocity = self.velocity
    self.advect.shader.quantity = self.dye
    self.advect:draw()
    blendMode(ONE,ZERO,ONE,ZERO)
    stroke(0,0,0,0)
    strokeWidth(1)
    line(0,0,w,0)
    line(w,0,w,h)
    line(w,h,0,h)
    line(0,h,0,0)
    popStyle()
    setContext()
    self.dye,self.temp = self.temp,self.dye
end

function Snowfall:drop_dye()
    blendMode(NORMAL)
    setContext(self.dye)
    fill(255, 255, 255, 255)
    stroke(fill())
    noSmooth()
    local x = math.random(15,self.w-15)
    local y = self.h-10
    ellipse(x,y,math.random(5,10),math.random(5,10))
    setContext()
    blendMode(NORMAL)
end

function potshader(s)
    return [[
//
// A basic vertex shader
//

//This is the current model * view * projection matrix
// Codea sets it automatically
uniform mat4 modelViewProjection;

//This is the current mesh vertex position, color and tex coord
// Set automatically
attribute vec4 position;
attribute vec4 color;
attribute vec2 texCoord;

//This is an output variable that will be passed to the fragment shader
varying lowp vec4 vColor;
varying highp vec2 vTexCoord;

void main()
{
    //Pass the mesh color to the fragment shader
    vColor = color;
    vTexCoord = texCoord;
    
    //Multiply the vertex position by our combined transform
    gl_Position = modelViewProjection * position;
}
]],[[
//
// A basic fragment shader
//

//Default precision qualifier
precision highp float;

//This represents the current texture on the mesh
uniform lowp sampler2D texture;
uniform vec2 size;
vec2 gr = 1./size;
highp float pi = 3.1415826538979323846;
//The interpolated vertex color for this fragment
varying lowp vec4 vColor;

//The interpolated texture coordinate for this fragment
varying highp vec2 vTexCoord;

void main()
{
    float x = 2.*vTexCoord.x - 1.;
    float y = 2.*vTexCoord.y - 1.;
    highp float u;
    highp float v;
    lowp vec4 col = vec4(0.,0.,0.,1.);
]] .. s .. [[
    col.x = atan(u)/(2.*pi) + .5;
    col.y = atan(v)/(2.*pi) + .5;
    //Set the output color to the texture color
    gl_FragColor = col;
}
]]
end

if cmodule then
    return Snowfall
else
    _G["Snowfall"] = Snowfall
end