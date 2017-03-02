-- Bezier path drawing

local Bezier = class()
local m
local __makeBezier = function(nsteps)
    -- nsteps doesn't make a huge difference in the range 50,300
    nsteps = nsteps or 150
    local m = mesh()
    m.shader = shader([[
//
// A basic vertex shader
//

//This is the current model * view * projection matrix
// Codea sets it automatically
uniform mat4 modelViewProjection;
uniform lowp vec4 scolour;
uniform lowp vec4 ecolour;
lowp vec4 mcolour = ecolour - scolour;
//This is the current mesh vertex position, color and tex coord
// Set automatically
attribute vec4 position;
attribute vec4 color;
attribute vec2 texCoord;

varying highp vec2 vTexCoord;
varying lowp vec4 vColour;
varying highp float vWidth;
varying highp float vCore;

uniform float width;
uniform float taper;
uniform float blur;
uniform float cap;
uniform float scap;
uniform float ecap;
float swidth = width + blur;
float ewidth = taper*width - width;
float ecapsw = clamp(cap,0.,1.)*ecap;
float scapsw = clamp(cap,0.,1.)*scap;
uniform vec2 pts[4];

void main()
{
    highp float t = clamp(position.y,0.,1.);
    vCore = t;
    highp float w = smoothstep(0.,1.,t);
    vWidth = w*ewidth + swidth;
    highp float tt = 1.0 - t;
    highp vec2 bpos = tt*tt*tt*pts[0] + 3.0*tt*tt*t*pts[1] 
    + 3.0*tt*t*t*pts[2] + t*t*t*pts[3];
    highp vec2 bdir = tt*tt*(pts[1]-pts[0])
         + 2.0*tt*t*(pts[2]-pts[1]) + t*t*(pts[3]-pts[2]);
    bdir = vec2(bdir.y,-bdir.x);
    bdir = vWidth*normalize(bdir);
    bpos = bpos + position.x*bdir;
    highp vec4 bzpos = vec4(bpos.x,bpos.y,0.,1.);
    bzpos.xy += (ecapsw*max(position.y-1.,0.)
                +scapsw*min(position.y,0.))*vec2(-bdir.y,bdir.x);
    highp float s = clamp(position.y, 
            scapsw*position.y,1.+ecapsw*(position.y-1.));
    vTexCoord = vec2(texCoord.x,s);
    vColour = t*mcolour + scolour;
    //Multiply the vertex position by our combined transform
    gl_Position = modelViewProjection * bzpos;
}
]],[[
//
// A basic fragment shader
//

uniform highp float blur;
uniform highp float cap;

varying highp vec2 vTexCoord;
varying highp float vWidth;
varying lowp vec4 vColour;
varying highp float vCore;

void main()
{
    lowp vec4 col = vColour;
    highp float edge = blur/(vWidth+blur);
    col.a = mix( 0., col.a, 
            (2.-cap)*smoothstep( 0., edge, 
                min(vTexCoord.x,1. - vTexCoord.x) )
            * smoothstep( 0., edge, 
                min(1.5-vTexCoord.y, .5+vTexCoord.y) ) 
            + (cap - 1.)*smoothstep( 0., edge,
             .5-length(vTexCoord - vec2(.5,vCore)))
                );

    gl_FragColor = col;
}
]])

    for n=1,nsteps do
        m:addRect(0,(n-.5)/nsteps,1,1/nsteps)
    end
    m:addRect(0,1.25,1,.5)
    m:addRect(0,-.25,1,.5)
    m.shader.blur = 2
    m.shader.cap = 2
    m.shader.scap = 1
    m.shader.ecap = 1
    return m
end

function bezier(...)
    m = __makeBezier()
    __bezier(...)
    bezier = __bezier
end

function __bezier(a,b,c,d,e)
    if type(a) == "table" then
        e = b
        a,b,c,d = unpack(a)
    end
    if type(c) ~= "userdata" then
        e = e or c
        d = b
        b = 2*a/3 + d/3
        c = a/3 + 2*d/3
    elseif type(d) ~= "userdata" then
        e = e or d
        d = c
        b = 2*b/3
        c = b + d/3
        b = b + a/3
    end
    --m.shader.blur = 15
    m.shader.taper = e or 1
    m.shader.width = strokeWidth()
    m.shader.scolour = color(stroke())
    m.shader.ecolour = color(stroke())
    m.shader.cap = (lineCapMode()-1)%3
    m.shader.pts = {a,b,c,d}
    m:draw()
end

function Bezier:init(...)
    self:setPoints(...)
end

function Bezier:clone()
    return Bezier(self.points)
end

function Bezier:makeDrawable(t)
    t = t or {}
    local nsteps = t.steps or self.steps
    local m = __makeBezier(nsteps)
    m.shader.taper = t.taper or self.taper or 1
    m.shader.blur = t.blur or self.blur or 2
    m.shader.cap = t.cap or self.cap or (lineCapMode()-1)%3
    m.shader.scap = t.scap or self.scap or 1
    m.shader.ecap = t.ecap or self.ecap or 1
    m.shader.width = t.width or self.width or strokeWidth()
    m.shader.scolour = t.scolour or self.scolour or t.colour or color(stroke())
    m.shader.ecolour = t.ecolour or self.ecolour or t.colour or color(stroke())
    m.shader.pts = self.points
    self.curve = m
    self.draw = function(self) self.curve:draw() end
end

function Bezier:draw(t)
    self:makeDrawable(t)
    self.curve:draw()
end

function Bezier:setPoints(a,b,c,d)
    if type(a) == "table" and a.is_a and a:is_a(Bezier) then
        a = a.points
    end
    if type(a) == "table" then
        a,b,c,d = unpack(a)
    end
    if not c then
        d = b
        b = 2*a/3 + d/3
        c = a/3 + 2*d/3
    elseif not d then
        d = c
        b = 2*b/3
        c = b + d/3
        b = b + a/3
    elseif type(b) == "number" then
        a,b,c,d = __hobby(a,b,c,d)
    end
    self.points = {a,b,c,d}
    if self.curve then
        self.curve.shader.pts = self.points
    end
end

function Bezier:setStyle(t)
    self.scolour = t.scolour or t.colour or self.scolour
    self.ecolour = t.ecolour or t.colour or self.ecolour
    self.width = t.width or self.width
    self.taper = t.taper or self.taper
    self.blur = t.blur or self.blur
    self.cap = t.cap or self.cap
    self.scap = t.scap or self.scap
    self.ecap = t.ecap or self.ecap
    if not self.curve then 
        return
    end
    t = t or {}
    if t.colour then
        self.curve.shader.scolour = t.colour
        self.curve.shader.ecolour = t.colour
    end
    if t.scolour then
        self.curve.shader.scolour = t.scolour
    end
    if t.ecolour then
        self.curve.shader.ecolour = t.ecolour
    end
    if t.width then
        self.curve.shader.width = t.width
    end
    if t.taper then
        self.curve.shader.taper = t.taper
    end
    if t.blur then
        self.curve.shader.blur = t.blur
    end
    if t.cap then
        self.curve.shader.cap = t.cap
    end
    if t.scap then
        self.curve.shader.scap = t.scap
    end
    if t.ecap then
        self.curve.shader.ecap = t.ecap
    end
end

function Bezier:point(t)
    local s = 1 - t
    return s^3 * self.points[1]
        + 3*s*s*t * self.points[2]
        + 3*s*t*t * self.points[3]
        + t^3 * self.points[4]
end

function Bezier:split(t)
    t = math.min(1,math.max(0,t))
    local s = 1 - t
    local apts,bpts = {},{}
    apts[1] = self.points[1]
    apts[2] = t*(self.points[2] - self.points[1]) + self.points[1]
    apts[3] = -t*self:tangent(t)/3 + self:point(t)
    apts[4] = self:point(t)
    bpts[1] = self:point(t)
    bpts[2] = s*self:tangent(t)/3 + self:point(t)
    bpts[3] = s*(self.points[3] - self.points[4]) + self.points[4]
    bpts[4] = self.points[4]
    return Bezier(apts), Bezier(bpts)
end

function Bezier:tangent(t)
    local s = 1 - t
    return 3*s^2 * (self.points[2] - self.points[1])
        + 6*s*t * (self.points[3] - self.points[2])
        + 3*t^2 * (self.points[4] - self.points[3])
end

function Bezier:normal(t)
    return self:tangent(t):rotate90()
end

function Bezier:unitNormal(t)
    local pt = self:normal(t)
    local l = pt:len()
    if l == 0 then
        return vec2(0,0)
    else
        return pt/l
    end
end

function Bezier:unitTangent(t)
    local pt = self:tangent(t)
    local l = pt:len()
    if l == 0 then
        return vec2(0,0)
    else
        return pt/l
    end
end

local ha = math.sqrt(2)
local hb = 1/16
local hc = (3 - math.sqrt(5))/2
local hd = 1 - hc
local function __hobby(a,tha,phb,b)
    local c = b - a
    local sth = math.sin(tha)
    local cth = math.cos(tha)
    local sph = math.sin(phb)
    local cph = math.cos(phb)
    local alpha = ha * (sth - hb * sph) * (sph - hb * sth) * (cth - cph)
    local rho = (2 + alpha)/(1 + hd * cth + hc * cph)
    local sigma = (2 - alpha)/(1 + hd * cph + hc * cth)
    return a,a + rho*c:rotate(tha)/3, b - sigma*c:rotate(-phb)/3,b
end

local function QuickHobby(a,b,c,tha)
    if type(a) == "table" then
        tha = b
        a,b,c = unpack(a)
    end
    local da = a:dist(b)
    local db = b:dist(c)
    local wa = vec2(1,0):angleBetween(b-a)
    local wb = vec2(1,0):angleBetween(c-b)
    local psi = wb - wa
    if psi > math.pi then
        psi = psi - 2*math.pi
    end
    if psi <= -math.pi then
        psi = psi + 2*math.pi
    end
    local thb,phb,phc
    if tha then
        thb = -(2*psi + tha) * db / (2*db + da)
        phb = - psi - thb
        phc = thb
    else
        thb = - psi * db / (da + db)
        tha = - psi - thb
        phb = tha
        phc = thb
    end
    return Bezier(__hobby(a,tha,phb,b)),Bezier(__hobby(b,thb,phc,c)),thb
end

local function QHobbyGenerator(a,b)
    local th
    return function(c)
        local p,q
        p,q,th = QuickHobby(a,b,c,th)
        a = b
        b = c
        return p,q
    end
end

local function QHobby(pts,th)
    local n = #pts
    if n == 1 then
        return {}
    end
    if n == 2 then
        th = th or 0
        return {Bezier(pts[1], th, -th, pts[2] )},th
    end
    local a,b = pts[1],pts[2]
    local p,q
    local cvs = {}
    for k=3,n do
        p,q,th = QuickHobby(pts[k-2],pts[k-1],pts[k],th)
        table.insert(cvs,p)
    end
    table.insert(cvs,q)
    return cvs,th
end

local function __makeHobby(pts,fn,extra)
    local z = {}
    local d = {}
    local u = {}
    local v = {}
    local omega = {}
    local psi = {}
    local it = {}
    local ot = {}
    local n = -1
    local A = {}
    local B = {}
    local C = {}
    local D = {}
    local icurl = 1
    local ocurl = 1
    local theta = {}
    local phi = {}
    local rho ={}
    local sigma = {}
    local a = math.sqrt(2)
    local b = 1/16
    local c = (3 - math.sqrt(5))/2
    local cpta = {}
    local cptb = {}
    local dten = 1
    local curves = {}
    local closed = false
    if extra then
        dten = extra.tension or 1
        icurl = extra.inCurl or 1
        ocurl = extra.outCurl or 1
        closed = extra.closed
    end

    for _,t in ipairs(pts) do
        n = n + 1
        if type(t) == "table" then
            z[n] = t[1]
            it[n] = t[2] or dten
            ot[n] = t[3] or dten
        else
            z[n] = t
            it[n] = dten
            ot[n] = dten
        end
    end
    if n < 1 then
        return {}
    end
    if closed then
        if z[n] ~= z[0] then
            n = n + 1
            z[n] = z[0]
            it[n] = it[0]
            ot[n] = ot[0]
        end
        n = n + 1
        z[n] = z[1]
        it[n] = it[1]
        ot[n] = ot[1]
    end
    if n == 1 then
        local th,ph
        if extra then
            th = extra.inAngle
            ph = extra.outAngle
        end
        if not th and ph then
            th = -ph
        elseif not ph and th then
            ph = - th
        elseif not th and not ph then
            ph,th = 0,0
        end
        return {fn(__hobby(z[0],th,ph,z[1]))}
    end
    local ang
    for k=0,n-1 do
        d[k] = z[k]:dist(z[k+1])
        omega[k] = vec2(1,0):angleBetween(z[k+1]-z[k])
        if k > 0 then
          ang = omega[k] - omega[k-1]
           if ang > math.pi then
             ang = ang - 2*math.pi
            end
            if ang < -math.pi then
                ang = ang + 2*math.pi
             end
          psi[k] = ang
       end
    end

    if extra then
        theta[0] = extra.inAngle
        phi[n] = extra.outAngle
    end

   for k=1,n-1 do
      A[k] = d[k] * it[k+1] * it[k]^2
   end

   if theta[0] or closed then
      B[0] = 1
   else
      B[0] = ot[0]^3 * (3 * it[1] - 1) + icurl * it[1]^3
   end
   for k = 1,n-2 do
      B[k] = d[k] * it[k+1] * it[k]^2 * (3 * ot[k-1] - 1) + d[k-1] * ot[k-1] * ot[k]^2 * (3 * it[k+1] - 1)
   end
   B[n-1] = d[n-1] * it[n] * it[n-1]^2 * (3 * ot[n-2] - 1) + d[n-2] * ot[n-2] * ot[n-1]^2 * (3 * it[n] - 1)
    if closed then
        B[n-1] = B[n-1] + 1
   elseif not phi[n] then
      B[n-1] = B[n-1] - d[n-2] * ot[n-2] * ot[n-1]^2 * (it[n]^3 + ocurl * ot[n-1]^3 * (3 * it[n] - 1)) / (it[n]^3 * (3 * ot[n-1] - 1) + ocurl * ot[n-1]^3)
   end

    if closed then
      C[0] = -d[n-2] * ot[n-2] * ot[n-1]^2
   elseif theta[0] then
      C[0] = 0
   else
      C[0] = ot[0]^3 + icurl * it[1]^3 * (3 * ot[0] - 1)
   end
   for i=1,n do
      C[i] = d[i-1] * ot[i-1] * ot[i]^2
   end

    if closed then
        D[0] = 0
   elseif theta[0] then
      D[0] = theta[0]
   else
      D[0] = - (ot[0]^3 + icurl * it[1]^3 * (3 * ot[0] - 1)) * psi[1]
   end
   for i=1,n-2 do
      D[i] = - d[i] * it[i+1] * it[i]^2 * (3 * ot[i-1] - 1) * psi[i] - d[i-1] * ot[i-1] * ot[i]^2 * psi[i+1]
   end
   D[n-1] = - d[n-1] * it[n] * it[n-1]^2 * (3 * ot[n-2] - 1) * psi[n-1]
    if closed then
      D[n-1] = D[n-1] - d[n-2] * ot[n-2] * ot[n-1]^2 * psi[1]
   elseif phi[n] then
      D[n-1] = D[n-1] - d[n-2] * ot[n-2] * ot[n-1]^2 * phi[n]
   end
    
    if closed then
        u[0] = 1
        u[n-1] = 1
        v[1] = d[n-2] * ot[n-2] * ot[n-1]^2
        v[n-1] = -1
        for k=1,n-2 do
            u[k] = 0
        end
        for k=2,n-2 do
            v[k] = 0
        end
    end

   for i=1,n-1 do
      B[i] = B[i-1] * B[i] - A[i] * C[i-1]
      C[i] = B[i-1] * C[i]
      D[i] = B[i-1] * D[i] - A[i] * D[i-1]
        if closed then
            u[i] = B[i-1] * u[i] - A[i] * u[i-1]
        end
   end

   theta[n-1] = D[n-1]/B[n-1]
   for i=n-2,1,-1 do
      theta[i] = (D[i] - C[i] * theta[i+1])/B[i]
   end
    if closed then
        local Mu = {}
        Mu[n-1] = u[n-1]/B[n-1]
        for i=n-2,1,-1 do
            Mu[i] = (u[i] - C[i] * Mu[i+1])/B[i]
        end
        local vMD = -(v[1]*theta[1] + v[n-1]*theta[n-1])/(1+v[1]*Mu[1] + v[n-1]*Mu[n-1])
        for k=1,n-1 do
            theta[k] = theta[k] + vMD *Mu[k]
        end
        -- n = n -1
        theta[0] = theta[n-1]
    end
   for i=1,n-1 do
      phi[i] = -psi[i] - theta[i]
   end
   if not theta[0] then
      theta[0] = (ot[0]^3 + icurl * it[1]^3 * (3 * ot[0] - 1)) / (ot[0]^3 * (3 * it[1] - 1) + icurl * it[1]^3) * phi[1]
   end
   if not phi[n] then
      phi[n] = (it[n]^3 + ocurl * it[n-1]^3 * (3 * it[n] - 1)) / (it[n]^3 * (3 * ot[n-1] - 1) + ocurl * ot[n-1]^3) * theta[n-1]
   end

   local alpha
   for i = 0,n-1 do
      alpha = a * (math.sin(theta[i]) - b * math.sin(phi[i+1])) * (math.sin(phi[i+1]) - b * math.sin(theta[i])) * (math.cos(theta[i]) - math.cos(phi[i+1]))
      rho[i] = (2 + alpha) / (1 + (1 - c) * math.cos(theta[i]) + c * math.cos(phi[i+1]))
      sigma[i+1] = (2 - alpha) / (1 + (1 - c) * math.cos(phi[i+1]) + c * math.cos(theta[i]))
   end
    if closed then
        n = n - 1
    end
   for i = 0,n-1 do
    table.insert(curves,fn(
        z[i],
        z[i] + d[i]*rho[i] * vec2(math.cos(theta[i] + omega[i]), math.sin(theta[i] + omega[i]))/3,
        z[i+1] - d[i] * sigma[i+1] * vec2(math.cos(omega[i] - phi[i+1]), math.sin(omega[i] - phi[i+1]))/3,
        z[i+1]
        ))
   end
    return curves
end

local function Hobby(pts,extra)
    return __makeHobby(pts,Bezier,extra)
end

local function HobbyPoints(pts,extra)
    return __makeHobby(pts,function(a,b,c,d) return {a,b,c,d} end,extra)
end

local BezierList = class()
local s
local function __bezierlist() 
    s = shader([[
//
// A basic vertex shader
//

//This is the current model * view * projection matrix
// Codea sets it automatically
uniform mat4 modelViewProjection;
attribute vec4 scolour;
attribute vec4 ecolour;

//This is the current mesh vertex position, color and tex coord
// Set automatically
attribute vec4 position;
attribute vec2 texCoord;

//This is an output variable that will be passed to the fragment shader
varying highp vec2 vTexCoord;
varying highp float vWidth;
varying lowp vec4 vColour;

attribute float len;
attribute float width;
attribute float taper;
attribute float blur;
attribute vec2 pts_a;
attribute vec2 pts_b;
attribute vec2 pts_c;
attribute vec2 pts_d;

void main()
{
    highp float t = position.y/len;
    highp float w = smoothstep(0.,1.,t);
    vWidth = w*(taper*width - width) + width + blur;
    highp float tt = 1.0 - t;
    highp vec2 bpos = tt*tt*tt*pts_a + 3.0*tt*tt*t*pts_b 
    + 3.0*tt*t*t*pts_c + t*t*t*pts_d;
    highp vec2 bdir = tt*tt*(pts_b-pts_a)
         + 2.0*tt*t*(pts_c-pts_b) + t*t*(pts_d-pts_c);
    bdir = vec2(bdir.y,-bdir.x);
    bdir = vWidth*position.x*normalize(bdir);
    bpos = bpos + bdir;
    highp vec4 bzpos = vec4(bpos.x,bpos.y,0,1);
    vColour = t*(ecolour - scolour) + scolour;
    vTexCoord = vec2(texCoord.x, t);
    //Multiply the vertex position by our combined transform
    gl_Position = modelViewProjection * bzpos;
}
]],[[
//
// A basic fragment shader
//

//This represents the current texture on the mesh
uniform lowp sampler2D texture;
//uniform highp float width;
uniform highp float blur;

//The interpolated texture coordinate for this fragment
varying highp vec2 vTexCoord;
varying highp float vWidth;
varying lowp vec4 vColour;

void main()
{
    //Sample the texture at the interpolated coordinate
    lowp vec4 col = vColour;
    highp float edge = blur/(vWidth+blur);
    col.a = mix( 0., col.a,
    smoothstep( 0., edge, min(vTexCoord.x,1. - vTexCoord.x) ) );
    gl_FragColor = col;
}
]])
end

function BezierList:init()
    __bezierlist()
    self:__init()
    BezierList.init = BezierList.__init
end

function BezierList:__init()
    self.mesh = mesh()
    self.mesh.shader = s
    self.size = 1
end

function BezierList:draw()
    self.mesh:draw()
end

function BezierList:addBezier(t)
    local m = self.mesh
    local sc = m:buffer("scolour")
    local ec = m:buffer("ecolour")
    local len = m:buffer("len")
    local w = m:buffer("width")
    local tp = m:buffer("taper")
    local bl = m:buffer("blur")
    local ptsa = m:buffer("pts_a")
    local ptsb = m:buffer("pts_b")
    local ptsc = m:buffer("pts_c")
    local ptsd = m:buffer("pts_d")
    local isc = t.scolour or t.colour or color(stroke())
    local iec = t.ecolour or t.colour or color(stroke())
    local iw = t.width or strokeWidth()
    local itp = t.taper or 1
    local ibl = t.blur or 2
    local ipts = t.points
    local nsteps = t.nsteps or 150
    local s = self.size
    local bs = s+nsteps*6
    local ret = {s,bs}
    sc:resize(bs)
    ec:resize(bs)
    len:resize(bs)
    w:resize(bs)
    tp:resize(bs)
    bl:resize(bs)
    ptsa:resize(bs)
    ptsb:resize(bs)
    ptsc:resize(bs)
    ptsd:resize(bs)
    for n=1,nsteps do
        m:addRect(0,(n-.5),1,1)
        for k=1,6 do
            sc[s] = isc
            ec[s] = iec
            len[s] = nsteps
            w[s] = iw
            tp[s] = itp
            bl[s] = ibl
            ptsa[s] = ipts[1]
            ptsb[s] = ipts[2]
            ptsc[s] = ipts[3]
            ptsd[s] = ipts[4]
            s = s + 1
        end
    end
    self.size = s
    return ret
end

function BezierList:updateBezier(t,first,last)
    local m = self.mesh
    local fields,values = {},{}
    if t.scolour or t.colour then
        table.insert(fields,"scolour")
        values["scolour"] = t.scolour or t.colour
    end
    if t.ecolour or t.colour then
        table.insert(fields,"ecolour")
        values["ecolour"] = t.ecolour or t.colour
    end
    if t.width then
        table.insert(fields,"width")
        values["width"] = t.width
    end
    if t.taper then
        table.insert(fields,"taper")
        values["taper"] = t.taper
    end
    if t.blur then
        table.insert(fields,"blur")
        values["blur"] = t.blur
    end
    if t.points then
        table.insert(fields,"pts_a")
        table.insert(fields,"pts_b")
        table.insert(fields,"pts_c")
        table.insert(fields,"pts_d")
        values["pts_a"] = t.points[1]
        values["pts_b"] = t.points[2]
        values["pts_c"] = t.points[3]
        values["pts_d"] = t.points[4]
    end
    local buffers = {}
    for k,v in ipairs(fields) do
        buffers[v] = m:buffer(v)
    end
    for k=first,last do
        for l,v in pairs(buffers) do
            v[k] = values[l]
        end
    end
end

local exports = {
   QuickHobby = QuickHobby,
   HobbyPoints = HobbyPoints,
    QHobbyGenerator = QHobbyGenerator,
    Hobby = Hobby,
    QHobby = QHobby,
    bezier = bezier
}

if cmodule then
    cmodule.export(exports)
    return {Bezier,BezierList}
else
    for k,v in pairs(exports) do
        _G[k] = v
    end
    _G["Bezier"] = Bezier
    _G["BezierList"] = BezierList
end
