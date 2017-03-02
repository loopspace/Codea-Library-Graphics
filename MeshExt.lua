-- MeshExt

local __doJewel, __doSuspension, __doPyramid, __doBlock, __addTriangle, __doSphere, __threeFromTwo, __orthogonalTo, __doCylinder, __discreteNormal, __doCone, __doPoly, __doFacetedClosedCone, __doFacetedOpenCone, __doSmoothClosedCone, __doSmoothOpenCone, __doFacetedClosedCylinder, __doFacetedOpenCylinder, __doSmoothClosedCylinder, __doSmoothOpenCylinder, __initmesh

--[[
| Option       | Default                  | Description |
|:-------------|:-------------------------|:------------|
| `mesh`         | new mesh                 | The mesh to add the shape to. |
| `position`     | end of mesh              | The position in the mesh at which to start the shape. |
| `origin`       | `vec3(0,0,0)`            | The origin (or centre) of the shape. |
| `axis`         | `vec3(0,1,0)`            | The axis specifies the direction of the jewel. |
| `aspect`       | 1                        | The ratio of the height to the diameter of the gem. |
| `size`         | the length of the axis   | The size of the jewel; specifically the distance from the centre to the apex of the jewel. |
| `colour`/`color` | white                  | The colour of the jewel. |
| `texOrigin`    | `vec2(0,0)`              | If using a sprite sheet, this is the lower left corner of the rectangle associated with this gem. |
| `texSize`      | `vec2(1,1)`              | This is the width and height of the rectangle of the texture associated to this gem.
--]]
function addJewel(t)
    local m,ret,rl = __initmesh(t.mesh, t.light, t.ambience, t.intensity, t.texture, t.basicLighting)
    local p = t.position or (m.size + 1)
    p = p + (1-p)%3
    local o = t.origin or vec3(0,0,0)
    local c = t.colour or t.color or color(255, 255, 255, 255)
    local as = t.aspect or 1
    local to = t.texOrigin or vec2(0,0)
    local ts = t.texSize or vec2(1,1)
    local a = {}
    a[1] = t.axis or vec3(0,1,0)
    if t.size then
        a[1] = a[1]:normalize()*t.size
    end
    a[2] = __orthogonalTo(a[1])
    a[3] = a[1]:cross(a[2])
    local la = a[1]:len()
    for i = 2,3 do
        a[i] = as*la*a[i]:normalize()
    end
    local n = t.sides or 12
    if p > m.size - 12*n then
        m:resize(p + 12*n-1)
    end
    local l,am
    if rl then
        l = vec3(0,0,0)
        am = 1
    else
        l = t.light or vec3(0,0,0)
        if t.intensity then
            l = l:normalize()*t.intensity
        elseif l:lenSqr() > 1 then
            l = l:normalize()
        end
        am = t.ambience or (1 - l:len())
    end
    local np = __doJewel(m,p,n,o,a,c,to,ts,l,am)
    if ret then
        return m,p,np
    else
        return m
    end
end

--[[
A jewel is a special case of a "suspension".

m mesh to add shape to
p position of first vertex of shape
n number of sides
o centre of shape (vec3)
a axes (table of vec3s)
col colour
to offset of texture region (vec2)
ts size of texture region (vec2)
l light vector
--]]
function __doJewel(m,p,n,o,a,col,to,ts,l,am)
    local th = math.pi/n
    local cs = math.cos(th)
    local sn = math.sin(th)
    local h = (1 - cs)/(1 + cs)
    local k,b,c,d,tb,tc,td,tex,pol
    tex,pol={},{}
    c = cs*a[2] + sn*a[3]
    d = -sn*a[2] + cs*a[3]
    tc = cs*vec2(ts.x*.25,0) + sn*vec2(0,ts.y*.5)
    td = -sn*vec2(ts.x*.25,0) + cs*vec2(0,ts.y*.5)
    for i = 1,2*n do
        k = 2*(i%2) - 1
        table.insert(pol,o+h*k*a[1]+c)
        table.insert(tex,tc)
        c,d = cs*c + sn*d,-sn*c + cs*d
        tc,td = cs*tc + sn*td,-sn*tc + cs*td
    end
    return __doSuspension(m,p,2*n,o,{o+a[1],o-a[1]},pol,tex,col,to,ts,true,true,l,am)
end

--[[
A "suspension" is a double cone on a curve.

m mesh to add shape to
p position of first vertex of shape
n number of points
o centre of shape (vec3)
a apexes (table of 2 vec3s)
v vertices (table of vec3s in cyclic order)
t texture coordinates corresponding to vertices (relative to centre)
col colour
to offset of texture region (vec2)
ts size of texture region (vec2)
f faceted
cl closed curve or not
l light vector
--]]
function __doSuspension(m,p,n,o,a,v,t,col,to,ts,f,cl,l,am)
    local tu
    for i=1,2 do
        tu = to+vec2(ts.x*(i*.5-.25),ts.y*.5)
        p = __doCone(m,p,n,o,a[i],v,t,col,tu,ts,f,cl,l,am)
    end
    return p
end

--[[
A "cone" is formed by taking a curve in space and joining each of its points to an apex.
If the original curve is made from line segments, the resulting cone has a natural triangulation which can be used to construct it as a mesh.

m mesh
p position in mesh
n number of points
o "internal" point (to ensure that normals point outwards)
a apex of cone
v table of base points
t table of texture points
col colour
to texture offset
ts not used
f faceted or not
cl closed curve or not
l light vector
--]]
function __doCone(m,p,n,o,a,v,t,col,to,ts,f,cl,l,am)
    if f then
        if cl then
            return __doFacetedClosedCone(m,p,n,o,a,v,t,col,to,ts,l,am)
        else
            return __doFacetedOpenCone(m,p,n,o,a,v,t,col,to,ts,l,am)
        end
    else
        if cl then
            return __doSmoothClosedCone(m,p,n,o,a,v,t,col,to,ts,l,am)
        else
            return __doSmoothOpenCone(m,p,n,o,a,v,t,col,to,ts,l,am)
        end
    end
end

function __doFacetedClosedCone(m,p,n,o,a,v,t,col,to,ts,l,am)
    local j,nml,c
    for k=1,n do
        j = k%n + 1
        nml = (v[k] - a):cross(v[j] - a)
        if nml:dot(a - o) < 0 then
            nml = -nml
        end
        nml = nml:normalize()
        c = col:mix(color(0,0,0,col.a),am+(1-am)*math.max(0,l:dot(nml)))
        __addTriangle(m,p,v[j],v[k],a,c,c,c,nml,nml,nml,to+t[j],to+t[k],to)
        p = p + 3
    end
    return p
end

function __doFacetedOpenCone(m,p,n,o,a,v,t,col,to,ts,l,am)
    local j,nml,c
    for k=1,n-1 do
        j = k + 1
        nml = (v[k] - a):cross(v[j] - a)
        if nml:dot(a - o) < 0 then
            nml = -nml
        end
        nml = nml:normalize()
        c = col:mix(color(0,0,0,col.a),am+(1-am)*math.max(0,l:dot(nml)))
        __addTriangle(m,p,v[j],v[k],a,c,c,c,nml,nml,nml,to+t[j],to+t[k],to)
        p = p + 3
    end
    return p
end

function __doSmoothClosedCone(m,p,n,o,a,v,t,col,to,ts,l,am)
    local j,nmla,nmlb,nmlc,cc,ca,nb,cb
    nmlb = vec3(0,0,0)
    nmlc = __discreteNormal(v[1],o,v[n],a,v[2])
    cc = col:mix(color(0,0,0,col.a),am+(1-am)*math.max(0,l:dot(nmlc)))
    nb = vec3(0,0,0)
    for k=1,n do
        j = k%n + 1
        nb = nb + __discreteNormal(v[j],o,v[k],a,v[j%n+1])
    end
    nb = nb:normalize()
    cb = col:mix(color(0,0,0,col.a),am+(1-am)*math.max(0,l:dot(nb)))
    for k=1,n do
        j = k%n + 1
        nmla = nmlc
        ca = cc
        nmlc = __discreteNormal(v[j],o,v[k],a,v[j%n+1])
        cc = col:mix(color(0,0,0,col.a),am+(1-am)*math.max(0,l:dot(nmlc)))
        __addTriangle(m,p,v[j],v[k],a,cc,ca,cb,nmlc,nmla,nmlb,to+t[j],to+t[k],to)
        p = p + 3
    end
    return p
end

function __doSmoothOpenCone(m,p,n,o,a,v,t,col,to,ts,l,am)
    local j,nmla,nmlb,nmlc,cc,ca,ll,nb,cb
    ll = l:len()
    nmlb = vec3(0,0,0)
    nmlc = __discreteNormal(v[1],o,a,v[2])
    cc = col:mix(color(0,0,0,col.a),am+(1-am)*math.max(0,l:dot(nmlc)))
    nb = vec3(0,0,0)
    for k=1,n-2 do
        j = k + 1
        nb = nb + __discreteNormal(v[j],o,v[k],a,v[j%n+1])
    end
    nb = nb + __discreteNormal(v[n],o,v[n-1],a)
    nb = nb:normalize()
    cb = col:mix(color(0,0,0,col.a),am+(1-am)*math.max(0,l:dot(nb)))
    for k=1,n-2 do
        j = k + 1
        nmla = nmlc
        ca = cc
        nmlc = __discreteNormal(v[j],o,v[k],a,v[j%n+1])
        cc = col:mix(color(0,0,0,col.a),am+(1-am)*math.max(0,l:dot(nmlc)))
        __addTriangle(m,p,v[j],v[k],a,cc,ca,cb,nmlc,nmla,nmlb,to+t[j],to+t[k],to)
        p = p + 3
    end
    nmla = nmlc
    ca = cc
    nmlc = __discreteNormal(v[n],o,v[n-1],a)
    cc = col:mix(color(0,0,0,col.a),am+(1-am)*math.max(0,l:dot(nmlc)))
    __addTriangle(m,p,v[n],v[n-1],a,cc,ca,cb,nmlc,nmla,nmlb,to+t[n],to+t[n-1],to)
    return p + 3
end

function addPolygon(t)
    t = t or {}
    local m,ret,rl = __initmesh(t.mesh, t.light, t.ambience, t.intensity, t.texture, t.basicLighting)
    local p = t.position or (m.size + 1)
    p = p + (1-p)%3
    local ip = p
    local col = t.colour or t.color or color(255, 255, 255, 255)
    local f = true
    local to = t.texOrigin or vec2(0,0)
    local ts = t.texSize or vec2(1,1)
    if t.faceted ~= nil then
        f = t.faceted
    end
    local cl = true
    if t.closed ~= nil then
        cl = t.closed
    end
    local l,am
    if rl then
        l = vec3(0,0,0)
        am = 1
    else
        l = t.light or vec3(0,0,0)
        if t.intensity then
            l = l:normalize()*t.intensity
        elseif l:lenSqr() > 1 then
            l = l:normalize()
        end
        am = t.ambience or (1 - l:len())
    end
    local v = t.vertices or {}
    local c = vec3(0,0,0)
    local n = 0
    for k,u in ipairs(v) do
        c = c + u
        n = n + 1
    end
    local size = p-1+3*n+3
    if not closed then
        size = size - 3
    end
    if m.size<size then
        m:resize(size)
    end
    c = c/n
    local cv = {}
    for k,u in ipairs(v) do
        table.insert(cv,u-c)
    end
    local nml = vec3(0,0,0)
    for k=2,n do
        nml = nml + cv[k]:cross(cv[k-1])
    end
    if cl then
        nml = nml + cv[1]:cross(cv[n])
    end
    nml = nml:normalize()
    local o = t.viewFrom or 1
    if type(o) == "number" then
        o = o * nml + c
    end
    local tx
    if t.texCoords then
        tx = t.texCoords
    else
        tx = {}
        local mx = (cv[1] - cv[1]:dot(nml)*nml):normalize()
        local my = nml:cross(mx):normalize()
        
        for k,u in ipairs(cv) do
            table.insert(tx,vec2(u:dot(mx),u:dot(my)))
        end
        mx,my = tx[1],tx[1]
        for k,u in ipairs(tx) do
            mx.x = math.min(mx.x,u.x)
            mx.y = math.min(mx.y,u.y)
            my.x = math.max(my.x,u.x)
            my.y = math.max(my.y,u.y)
        end
        for k,u in ipairs(tx) do
            tx[k] = vec2((u.x-mx.x)/(my.x-mx.x),(u.y-mx.y)/(my.y-mx.y))
        end
    end
    p = __doPoly(m,p,n,o,v,tx,col,to,ts,f,cl,l,am)
    if rt then
        return m,ip,p
    else
        return m
    end
end

--[[
This forms a surface which has boundary a given curve by forming a cone with the barycentre of the curve as its apex.

m mesh
p position in mesh
n number of points
o "internal" point (for normals)
v table of base points
t table of texture points
col colour
to texture offset
ts not used
f faceted or not
cl closed curve or not
l light vector
--]]
function __doPoly(m,p,n,o,v,t,col,to,ts,f,cl,l,am)
    local a,b,r = vec3(0,0,0),vec2(0,0),0
    for k,u in ipairs(v) do
        a = a + u
        r = r + 1
    end
    a = a / r
    for k,u in ipairs(t) do
        b = b + u
    end
    b = b / r
    for k=1,r do
        t[k] = t[k] - b
    end
    return __doCone(m,p,n,o,a,v,t,col,to+b,ts,f,cl,l,am)
end

--[[
| Option | Default | Description |
|:-------|:--------|:------------|
| `mesh` | new mesh | The mesh to add the shape to. |
| `position` | end of mesh | The place in the mesh at which to add the shape. |
| `colour`/`color` | white | The colour of the shape. |
| `faceted` | true | Whether to make it faceted or smooth. |
| `ends` | `0` | Which ends to fill in (`0` for none, `1` for start, `2` for end, `3` for both) |
| `texOrigin`    | `vec2(0,0)`              | If using a sprite sheet, this is the lower left corner of the rectangle associated with this shape. |
| `texSize`      | `vec2(1,1)`              | This is the width and height of the rectangle of the texture associated to this shape. |

There are various ways to specify the dimensions of the cylinder.
If given together, the more specific overrides the more general.

`radius` and `height` (`number`s) can be combined with `axes` (table of three `vec3`s) to specify the dimensions, where the first axis vector lies along the cylinder.  The vector `origin` then locates the cylinder in space.

`startCentre`/`startCenter` (a `vec3`), `startWidth` (`number` or `vec3`), `startHeight` (`number` or `vec3`), `startRadius` (`number`) specify the dimensions at the start of the cylinder (if numbers, they are taken with respect to certain axes).

Similarly named options control the other end.

If axes are needed, these can be supplied via the `axes` option.
If just the `axis` option is given (a single `vec3`), this is the direction along the cylinder.
Other directions (if needed) are found by taking orthogonal vectors to this axis.
--]]
										
function addCylinder(t)
    t = t or {}
    local m,ret,rl = __initmesh(t.mesh, t.light, t.ambience, t.intensity, t.texture, t.basicLighting)
    local p = t.position or (m.size + 1)
    p = p + (1-p)%3
    local ip = p
    local col = t.colour or t.color or color(255, 255, 255, 255)
    local f = true
    local ends
    local solid = t.solid
    if solid then
        ends = t.ends or 3
    else
        ends = t.ends or 0
    end
    if t.faceted ~= nil then
        f = t.faceted
    end
    local l,am
    if rl then
        l = vec3(0,0,0)
        am = 1
    else
        l = t.light or vec3(0,0,0)
        if t.intensity then
            l = l:normalize()*t.intensity
        elseif l:lenSqr() > 1 then
            l = l:normalize()
        end
        am = t.ambience or (1 - l:len())
    end
    local r = t.radius or 1
    local h = t.height or 1
    local to = t.texOrigin or vec2(0,0)
    local ts = t.texSize or vec2(1,1)
    local sc,si,sj,ec,ei,ej,a,o
    
    if t.axis or t.axes or t.origin or t.centre or t.center then
        if t.axis then
            a = t.axis
        elseif t.axes then
            a = t.axes[1]
        else
            a = vec3(0,1,0)
        end
        if t.height then
            a = h*a:normalize()
        end
        if t.origin or t.centre or t.center then
            local o = t.origin or t.centre or t.center
            sc,ec = o - a/2,o + a/2
        end
    end
    sc = t.startCentre or t.startCenter or sc
    ec = t.endCentre or t.endCenter or ec
    sc,ec,a = __threeFromTwo(sc,ec,a,vec3(0,-h/2,0),vec3(0,h/2,0),vec3(0,h,0))
    si = t.startWidth or t.startRadius or t.radius or 1
    sj = t.startHeight or t.startRadius or t.radius or 1
    ei = t.endWidth or t.endRadius or t.radius or 1
    ej = t.endHeight or t.endRadius or t.radius or 1
    local c,d
    if t.axes then
        a,c,d = unpack(t.axes)
    end
    if type(si) == "number" then
        if type(sj) == "number" then
            if not c then
                c = __orthogonalTo(a)
            end
            si = si*c:normalize()
            if not d then
                sj = sj*a:cross(c):normalize()
            else
                sj = sj*d:normalize()
            end
        else
            si = si*sj:cross(a):normalize()
        end
    elseif type(sj) == "number" then
        sj = sj*a:cross(si):normalize()
    end
    if type(ei) == "number" then
        if type(ej) == "number" then
            if not c then
                c = __orthogonalTo(a)
            end
            ei = ei*c:normalize()
            if not d then
                ej = ej*a:cross(c):normalize()
            else
                ej = ej*d:normalize()
            end
        else
            ei = ei*ej:cross(a):normalize()
        end
    elseif type(ej) == "number" then
        ej = ej*a:cross(ei):normalize()
    end

    local n = t.size or 12
    local sa,ea,da = __threeFromTwo(t.startAngle,t.endAngle,t.deltaAngle,0,360,360)
    local closed
    if da == 360 then
        closed = true
        solid = false
    else
        closed = false
    end
    sa = math.rad(sa)
    ea = math.rad(ea)
    da = math.rad(da)/n
    o = (sc + math.cos((sa+ea)/2)*si/2 + math.sin((sa+ea)/2)*sj/2 + ec + math.cos((sa+ea)/2)*ei/2 + math.sin((sa+ea)/2)*ej/2)/2
    local ss = 1 + math.floor((ends+1)/2)
    if solid then
        ss = ss + 2 
    end
    ts.x = ts.x / ss
    local cs,sn,ti,tj
    ti,tj = vec2(ts.x/2,0),vec2(0,ts.y/2)
    cs = math.cos(sa)
    sn = math.sin(sa)
    si,sj = cs*si + sn*sj, -sn*si + cs*sj
    ei,ej = cs*ei + sn*ej, -sn*ei + cs*ej
    ti,tj = cs*ti + sn*tj, -sn*ti + cs*tj
    local u,v,tu,tv,tw,cnrs = {},{},{},{},{},{}
    cnrs[1] = {sc,sc+si,ec+ei,ec}
    cs = math.cos(da)
    sn = math.sin(da)
    u[0] = sc+cs*si - sn*sj
    v[0] = ec+cs*ei - sn*ej
    for k=0,n do
        table.insert(u,sc+si)
        table.insert(v,ec+ei)
        table.insert(tu,to + vec2(ts.x*k/n,0))
        table.insert(tv,to + vec2(ts.x*k/n,ts.y))
        table.insert(tw,ti)
        si,sj = cs*si + sn*sj, -sn*si + cs*sj
        ei,ej = cs*ei + sn*ej, -sn*ei + cs*ej
        ti,tj = cs*ti + sn*tj, -sn*ti + cs*tj
    end
    u[n+2] = sc+cs*si + sn*sj
    v[n+2] = ec+cs*ei + sn*ej
    cnrs[2] = {sc, sc+cs*si - sn*sj, ec+cs*ei - sn*ej, ec}
    local size = 6*n + math.floor((ends+1)/2)*3*n
    if closed then
        size = size + math.floor((ends+1)/2)*3
    elseif solid then
        size = size + 24
    end
    if p - 1 + size > m.size then
        m:resize(p-1+size)
    end
    n = n + 1
    p = __doCylinder(m,p,n,o,u,v,tu,tv,col,f,closed,l,am)
    to = to + ts/2
    if solid and not closed then
        local tex = {-ts/2,vec2(ts.x/2,-ts.y/2),ts/2,vec2(-ts.x/2,ts.y/2)}
        for i=1,2 do
            to.x = to.x + ts.x
            p = __doPoly(m,p,4,o,cnrs[i],tex,col,to,ts,f,true,l,am)
        end
    end
    if ends%2 == 1 then
        to.x = to.x + ts.x
        p = __doCone(m,p,n,o,sc,u,tw,col,to,ts,f,closed,l,am)
    end
    if ends >= 2 then
        to.x = to.x + ts.x
        p = __doCone(m,p,n,o,ec,v,tw,col,to,ts,f,closed,l,am)
    end
    if ret then
        return m,ip, p
    else
        return m
    end
end

--[[
This adds a cylinder to the mesh.

m mesh to add shape to
p position of first vertex of shape
n number of points
o centre of shape (vec3)
a apexes (table of 2 vec3s)
v vertices (table of vec3s in cyclic order)
t texture coordinates corresponding to vertices (relative to centre)
col colour
to offset of texture region (vec2)
ts size of texture region (vec2)
f faceted
cl closed
l light vector
--]]
function __doCylinder(m,p,n,o,u,v,ut,vt,col,f,cl,l,am)
    if f then
        if cl then
            return __doFacetedClosedCylinder(m,p,n-1,o,u,v,ut,vt,col,l,am)
        else
            return __doFacetedOpenCylinder(m,p,n,o,u,v,ut,vt,col,l,am)
        end
    else
        if cl then
            return __doSmoothClosedCylinder(m,p,n-1,o,u,v,ut,vt,col,l,am)
        else
            return __doSmoothOpenCylinder(m,p,n,o,u,v,ut,vt,col,l,am)
        end
    end
end

function __doFacetedClosedCylinder(m,p,n,o,u,v,ut,vt,col,l,am)
    local i,j,nv,nu,cu,cv,ll
    ll = l:len()
    for k=1,n do
        j = k%n + 1
        nu = (u[j] - u[k]):cross(v[k] - u[k]):normalize()
        nv = (v[j] - v[k]):cross(u[k] - v[k]):normalize()
        if nu:dot(u[k]-o) < 0 then
            nu = -nu
        end
        if nv:dot(v[k]-o) < 0 then
            nv = -nv
        end
        cv = col:mix(color(0,0,0,col.a),am+(1-am)*math.max(0,l:dot(nv)))
        cu = col:mix(color(0,0,0,col.a),am+(1-am)*math.max(0,l:dot(nu)))
        __addTriangle(m,p,v[j],v[k],u[j],cv,cv,cu,nv,nv,nu,vt[j],vt[k],ut[j])
        p = p + 3
        __addTriangle(m,p,v[k],u[j],u[k],cv,cu,cu,nv,nu,nu,vt[k],ut[j],ut[k])
        p = p + 3
    end
    return p
end

function __doFacetedOpenCylinder(m,p,n,o,u,v,ut,vt,col,l,am)
    local i,j,nv,nu,cu,cv,ll
    ll = l:len()
    for k=1,n-1 do
        j = k + 1
        nu = (u[j] - u[k]):cross(v[k] - u[k]):normalize()
        nv = (v[j] - v[k]):cross(u[k] - v[k]):normalize()
        if nu:dot(u[k]-o) < 0 then
            nu = -nu
        end
        if nv:dot(v[k]-o) < 0 then
            nv = -nv
        end
        cv = col:mix(color(0,0,0,col.a),am+(1-am)*math.max(0,l:dot(nv)))
        cu = col:mix(color(0,0,0,col.a),am+(1-am)*math.max(0,l:dot(nu)))
        __addTriangle(m,p,v[j],v[k],u[j],cv,cv,cu,nv,nv,nu,vt[j],vt[k],ut[j])
        p = p + 3
        __addTriangle(m,p,v[k],u[j],u[k],cv,cu,cu,nv,nu,nu,vt[k],ut[j],ut[k])
        p = p + 3
    end
    return p
end

function __doSmoothClosedCylinder(m,p,n,o,u,v,ut,vt,col,l,am)
    local i,j,nv,nu,cu,cv
    nv,nu,cv,cu = {},{},{},{}
    nv[1] = __discreteNormal(v[1],o,v[n],u[1],v[2])
    nu[1] = __discreteNormal(u[1],o,u[n],v[1],u[2])
    cv[1] = col:mix(color(0,0,0,col.a),am+(1-am)*math.max(0,l:dot(nv[1])))
    cu[1] = col:mix(color(0,0,0,col.a),am+(1-am)*math.max(0,l:dot(nu[1])))
    for k=1,n do
        j = k%n + 1
        i = j%n + 1
        nv[j] = __discreteNormal(v[j],o,v[k],u[j],v[i])
        nu[j] = __discreteNormal(u[j],o,u[k],v[j],u[i])
        cv[j] = col:mix(color(0,0,0,col.a),am+(1-am)*math.max(0,l:dot(nv[j])))
        cu[j] = col:mix(color(0,0,0,col.a),am+(1-am)*math.max(0,l:dot(nu[j])))
        __addTriangle(m,p,v[j],v[k],u[j],cv[j],cv[k],cu[j],nv[j],nv[k],nu[j],vt[j],vt[k],ut[j])
        p = p + 3
        __addTriangle(m,p,v[k],u[j],u[k],cv[k],cu[j],cu[k],nv[k],nu[j],nu[k],vt[k],ut[j],ut[k])
        p = p + 3
    end
    return p
end

function __doSmoothOpenCylinder(m,p,n,o,u,v,ut,vt,col,l,am)
    local i,j,nv,nu,cu,cv
    nv,nu,cv,cu = {},{},{},{}
    nv[1] = __discreteNormal(v[1],o,v[0],u[1],v[2])
    nu[1] = __discreteNormal(u[1],o,v[0],v[1],u[2])
    cv[1] = col:mix(color(0,0,0,col.a),am+(1-am)*math.max(0,l:dot(nv[1])))
    cu[1] = col:mix(color(0,0,0,col.a),am+(1-am)*math.max(0,l:dot(nu[1])))
    for k=1,n-2 do
        j = k + 1
        i = j + 1
        nv[j] = __discreteNormal(v[j],o,v[k],u[j],v[i])
        nu[j] = __discreteNormal(u[j],o,u[k],v[j],u[i])
        cv[j] = col:mix(color(0,0,0,col.a),am+(1-am)*math.max(0,l:dot(nv[j])))
        cu[j] = col:mix(color(0,0,0,col.a),am+(1-am)*math.max(0,l:dot(nu[j])))
        __addTriangle(m,p,v[j],v[k],u[j],cv[j],cv[k],cu[j],nv[j],nv[k],nu[j],vt[j],vt[k],ut[j])
        p = p + 3
        __addTriangle(m,p,v[k],u[j],u[k],cv[k],cu[j],cu[k],nv[k],nu[j],nu[k],vt[k],ut[j],ut[k])
        p = p + 3
    end
    nv[n] = __discreteNormal(v[n],o,v[n-1],u[n],v[n+1])
    nu[n] = __discreteNormal(u[n],o,u[n-1],v[n],u[n+1])
    cv[n] = col:mix(color(0,0,0,col.a),am+(1-am)*math.max(0,l:dot(nv[n])))
    cu[n] = col:mix(color(0,0,0,col.a),am+(1-am)*math.max(0,l:dot(nu[n])))
    __addTriangle(m,p,v[n],v[n-1],u[n],cv[n],cv[n-1],cu[n],nv[n],nv[n-1],nu[n],vt[n],vt[n-1],ut[n])
    p = p + 3
    __addTriangle(m,p,v[n-1],u[n],u[n-1],cv[n-1],cu[n],cu[n-1],nv[n-1],nu[n],nu[n-1],vt[n-1],ut[n],ut[n-1])
    return p+3
end


--[[
This works out a normal vector for a vertex in a triangulated surface by taking an average of the triangles in which it appears.
The normals are weighted by the reciprocal of the size of the corresponding triangle.

a vertex under consideration
o a point to determine which side the normals lie
... a cyclic list of vertices, successive pairs of which make up the triangles
--]]
function __discreteNormal(a,o,...)
    local arg = {}
    local n = 0
    for k,v in ipairs({...}) do
        if v then
            table.insert(arg,v)
            n = n + 1
        end
    end
    local na,nb
    na = vec3(0,0,0)
    for k=2,n do
        nb = (arg[k] - a):cross(arg[k-1] - a)
        na = na + nb/nb:lenSqr()
    end
    na = na:normalize()
    if na:dot(a-o) < 0 then
        na = -na
    end
    return na
end

--[[
Adds a pyramid to a mesh.

| Option       | Default                  | Description |
|:-------------|:-------------------------|:------------|
| `mesh`         | new mesh                 | The mesh to add the shape to. |
| `position`     | end of mesh              | The position in the mesh at which to start the shape. |
| `origin`       | `vec3(0,0,0)`            | The origin (or centre) of the shape. |
| `axis`         | `vec3(0,1,0)`            | The axis specifies the direction of the jewel. |
| `aspect`       | 1                        | The ratio of the height to the diameter of the gem. |
| `size`         | the length of the axis   | The size of the jewel; specifically the distance from the centre to the apex of the jewel. |
| `colour`/`color` | `color(255, 255, 255, 255)` | The colour of the jewel. |
| `texOrigin`    | `vwc2(0,0)`              | If using a sprite sheet, this is the lower left corner of the rectangle associated with this gem. |
| `texSize`      | `vec2(1,1)`              | This is the width and height of the rectangle of the texture associated to this gem.
--]]
function addPyramid(t)
    local m,ret,rl = __initmesh(t.mesh, t.light, t.ambience, t.intensity, t.texture, t.basicLighting)
    local p = t.position or (m.size + 1)
    p = p + (1-p)%3
    local o = t.origin or vec3(0,0,0)
    local c = t.colour or t.color or color(255, 255, 255, 255)
    local f = true
    if t.faceted ~= nil then
        f = t.faceted
    end
    local l,am
    if rl then
        l = vec3(0,0,0)
        am = 1
    else
        l = t.light or vec3(0,0,0)
        if t.intensity then
            l = l:normalize()*t.intensity
        elseif l:lenSqr() > 1 then
            l = l:normalize()
        end
        am = t.ambience or (1 - l:len())
    end
    local as = t.aspect or 1
    local to = t.texOrigin or vec2(0,0)
    local ts = t.texSize or vec2(1,1)
    local a = t.axes or {}
    a[1] = t.apex or a[1] or vec3(0,1,0)
    if t.size then
        a[1] = a[1]:normalize()*t.size
    end
    if not a[2] then
        local ax,ay,az = math.abs(a[1].x),math.abs(a[1].y),math.abs(a[1].z)
        if ax < ay and ax < az then
            a[2] = vec3(0,a[1].z,-a[1].y)
        elseif ay < az then
            a[2] = vec3(a[1].z,0,-a[1].x)
        else
            a[2] = vec3(a[1].y,-a[1].x,0)
        end
        a[3] = a[1]:cross(a[2])
    end
    local la = a[1]:len()
    for i = 2,3 do
        a[i] = as*la*a[i]:normalize()
    end
    local n = t.sides or 12
    if p > m.size - 6*n then
        m:resize(p + 6*n-1)
    end
    local np = __doPyramid(m,p,n,o,a,c,to,ts,f,l,am)
    if ret then
        return m,p,np
    else
        return m
    end
end

--[[
A pyramid is a special case of a suspension.

m mesh
p position
n number of points
o origin
a apex
col colour
to texture offset
ts texture size
f faceted
l light vector
--]]
function __doPyramid(m,p,n,o,a,col,to,ts,f,l,am)
    local th = 2*math.pi/n
    local cs = math.cos(th)
    local sn = math.sin(th)
    local b,c,d,tb,tc,td,tex,pol
    tex,pol={},{}
    c = cs*a[2] + sn*a[3]
    d = -sn*a[2] + cs*a[3]
    tc = cs*vec2(ts.x*.25,0) + sn*vec2(0,ts.y*.5)
    td = -sn*vec2(ts.x*.25,0) + cs*vec2(0,ts.y*.5)
    for i = 1,n do
        table.insert(pol,o+c)
        table.insert(tex,tc)
        c,d = cs*c + sn*d, -sn*c + cs*d
        tc,td = cs*tc + sn*td, -sn*tc + cs*td
    end
    return __doSuspension(m,p,n,o+a[1]/2,{o+a[1],o},pol,tex,col,to,ts,f,true,l,am)
end

-- block faces are in binary order: 000, 001, 010, 011 etc
local BlockFaces = {
        {1,2,3,4},
        {5,7,6,8},
        {1,5,2,6},
        {3,4,7,8},
        {2,6,4,8},
        {1,3,5,7}
    }
local BlockTex = {
    vec2(0,0),vec2(1/6,0),vec2(0,1),vec2(1/6,1)
}
--[[
Adds a block to a mesh.

| Option | Default | Description |
|:-------|:--------|:------------|
| `mesh`                     | new mesh | Mesh to use to add shape to. |
| `position`                 | end of mesh | Position in mesh to add shape at. |
| `colour`/`color` | color(255, 255, 255, 255) | Colour or colours to use.  Can be a table of colours, one for each vertex of the block. |
| `faces`        | all         | Which faces to render |
| `texOrigin`    | `vec2(0,0)` | Lower left corner of region on texture. |
| `texSize`      | `vec2(1,1)` | Width and height of region on texture. |
| `singleImage`  | `false`     | Uses the same image for all sides. |

There are a few ways of specifying the dimensions of the "block".

`centre`/`center`, `width`, `height`, `depth`, `size`.  This defines the "block" by specifying a centre followed by the width, height, and depth of the cube (`size` sets all three).  These can be `vec3`s or numbers.  If numbers, they correspond to the dimensions of the "block" in the `x`, `y`, and `z` directions respectively.  If `vec3`s, then are used to construct the vertices by adding them to the centre so that the edges of the "block" end up parallel to the given vectors.

`startCentre`/`startCenter`, `startWidth`, `startHeight`, `endCentre`/`endCenter`, `endWidth`, `endHeight`.  This defined the "block" by defining two opposite faces of the cube and then filling in the region in between.  The two faces are defined by their centres, widths, and heights.  The widths and heights can be numbers or `vec3`s exactly as above.

`block`.  This is a table of eight vertices defining the block.  The vertices are listed in binary order, in that if you picture the vertices of the standard cube of side length `1` with one vertex at the origin, the vertex with coordinates `(a,b,c)` is number a + 2b + 4c + 1 in the table (the `+1` is because lua tables are 1-based).
--]]
function addBlock(t)
    local m,ret,rl = __initmesh(t.mesh, t.light, t.ambience, t.intensity, t.texture, t.basicLighting)
    local p = t.position or (m.size + 1)
    p = p + (1-p)%3
    local c = t.colour or t.color or color(255, 255, 255, 255)
    if type(c) == "userdata" then
        c = {c,c,c,c,c,c,c,c}
    end
    local f = t.faces or BlockFaces
    local to = t.texOrigin or vec2(0,0)
    local ts = t.texSize or vec2(1,1)
    local dt = 1
    if t.singleImage then
        dt = 0
        ts.x = ts.x * 6
    end
    local l,am
    if rl then
        l = vec3(0,0,0)
        am = 1
    else
        l = t.light or vec3(0,0,0)
        if t.intensity then
            l = l:normalize()*t.intensity
        elseif l:lenSqr() > 1 then
            l = l:normalize()
        end
        am = t.ambience or (1 - l:len())
    end
    local v
    if t.block then
        v = t.block
    elseif t.center or t.centre then
        local o = t.center or t.centre
        local w,h,d = t.width or t.size or 1, t.height or t.size or 1, t.depth or t.size or 1
        w,h,d=w/2,h/2,d/2
        if type(w) == "number" then
            w = vec3(w,0,0)
        end
        if type(h) == "number" then
            h = vec3(0,h,0)
        end
        if type(d) == "number" then
            d = vec3(0,0,d)
        end
        v = {
            o - w - h - d,
            o + w - h - d,
            o - w + h - d,
            o + w + h - d,
            o - w - h + d,
            o + w - h + d,
            o - w + h + d,
            o + w + h + d
        }
    elseif t.startCentre or t.startCenter then
        local sc = t.startCentre or t.startCenter
        local ec = t.endCentre or t.endCenter
        local sw = t.startWidth
        local sh = t.startHeight
        local ew = t.endWidth
        local eh = t.endHeight
        if type(sw) == "number" then
            sw = vec3(sw,0,0)
        end
        if type(sh) == "number" then
            sh = vec3(0,sh,0)
        end
        if type(sc) == "number" then
            sc = vec3(0,0,sc)
        end
        if type(ew) == "number" then
            ew = vec3(ew,0,0)
        end
        if type(eh) == "number" then
            eh = vec3(0,eh,0)
        end
        if type(ec) == "number" then
            ec = vec3(0,0,ec)
        end
        v = {
            sc - sw - sh,
            sc + sw - sh,
            sc - sw + sh,
            sc + sw + sh,
            ec - ew - eh,
            ec + ew - eh,
            ec - ew + eh,
            ec + ew + eh
        }
    else
        v = {
            vec3(-1,-1,-1)/2,
            vec3(1,-1,-1)/2,
            vec3(-1,1,-1)/2,
            vec3(1,1,-1)/2,
            vec3(-1,-1,1)/2,
            vec3(1,-1,1)/2,
            vec3(-1,1,1)/2,
            vec3(1,1,1)/2
        }
    end
    if p > m.size - 36 then
        m:resize(p + 35)
    end
    local np = __doBlock(m,p,f,v,c,to,ts,dt,l,am)
    if ret then
        return m,p,np
    else
        return m
    end
end

--[[
m mesh
p index of first vertex to be used
f table of faces of block
v table of vertices of block
c table of colours of block (per vertex of block)
to offset for this shape's segment of the texture
ts size of this shape's segment of the texture
dt step size for the texture tiling
l light vector
--]]
function __doBlock(m,p,f,v,c,to,ts,dt,l,am)
    local n,t,tv
    t = 0
    l = l / 2
    for k,w in ipairs(f) do
        n = (v[w[3]] - v[w[1]]):cross(v[w[2]] - v[w[1]]):normalize()
        for i,u in ipairs({1,2,3,2,3,4}) do
            m:vertex(p,v[w[u]])
            m:color(p,c[w[u]]:mix(color(0,0,0,c[w[u]].a),am+(1-am)*math.max(0,l:dot(n))))
            m:normal(p,n)
            tv = BlockTex[u] + t*vec2(1/6,0)
            tv.x = tv.x * ts.x
            tv.y = tv.y * ts.y
            m:texCoord(p, to + tv)
            p = p + 1
        end
        t = t + dt
    end
    return p
end

--[[
Adds a sphere to a mesh.

| Options | Defaults | Description |
|:--------|:---------|:------------|
| `mesh` | New mesh | Mesh to add shape to. |
| `position` | End of mesh | Position at which to add shape. |
| `origin`/`centre`/`center` | `vec3(0,0,0)` | Centre of sphere. |
| `axes` | Standard axes | Axes of sphere. |
| `size` | `1` | Radius of sphere (relative to axes). |
| `colour`/`color` | `color(255, 255, 255, 255)` | Colour of sphere. |
| `faceted` | `false` | Whether to render the sphere faceted or smoothed (not yet implemented). |
| `number` | `36` | Number of steps to use to render sphere (twice this for longitude. |
| `texOrigin` | `vec2(0,0)` | Origin of region in texture to use. |
| `texSize` | `vec2(0,0)` | Width and height of region in texture to use.|
--]]
function addSphere(t)
    local m,ret,rl = __initmesh(t.mesh, t.light, t.ambience, t.intensity, t.texture, t.basicLighting)
    local p = t.position or (m.size + 1)
    p = p + (1-p)%3
    local o = t.origin or t.centre or t.center or vec3(0,0,0)
    local s = t.size or t.radius or 1
    local c = t.colour or t.color or color(255, 255, 255, 255)
    local n = t.number or 36
    local a = t.axes or {vec3(1,0,0),vec3(0,1,0),vec3(0,0,1)}
    a[1],a[2],a[3] = s*a[1],s*a[2],s*a[3]
    local to = t.texOrigin or vec2(0,0)
    local ts = t.texSize or vec2(1,1)
    local f = false
    if t.faceted ~= nil then
        f = t.faceted
    end
    local l,am
    if rl then
        l = vec3(0,0,0)
        am = 1
    else
        l = t.light or vec3(0,0,0)
        if t.intensity then
            l = l:normalize()*t.intensity
        elseif l:lenSqr() > 1 then
            l = l:normalize()
        end
        am = t.ambience or (1 - l:len())
    end
    if p > m.size - 12*n*(n-1) then
        m:resize(p+12*n*(n-1)-1)
    end
    local step = math.pi/n
    local np = __doSphere(m,p,o,a,0,step,n,0,step,2*n,c,f,to,ts,l,am)
    if ret then
        return m,p,np
    else
        return m
    end
end

--[[
Adds a segment of a sphere to a mesh.

| Options | Defaults | Description |
|:--------|:---------|:------------|
| `mesh` | New mesh | Mesh to add shape to. |
| `position` | End of mesh | Position at which to add shape. |
| `origin`/`centre`/`center` | `vec3(0,0,0)` | Centre of sphere. |
| `axes` | Standard axes | Axes of sphere. |
| `size` | `1` | Radius of sphere (relative to axes). |
| `colour`/`color` | `color(255, 255, 255, 255)` | Colour of sphere. |
| `faceted` | `false` | Whether to render the sphere faceted or smoothed (not yet implemented). |
| `number` | `36` | Number of steps to use to render sphere (twice this for longitude. |
| `solid` | `true` | Whether to make the sphere solid by filling in the internal sides. |
| `texOrigin` | `vec2(0,0)` | Origin of region in texture to use. |
| `texSize` | `vec2(0,0)` | Width and height of region in texture to use.|

Specifying the segment can be done in a variety of ways.

`startLatitude`, `endLatitude`, `deltaLatitude`, `startLongitude`, `endLongitude`, `deltaLongitude` specify the latitude and longitude for the segment relative to given axes (only two of the three pieces of information for each need to be given).

`incoming` and `outgoing` define directions that the ends of the segment will point towards.

--]]
function addSphereSegment(t)
    local m,ret,rl = __initmesh(t.mesh, t.light, t.ambience, t.intensity, t.texture, t.basicLighting)
    local p = t.position or (m.size + 1)
    p = p + (1-p)%3
    local ip = p
    local o = t.origin or t.centre or t.center or vec3(0,0,0)
    local s = t.size or t.radius or 1
    local c = t.colour or t.color or color(255, 255, 255, 255)
    local n = t.number or 36
    local solid = true
    if t.solid ~= nil then
        solid = t.solid
    end
    local a,st,dt,et,sp,dp,ep
    if t.incoming then
        a = {}
        a[3] = t.incoming:cross(t.outgoing)
        if a[3]:lenSqr() == 0 then
            if t.axes then
                a[3] = t.axes[3] - t.axes[3]:dot(t.incoming)*t.incoming/t.incoming:lenSqr()
            end
            if a[3]:lenSqr() == 0 then
                a[3] = __orthogonalTo(t.incoming)
            end
        end
        a[3] = a[3]:normalize()
        a[2] = t.incoming:normalize()
        a[1] = a[2]:cross(a[3])
        local w = a[3]:cross(t.outgoing):normalize()
        dp = math.acos(a[1]:dot(w))
        sp = 0
        ep = dp
        st = 0
        dt = math.pi
        et = math.pi
    else
        local ia = t.axes or {vec3(1,0,0),vec3(0,1,0),vec3(0,0,1)}
        a = {}
        a[1],a[2],a[3] = s*ia[1],s*ia[2],s*ia[3]
        sp,ep,dp = __threeFromTwo(t.startLongitude,t.endLongitude,t.deltaLongitude,0,360,360)
        st,et,dt = __threeFromTwo(t.startLatitude,t.endLatitude,t.deltaLatitude,0,180,180)
        sp = sp/180*math.pi
        dp = dp/180*math.pi
        ep = ep/180*math.pi
        st = st/180*math.pi
        dt = dt/180*math.pi
        et = et/180*math.pi
    end
    local step = math.pi/n
    local nt = math.ceil(dt/step)
    local np = math.ceil(dp/step)
    dt = dt / nt
    dp = dp / np
    local to = t.texOrigin or vec2(0,0)
    local ts = t.texSize or vec2(1,1)
    local f = false
    if t.faceted ~= nil then
        f = t.faceted
    end
    local l,am
    if rl then
        l = vec3(0,0,0)
        am = 1
    else
        l = t.light or vec3(0,0,0)
        if t.intensity then
            l = l:normalize()*t.intensity
        elseif l:lenSqr() > 1 then
            l = l:normalize()
        end
        am = t.ambience or (1 - l:len())
    end
    local size = 6*nt*np
    if st == 0 then
        size = size - 3*np
    end
    if et >= math.pi then
        size = size - 3*np
    end
    if solid then
        size = size + 6*(nt+3)
        local ss = 3
        if st ~= 0 then
            size = size + 3*np
            ss = ss + 1
        end
        if et < math.pi then
            size = size + 3*np
            ss = ss + 1
        end
        ts.x = ts.x/ss
    end
    if p > m.size - size then
        m:resize(p-1+size)
    end
    p = __doSphere(m,p,o,a,st,dt,nt,sp,dp,np,c,f,to,ts,l,am)
    if solid then
        to.x = to.x + ts.x
        local intl = o + math.sin(st+nt*dt/2)*math.cos(sp+np*dp/2)*a[1] + math.sin(st+nt*dt/2)*math.sin(sp+dp*np/2)*a[2] + math.cos(st+nt*dt/2)*a[3]
        local v,tex,at = {},{},1
        local tl,tu = math.cos(st), math.cos(et) - math.cos(st)
        if st ~= 0 then
            table.insert(v,o + math.cos(st)*a[3])
            table.insert(tex,vec2(ts.x,0))
            at = at + 1
        end
        for k=0,nt do
            table.insert(v,o+math.sin(st+k*dt)*math.cos(sp)*a[1] + math.sin(st+k*dt)*math.sin(sp)*a[2] + math.cos(st+k*dt)*a[3])
            table.insert(tex,vec2(ts.x*(1-math.sin(st+k*dt)),ts.y*(math.cos(st+k*dt) - tl)/tu))
        end
        if et < math.pi then
            table.insert(v,o + math.cos(et)*a[3])
            table.insert(tex,ts)
            at = at + 1
        end
        p = __doPoly(m,p,nt+at,intl,v,tex,c,to,ts,f,true,l,am)
        to.x = to.x + ts.x
        v,tex,at = {},{},1
        if st ~= 0 then
            table.insert(v,o + math.cos(st)*a[3])
            table.insert(tex,vec2(0,0))
            at = at + 1
        end
        for k=0,nt do
            table.insert(v,o+math.sin(st+k*dt)*math.cos(ep)*a[1] + math.sin(st+k*dt)*math.sin(ep)*a[2] + math.cos(st+k*dt)*a[3])
            table.insert(tex,vec2(ts.x*math.sin(st+k*dt),ts.y*(math.cos(st+k*dt) - tl)/tu))
        end
        if et < math.pi then
            table.insert(v,o + math.cos(et)*a[3])
            table.insert(tex,vec2(0,ts.y))
            at = at + 1
        end
        p = __doPoly(m,p,nt+at,intl,v,tex,c,to,ts,f,true,l,am)
        to = to + ts/2
        if st ~= 0 then
            to.x = to.x + ts.x
            v,tex = {},{}
            for k=0,np do
                table.insert(v,o+math.sin(st)*math.cos(sp+k*dp)*a[1] + math.sin(st)*math.sin(sp+k*dp)*a[2] + math.cos(st)*a[3])
                table.insert(tex,vec2(ts.x*math.sin(sp+k*dp)/2,ts.y*math.cos(sp+k*dp)/2))
            end
            p = __doCone(m,p,np+1,intl,o + math.cos(st)*a[3],v,tex,c,to,ts,f,false,l,am)
        end
        if et < math.pi then
            to.x = to.x + ts.x
            v,tex = {},{}
            for k=0,np do
                table.insert(v,o+math.sin(et)*math.cos(sp+k*dp)*a[1] + math.sin(et)*math.sin(sp+k*dp)*a[2] + math.cos(et)*a[3])
                table.insert(tex,vec2(ts.x*math.sin(sp+k*dp)/2,ts.y*math.cos(sp+k*dp)/2))
            end
            p = __doCone(m,p,np+1,intl,o + math.cos(et)*a[3],v,tex,c,to,ts,f,false,l,am)
        end
    end
    if ret then
        return m,ip,p
    else
        return m
    end
end

--[[
Adds a sphere or segment of the surface of a sphere.

m mesh
p position of first vertex
o origin
a axes (table of vec3s)
st start angle for theta
dt delta angle for theta
nt number of steps for theta
sp start angle for phi
dp delta angle for phi
np number of steps for phi
c colour
f faceted or smooth
to offset for this shape's segment of the texture
ts size of this shape's segment of the texture
l light vector
--]]
function __doSphere(m,p,o,a,st,dt,nt,sp,dp,np,c,f,to,ts,ll,am)
    local theta,ptheta,phi,pphi,ver,et,ep,tx,l,tex,stt,ett,ln,nml
    et = nt*dt/ts.y
    ep = np*dp/ts.x
    if st == 0 then
        stt = 2
    else
        stt = 1
    end
    if st + nt*dt >= math.pi then
        ett = nt-1
    else
        ett = nt
    end
    for i = stt,ett do
        theta = st + i*dt
        ptheta = st + (i-1)*dt
        for j=1,np do
            phi = sp + j*dp
            pphi = sp + (j-1)*dp
            ver = {}
            tex = {}
            for k,v in ipairs({
                {ptheta,pphi},
                {ptheta,phi},
                {theta,phi},
                {theta,phi},
                {ptheta,pphi},
                {theta,pphi}
            }) do
                table.insert(ver,math.sin(v[1])*math.cos(v[2])*a[1] + math.sin(v[1])*math.sin(v[2])*a[2] + math.cos(v[1])*a[3])
                table.insert(tex,to + vec2((v[2]-sp)/ep,(v[1]-st)/et))
            end
            for k = 1,6 do
                m:vertex(p,o + ver[k])
                if f then
                    l = math.floor((k-1)/3)
                    nml = (-1)^l*(ver[3*l+3] - ver[3*l+1]):cross(ver[3*l+2] - ver[3*l+1]):normalize()
                else
                    nml = ver[k]:normalize()
                end
                m:color(p,c:mix(color(0,0,0,255),am+(1-am)*math.max(0,ll:dot(nml))))
                m:normal(p,nml)
                m:texCoord(p,tex[k])
                p = p + 1
            end
        end
    end
    local ends = {}
    if st == 0 then
        table.insert(ends,0)
    end
    if st + nt*dt >= math.pi then
        table.insert(ends,1)
    end
    et = nt*dt
    ep = np*dp
    for _,i in ipairs(ends) do
        for j=1,np do
            phi = sp + j*dp
            pphi = sp + (j-1)*dp
            ver = {}
            tex = {}
            for k,v in ipairs({
                {dt,pphi},
                {dt,phi},
                {0,phi}
            }) do
                table.insert(ver,math.sin(v[1])*math.cos(v[2])*a[1] + math.sin(v[1])*math.sin(v[2])*a[2] + (-1)^i*math.cos(v[1])*a[3])
                tx = vec2((v[2]-sp)/ep,i + (1-2*i)*(v[1]-st)/et)
                tx.x = tx.x * ts.x
                tx.y = tx.y * ts.y
                table.insert(tex,to + tx)
            end
            for k=1,3 do
                m:vertex(p,o + ver[k])
                if f then
                    nml = (-1)^i*(ver[2]-ver[1]):cross(ver[3]-ver[1]):normalize()
                else
                    nml = ver[k]:normalize()
                end
                m:normal(p,nml)
                m:color(p,c:mix(color(0,0,0,255),am+(1-am)*math.max(0,ll:dot(nml))))
                m:texCoord(p,tex[k])
                p = p + 1
            end
        end
    end
    return p
end

--[[
These make the above available as methods on a mesh.
--]]
local mt = getmetatable(mesh())

local __addShape = function(m,f,t)
    t = t or {}
    local nt = {}
    for k,v in pairs(t) do
        nt[k] = v
    end
    nt.mesh = m
    return f(nt)
end

mt.addJewel = function(m,t)
    return __addShape(m,addJewel,t)
end

mt.addPyramid = function(m,t)
    return __addShape(m,addPyramid,t)
end

mt.addPolygon = function(m,t)
    return __addShape(m,addPolygon,t)
end

mt.addBlock = function(m,t)
    return __addShape(m,addBlock,t)
end

mt.addCylinder = function(m,t)
    return __addShape(m,addCylinder,t)
end

mt.addSphere = function(m,t)
    return __addShape(m,addSphere,t)
end

mt.addSphereSegment = function(m,t)
    return __addShape(m,addSphereSegment,t)
end


--[[
Adds a triangle to a mesh, with specific vertices, colours, normals, and texture coordinates.
--]]
function __addTriangle(m,p,a,b,c,d,e,f,g,h,i,j,k,l)
    m:vertex(p,a)
    m:color(p,d)
    m:normal(p,g)
    m:texCoord(p,j)
    p = p + 1
    m:vertex(p,b)
    m:color(p,e)
    m:normal(p,h)
    m:texCoord(p,k)
    p = p + 1
    m:vertex(p,c)
    m:color(p,f)
    m:normal(p,i)
    m:texCoord(p,l)
end

--[[
Returns three things, u,v,w, with the property that u + w = v.  The input can be any number of the three together with three defaults to be used if not enough information is given (so if any two of the first three are given then that is enough information to determine the third).
--]]
function __threeFromTwo(a,b,c,d,e,f)
    local u,v,w = a or d or 0, b or e or 1, c or f or 1
    if not a then
        u = v - w
    end
    if not b then
        v = u + w
    end
    if not c then
        w = v - u
    end
    v = u + w
    return u,v,w
end

--[[
Returns a vector orthogonal to the given `vec3`.
--]]
function __orthogonalTo(v)
    local a,b,c = math.abs(v.x), math.abs(v.y), math.abs(v.z)
    if a < b and a < c then
        return vec3(0,v.z,-v.y)
    end
    if b < c then
        return vec3(-v.z,0,v.x)
    end
    return vec3(v.y,-v.x,0)
end

--[[
Initialise a mesh
--]]
function __initmesh(m,l,a,i,t,b)
    local r,rl
    if m then
        r = true
    else
        r,m = false,mesh()
        if l and a and not b then
            rl = true
            m.shader = lighting()
            if i then
                l = l:normalize()*i
            elseif l:lenSqr() > 1 then
                l = l:normalize()
            end
            m.shader.light = l
            m.shader.ambient = a
            if t then
                m.shader.useTexture = 1
            else
                m.shader.useTexture = 0
            end
        end
        if t then
            if type(t) == "string" then
                m.texture = readImage(t)
            else
                m.texture = t
            end
        end
    end
    return m,r,rl
end

--[[
A basic lighting shader with a texture.
--]]
function lighting()
    local s = shader([[
    //
// A basic vertex shader
//

//This is the current model * view * projection matrix
// Codea sets it automatically
uniform mat4 modelViewProjection;
uniform mat4 invModel;
//This is the current mesh vertex position, color and tex coord
// Set automatically
attribute vec4 position;
attribute vec4 color;
attribute vec2 texCoord;
attribute vec3 normal;

//This is an output variable that will be passed to the fragment shader
varying lowp vec4 vColor;
varying highp vec2 vTexCoord;
varying highp vec3 vNormal;

void main()
{
    //Pass the mesh color to the fragment shader
    vColor = color;
    vTexCoord = texCoord;
    highp vec4 n = invModel * vec4(normal,0.);
    vNormal = n.xyz;
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
uniform highp vec3 light;
uniform lowp float ambient;
uniform lowp float useTexture;
uniform lowp float diffuse;
//The interpolated vertex color for this fragment
varying lowp vec4 vColor;

//The interpolated texture coordinate for this fragment
varying highp vec2 vTexCoord;
varying highp vec3 vNormal;

void main()
{
    //Sample the texture at the interpolated coordinate
    lowp vec4 col = vColor;//vec4(1.,0.,0.,1.);
    lowp float nml = dot(light, normalize(vNormal));
    col *= useTexture * texture2D( texture, vTexCoord ) + (1. - useTexture);
    nml += diffuse;
    nml /= 1. + diffuse;
    nml = max(0.,nml);

    lowp float c = ambient + (1.-ambient) * nml;
    col.xyz *= c;
    //Set the output color to the texture color
    gl_FragColor = col;
}

    ]]
    )
    -- set defaults
    s.useTexture = 0
    s.diffuse = 0
    s.ambient = .5
    return s
end

local exports = {
    lighting = lighting,
    addBlock = addBlock,
    addJewel = addJewel,
    addPyramid = addPyramid,
    addSphere = addSphere,
    addSphereSegment = addSphereSegment,
    addCylinder = addCylinder
}

if cmodule then
    cmodule.export(exports)
else
    for k,v in pairs(exports) do
        _G[k] = v
    end
end
