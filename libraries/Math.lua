local min = math.min
local max = math.max
local cos = math.cos
local sin = math.sin
local rad = math.rad
local sqrt = math.sqrt
local modf = math.modf

local Debug_atan0 = true
local Debug_norm0 = true
local Debug_acosOutOfRange = true

if Debug_acosOutOfRange then
    local acos = math.acos
    function math.acos(x)
        assert(-1 <= x and x <= 1, "acos(|x| > 1)")
        return acos(x)
    end
end

if Debug_atan0 then
    local atan2 = math.atan2

    function math.atan2(y, x)
        assert(y ~= 0 or x ~= 0, "atan2(0,0)")
        return atan2(y, x)
    end
end

function math.round(x)
    local i, f = modf(x)
    if x < 0 then
        return f > -0.5 and i or i - 1
    end
    return f < 0.5 and i or i + 1
end

function math.clamp(x, a, b)
    return max(a, min(x, b))
end

function math.frompolar(a, d)
    d = d or 1
    return d*cos(a), d*sin(a)
end

function math.topolar(x, y)
    local d = math.len(x, y)
    local a = d == 0 and 0 or math.atan2(y, x)
    return a, d
end

function math.fromspherical(axy, az, d)
    local x, y = math.frompolar(axy, d)
    local sinz = sin(az)
    return x*sinz, y*sinz, d*cos(az)
end

function math.tospherical(x, y, z)
    local d = math.len(x, y, z)
    local axy, dxy = math.topolar(x, y)
    local xy = y < 0 and -dxy or dxy
    local az = z == 0 and xy == 0 and 0
        or math.atan2(xy, z)
    return axy, az, d
end

function math.rescale(x, y, l)
    if x == 0 and y == 0 then
        return 0, 0
    end
    x, y = math.norm(x, y)
    return x*l, y*l
end

function math.rescale3(x, y, z, l)
    if x == 0 and y == 0 and z == 0 then
        return 0, 0, 0
    end
    x, y, z = math.norm(x, y, z)
    return x*l, y*l, z*l
end

function math.clampangle(angle, center, arc)
    arc = arc or math.pi
    if not center or arc >= math.pi then
        return angle
    end
    local limitx, limity = math.frompolar(center)
    local aimx, aimy = math.frompolar(angle)
    if math.dot(limitx, limity, aimx, aimy) >= math.cos(arc) then
        return angle
    end
    if math.det(limitx, limity, aimx, aimy) < 0 then
        return center - arc
    end
    return center + arc
end

function math.anglesdiff(a, b)
    local ax, ay = math.frompolar(a)
    local bx, by = math.frompolar(b)
    return math.asin(math.det(ax, ay, bx, by))
end

function math.dot(x, y, x2, y2)
    return x2*x + y2*y
end
local dot = math.dot

function math.dot3(x, y, z, x2, y2, z2)
    return x2*x + y2*y + z2*z
end

function math.det(x, y, x2, y2)
    return x*y2 - y*x2
end
local det = math.det

function math.cross(x, y, z, x2, y2, z2)
    return det(y, z, y2, z2),
        det(z, x, z2, x2),
        det(x, y, x2, y2)
end

function math.lensq(x, y, z)
    z = z or 0
    return x*x+y*y+z*z
end
local lensq = math.lensq

function math.distsq(x1, y1, x2, y2)
    local dx, dy = x2-x1, y2-y1
    return dx*dx + dy*dy
end
local distsq = math.distsq

function math.distsq3(x1, y1, z1, x2, y2, z2)
    local dx, dy, dz = x2-x1, y2-y1, z2-z1
    return dx*dx + dy*dy + dz*dz
end

function math.dist(x1, y1, x2, y2)
    local dx, dy = x2-x1, y2-y1
    return sqrt(dx*dx + dy*dy)
end
local dist = math.dist

function math.dist3(x1, y1, z1, x2, y2, z2)
    local dx, dy, dz = x2-x1, y2-y1, z2-z1
    return sqrt(dx*dx + dy*dy + dz*dz)
end

function math.len(x, y, z)
    z = z or 0
    return sqrt(x*x + y*y + z*z)
end

function math.lerp(t, a, b)
    return a + t*(b-a)
end

function math.norm(x, y, z)
    z = z or 0
    local len = sqrt(x*x + y*y + z*z)
    return x/len, y/len, z/len
end

function math.lennorm(x, y, z)
    z = z or 0
    local len = sqrt(x*x + y*y + z*z)
    return len, x/len, y/len, z/len
end

if Debug_norm0 then
    local norm = math.norm
    function math.norm(x, y, z)
        assert(x ~= 0 or y ~= 0 or z ~= 0, "norm(0,0,0)")
        return norm(x, y, z)
    end
end

function math.mid(x1, y1, x2, y2)
    return x1 + (x2 - x1)/2, y1 + (y2 - y1)/2
end

function math.rot(x, y, a)
    local cosa, sina = cos(a), sin(a)
    return x*cosa - y*sina, y*cosa + x*sina
end

function math.rotunitvectortowards(ux, uy, destux, destuy, speed)
    speed = math.min(math.abs(speed), math.pi)
    if math.dot(ux, uy, destux, destuy) >= math.cos(speed) then
        return destux, destuy
    end
    if math.det(ux, uy, destux, destuy) < 0 then
        speed = -speed
    end
    return math.rot(ux, uy, speed)
end

function math.rotangletowards(angle, dest, speed)
    local x, y = math.rotunitvectortowards(cos(angle), sin(angle), cos(dest), sin(dest), speed)
    return math.atan2(y, x)
end

function math.rot90(x, y, dir)
    if dir < 0 then
        return y, -x
    end
    return -y, x
end

function math.testrects(ax, ay, aw, ah, bx, by, bw, bh)
    if ax + aw < bx then return false end
    if bx + bw < ax then return false end
    if ay + ah < by then return false end
    if by + bh < ay then return false end
    return true
end

function math.rectintersection(ax, ay, aw, ah, bx, by, bw, bh)
    local ax2 = ax + aw
    if ax2 < bx then return end
    local bx2 = bx + bw
    if bx2 < ax then return end
    local ay2 = ay + ah
    if ay2 < by then return end
    local by2 = by + bh
    if by2 < ay then return end
    local ix = max(ax, bx)
    local iy = max(ay, by)
    local ix2 = min(ax2, bx2)
    local iy2 = min(ay2, by2)
    return ix, iy, ix2-ix, iy2-iy
end

function math.testcircles(ax, ay, ar, bx, by, br)
    local dx, dy = ax - bx, ay - by
    local distsq = lensq(dx, dy)
    local radii = ar + br
    local radiisq = radii * radii
    return distsq <= radiisq and distsq
end

---Barycentric coordinates of point p in triangle abc
---@return number? a how much is p outside edge bc; 1 = on the edge
---@return number? b how much is p outside edge ac; 1 = on the edge
---@return number? c how much is p outside edge ab; 1 = on the edge
function math.bary(px, py, ax, ay, bx, by, cx, cy)
    local acx, acy = cx - ax, cy - ay
    local abx, aby = bx - ax, by - ay
    local apx, apy = px - ax, py - ay

    local div = det(abx, aby, acx, acy)
    if div == 0 then
        return
    end

    local b = det(apx, apy, acx, acy) / div
    local c = det(abx, aby, apx, apy) / div
    return 1-b-c, b, c
end

function math.frombary(a, b, c, ax, ay, bx, by, cx, cy)
    local x = a*ax + b*bx + c*cx
    local y = a*ay + b*by + c*cy
    return x, y
end

---@param points number[] Every 2 elements is 1 point
---@param x number
---@param y number
function math.pointinpolygon(points, x, y)
    local inside = false
    local x1, y1 = points[#points-1], points[#points]
    for i = 2, #points, 2 do
        local x2, y2 = points[i-1], points[i]
        if y > min(y1, y2) then
            if y <= max(y1, y2) then
                if x <= max(x1, x2) then
                    local hitx = (y - y1) * (x2 - x1) / (y2 - y1) + x1;
                    if x1 == x2 or x <= hitx then
                        inside = not inside
                    end
                end
            end
        end
        x1, y1 = x2, y2
    end
    return inside
end

---@param polyline number[] Every 2 is a point
function math.nearestpolylinepoint(polyline, x, y, starti, startj)
    starti = starti or 2
    startj = startj or (starti + 2)
    local i = starti
    local x1, y1 = polyline[i-1], polyline[i]
    local nearestx, nearesty, nearesti, nearestj
    local nearestdsq = math.huge
    for j = startj, #polyline, 2 do
        local x2, y2 = polyline[j-1], polyline[j]
        local projx, projy = math.projpointsegment(x, y, x1, y1, x2, y2)
        local dsq = math.distsq(x, y, projx, projy)
        if dsq < nearestdsq then
            nearestx, nearesty, nearestdsq = projx, projy, dsq
            nearesti, nearestj = i, j
        end
        x1, y1, i = x2, y2, j
    end
    return nearestx, nearesty, nearesti, nearestj
end

function math.nearestpolygonpoint(polygon, x, y)
    return math.nearestpolylinepoint(polygon, x, y, #polygon, 2)
end

---Gets point on line through (ax, ay) and (bx, by) that is closest to point (px, py)
---@return number projx closest point on segment x
---@return number projy closest point on segment y
function math.projpointline(px, py, ax, ay, bx, by)
    local abx, aby = bx-ax, by-ay
    if abx == 0 and aby == 0 then
        return ax, ay
    end
    local apx, apy = px-ax, py-ay
    local t = dot(apx, apy, abx, aby)
    local ablensq = lensq(abx, aby)
    t = t / ablensq
    return ax + t*abx, ay + t*aby
end

---@param vx number vector to reflect
---@param vy number vector to reflect
---@param nx number vector out of surface to reflect against
---@param ny number vector out of surface to reflect against
function math.reflect(vx, vy, nx, ny)
    local projx, projy = math.projpointline(vx, vy, 0, 0, nx, ny)
    return vx - 2*projx, vy - 2*projy
end

---Gets point on line segment from (ax, ay) to (bx, by) that is closest to point (px, py)
---@return number projx closest point on segment x
---@return number projy closest point on segment y
function math.projpointsegment(px, py, ax, ay, bx, by)
    local apx, apy = px-ax, py-ay
    local abx, aby = bx-ax, by-ay
    local t = dot(apx, apy, abx, aby)
    if t <= 0 then
        return ax, ay
    end
    local ablensq = lensq(abx, aby)
    if t >= ablensq then
        return bx, by
    end
    t = t / ablensq
    return ax + t*abx, ay + t*aby
end
local projpointsegment = math.projpointsegment

---@param points number[] Every 2 elements is 1 point
---@param x number
---@param y number
function math.keeppointinpolygon(points, x, y)
    local inside = false
    local i = #points
    local x1, y1 = points[i-1], points[i]
    local nearestx, nearesty, nearesti, nearestj
    local nearestdsq = math.huge
    for j = 2, #points, 2 do
        local x2, y2 = points[j-1], points[j]
        local projx, projy = projpointsegment(x, y, x1, y1, x2, y2)
        local dsq = distsq(x, y, projx, projy)
        if dsq < nearestdsq then
            nearestx, nearesty, nearestdsq = projx, projy, dsq
            nearesti, nearestj = i, j
        end
        if y > min(y1, y2) then
            if y <= max(y1, y2) then
                if x <= max(x1, x2) then
                    local hitx = (y - y1) * (x2 - x1) / (y2 - y1) + x1
                    if x1 == x2 or x <= hitx then
                        inside = not inside
                    end
                end
            end
        end
        x1, y1, i = x2, y2, j
    end
    if inside then
        nearestx, nearesty = x, y
    end
    return nearestx, nearesty, nearesti, nearestj
end

function math.polysignedarea(points)
    local doublearea = 0
    local x1, y1 = points[#points-1], points[#points]
    for i = 2, #points, 2 do
        local x2, y2 = points[i-1], points[i]
        doublearea = doublearea + det(x1, y1, x2, y2)
        x1, y1 = x2, y2
    end
    return doublearea/2
end

---@param points number[] every 2 is a 2D point
function math.meancenter(points)
    local cx, cy = 0, 0
    for i = 2, #points, 2 do
        cx = cx + points[i-1]
        cy = cy + points[i]
    end
    local n = #points/2
    return cx/n, cy/n
end

---@param points number[] every 2 is a 2D point
function math.centerofgrav(points)
    local cx, cy = 0, 0
    local x1, y1 = points[#points-1], points[#points]
    for i = 2, #points, 2 do
        local x2, y2 = points[i-1], points[i]
        local d = det(x1, y1, x2, y2)
        cx = cx + d * (x1 + x2)
        cy = cy + d * (y1 + y2)
        x1, y1 = x2, y2
    end
    local sareaX6 = math.polysignedarea(points)*6
    return cx/sareaX6, cy/sareaX6
end

---@return number centerx
---@return number centery
---@return number radius
function math.boundingcircle(points)
    local cx, cy = math.meancenter(points)
    local rsq = 0
    for i = 2, #points, 2 do
        rsq = max(rsq, math.distsq(points[i-1], points[i], cx, cy))
    end
    return cx, cy, sqrt(rsq)
end

function math.boundingbox(points)
    local px1, py1, px2, py2 = math.huge, math.huge, -math.huge, -math.huge
    for i = 2, #points, 2 do
        local px, py = points[i-1], points[i]
        px1 = math.min(px1, px)
        py1 = math.min(py1, py)
        px2 = math.max(px2, px)
        py2 = math.max(py2, py)
    end
    return px1, py1, px2, py2
end

function math.farthestpoint(points, x, y)
    local fari, fardsq = nil, -1
    for i = 2, #points, 2 do
        local dsq = math.distsq(x, y, points[i-1], points[i])
        if dsq > fardsq then
            fari, fardsq = i, dsq
        end
    end
    return fari, fardsq
end

function math.testpointtri(px, py, ax, ay, bx, by, cx, cy)
    local acx, acy = cx - ax, cy - ay
    local abx, aby = bx - ax, by - ay
    local apx, apy = px - ax, py - ay

    local area = det(abx, aby, acx, acy)
    local ac = det(apx, apy, acx, acy)
    local ab = det(abx, aby, apx, apy)
    if area < 0 then
        return ac <= 0 and ab <= 0 and ac + ab >= area
    end
    return ac >= 0 and ab >= 0 and ac + ab <= area
end

function math.testsegments(ax, ay, bx, by, cx, cy, dx, dy)
    if ax == cx and ay == cy or ax == dx and ay == dy
    or bx == cx and by == cy or bx == dx and by == dy then
        return true
    end
    local abx = bx-ax
    local aby = by-ay
    local cdx = dx-cx
    local cdy = dy-cy
    local div = det(abx, aby, cdx, cdy)
    if div == 0 then
        return det(abx, aby, cx-ax, cy-ay) == 0 and
            math.rectintersection(ax, ay, bx, by, cx, cy, dx, dy) ~= nil
    end
    local cax, cay = ax-cx, ay-cy
    local s = det(abx, aby, cax, cay)/div
    local t = det(cdx, cdy, cax, cay)/div
    return s >= 0 and s <= 1 and t >= 0 and t <= 1
end

function math.intersectsegments(ax, ay, bx, by, cx, cy, dx, dy)
    if ax == cx and ay == cy or ax == dx and ay == dy then
        return ax, ay
    end
    if bx == cx and by == cy or bx == dx and by == dy then
        return bx, by
    end
    local abx = bx-ax
    local aby = by-ay
    local cdx = dx-cx
    local cdy = dy-cy
    local div = det(abx, aby, cdx, cdy)
    if div == 0 then
        if det(abx, aby, cx-ax, cy-ay) ~= 0 then
            return
        end
        local abminx = min(ax, bx)
        local abminy = abminx == ax and ay or by
        local cdminx = min(cx, dx)
        local cdminy = cdminx == cx and cy or dy
        local ix, iy, iw, ih = math.rectintersection(
            abminx, abminy,
            math.abs(abx), math.abs(aby),
            cdminx, cdminy,
            math.abs(cdx), math.abs(cdy))
        if not ix then
            return
        end
        return ix, iy, ix+iw, iy+ih
    end
    local cax, cay = ax-cx, ay-cy
    local s = det(abx, aby, cax, cay)/div
    local t = det(cdx, cdy, cax, cay)/div
    if s >= 0 and s <= 1 and t >= 0 and t <= 1 then
        local x = ax + abx*t
        local y = ay + aby*t
        return x, y
    end
end

function math.lenpolyline(points, i, j)
    i = max(2, i or 2)
    j = min(j or #points, #points)
    local len = 0
    local x1 = points[i-1]
    local y1 = points[i]
    for p = i+2, j, 2 do
        local x2 = points[p-1]
        local y2 = points[p]
        len = len + dist(x1, y1, x2, y2)
        x1, y1 = x2, y2
    end
    return len
end

-- DEBUG
-- print(math.intersectsegments(2,1,4,5,1,4,5,2)) -- should be 3,3

function math.intersectlines(ax, ay, bx, by, cx, cy, dx, dy)
    local bax = ax-bx
    local bay = ay-by
    local dcx = cx-dx
    local dcy = cy-dy
    local div = det(bax, dcx, bay, dcy)
    if div == 0 then
        return
    end
    local cax, cay = ax-cx, ay-cy
    local t = det(cax, dcx, cay, dcy) / div
    local x = ax - t*bax
    local y = ay - t*bay
    return x, y
end

---@param x number point
---@param y number point
---@param z number point
---@param nx number plane normal
---@param ny number plane normal
---@param nz number plane normal
---@param d number plane distance from origin along plane normal
function math.pointsigneddistfromplane(x, y, z, nx, ny, nz, d)
    return math.dot3(x, y, z, nx, ny, nz) + d
end

--- @param px number point on the plane
--- @param py number point on the plane
--- @param pz number point on the plane
--- @param nx number plane normal
--- @param ny number plane normal
--- @param nz number plane normal
--- @return number d the d component of the plane equation nx\*x + ny\*y + nz\*z + d == 0
function math.planedistfrom0(px, py, pz, nx, ny, nz)
    return -math.dot3(px, py, pz, nx, ny, nz)
end

---@param x number point
---@param y number point
---@param z number point
---@param nx number plane normal
---@param ny number plane normal
---@param nz number plane normal
---@param d number plane distance from origin along plane normal
function math.projpointplane(x, y, z, nx, ny, nz, d)
    local sdist = math.pointsigneddistfromplane(x, y, z, nx, ny, nz, d)
    return x - sdist*nx, y - sdist*ny, z - sdist*nz
end

---@param ax number point a on the line
---@param ay number point a on the line
---@param az number point a on the line
---@param bx number point b on the line
---@param by number point b on the line
---@param bz number point b on the line
---@param nx number plane normal
---@param ny number plane normal
---@param nz number plane normal
---@param d number plane signed dist from origin
---@return number? t line segment length from point a to the plane intersection. nil if no intersection. math.huge if the whole line is on the plane
function math.lineplaneintersectdist(ax, ay, az, bx, by, bz, nx, ny, nz, d)
    local ad = math.pointsigneddistfromplane(ax, ay, az, nx, ny, nz, d)
    if ax == bx and ay == by and az == bz then
        return ad == 0 and 0 or nil
    end
    local lx, ly, lz = math.norm(bx - ax, by - ay, bz - az)
    local ldotn = math.dot3(lx, ly, lz, nx, ny, nz)
    if ldotn == 0 then
        return ad == 0 and math.huge or nil
    end
    -- dot3(ax+lx*t, ay+ly*t, az+lz*t, nx, ny, nz) + d == 0
    -- nx*ax + nx*lx*t + ny*ay + ny*ly*t + nz*az + nz*lz*t + d = 0
    -- nx*lx*t + ny*ly*t + nz*lz*t = -nx*ax - ny*ay - nz*az - d
    -- t * (nx*lx + ny*ly + nz*lz) = -nx*ax - ny*ay - nz*az - d
    -- t = (-nx*ax - ny*ay - nz*az - d) / (nx*lx + ny*ly + nz*lz)
    return -ad / ldotn, lx, ly, lz
end

function math.intersectlineplane(ax, ay, az, bx, by, bz, nx, ny, nz, d)
    local t, lx, ly, lz = math.lineplaneintersectdist(ax, ay, az, bx, by, bz, nx, ny, nz, d)
    if not t then return end
    if t == 0 then
        return ax, ay, az
    end
    if t == math.huge then
        return ax, ay, az, bx, by, bz
    end
    return ax + lx*t, ay + ly*t, az + lz*t
end

function math.intersectsegmentplane(ax, ay, az, bx, by, bz, nx, ny, nz, d)
    local t, lx, ly, lz = math.lineplaneintersectdist(ax, ay, az, bx, by, bz, nx, ny, nz, d)
    if not t then return end
    if t == 0 then
        return ax, ay, az
    end
    if t == math.huge then
        return ax, ay, az, bx, by, bz
    end
    if 0 < t and t*t <= math.distsq3(ax, ay, az, bx, by, bz) then
        return ax + lx*t, ay + ly*t, az + lz*t
    end
end

function math.table_rad(t, k)
    local x = t[k]
    if type(x) == "number" then
        t[k] = rad(x)
    end
end