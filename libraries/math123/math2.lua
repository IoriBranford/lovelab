local math2 = {}

local Debug_atan0 = true
local Debug_norm0 = true

if Debug_atan0 then
    local atan2 = math.atan2

    function math2.atan2(y, x)
        assert(y ~= 0 or x ~= 0, "atan2(0,0)")
        return atan2(y, x)
    end
end

local abs = math.abs
local min = math.min
local max = math.max
local cos = math.cos
local sin = math.sin
local asin = math.asin
local sqrt = math.sqrt
local atan2 = math.atan2
local pi = math.pi
local huge = math.huge

function math2.vadd(x, y, a, b)
    return x+a, y+b
end

function math2.vsub(x, y, a, b)
    return x-a, y-b
end

function math2.vmul(x, y, a)
    return x*a, y*a
end

function math2.vdiv(x, y, a)
    return x/a, y/a
end

function math2.frompolar(a, d)
    d = d or 1
    return d*cos(a), d*sin(a)
end

function math2.topolar(x, y)
    local d = math2.len(x, y)
    local a = d == 0 and 0 or atan2(y, x)
    return a, d
end

function math2.dot(x, y, x2, y2)
    return x2*x + y2*y
end
local dot = math2.dot

function math2.det(x, y, x2, y2)
    return x*y2 - y*x2
end
local det = math2.det

function math2.lensq(x, y, z)
    z = z or 0
    return x*x+y*y+z*z
end
local lensq = math2.lensq

function math2.len(x, y, z)
    z = z or 0
    return sqrt(x*x + y*y + z*z)
end

function math2.distsq(x1, y1, x2, y2)
    local dx, dy = x2-x1, y2-y1
    return dx*dx + dy*dy, dx, dy
end
local distsq = math2.distsq

function math2.dist(x1, y1, x2, y2)
    local dx, dy = x2-x1, y2-y1
    return sqrt(dx*dx + dy*dy), dx, dy
end
local dist = math2.dist

function math2.norm(x, y)
    local l = sqrt(x*x + y*y)
    return x/l, y/l, l
end
if Debug_norm0 then
    local norm = math2.norm
    function math2.norm(x, y)
        assert(x ~= 0 or y ~= 0, "norm(0,0)")
        return norm(x, y)
    end
end
local norm = math2.norm

function math2.rescale(x, y, l)
    if x == 0 and y == 0 then
        return 0, 0
    end
    x, y = norm(x, y)
    return x*l, y*l
end

function math2.mid(x1, y1, x2, y2)
    return x1 + (x2 - x1)/2, y1 + (y2 - y1)/2
end

function math2.rot(x, y, a)
    local cosa, sina = cos(a), sin(a)
    return x*cosa - y*sina, y*cosa + x*sina
end
local rot = math2.rot

function math2.rot90(x, y, dir)
    if dir < 0 then
        return y, -x
    end
    return -y, x
end

function math2.rotunitvectortowards(ux, uy, destux, destuy, speed)
    speed = min(abs(speed), pi)
    if dot(ux, uy, destux, destuy) >= cos(speed) then
        return destux, destuy
    end
    if det(ux, uy, destux, destuy) < 0 then
        speed = -speed
    end
    return rot(ux, uy, speed)
end

function math2.rotangletowards(angle, dest, speed)
    local x, y = math2.rotunitvectortowards(cos(angle), sin(angle), cos(dest), sin(dest), speed)
    return atan2(y, x)
end

function math2.anglesdiff(a, b)
    local ax, ay = math2.frompolar(a)
    local bx, by = math2.frompolar(b)
    return asin(math2.det(ax, ay, bx, by))
end

function math2.clampangle(angle, center, arc)
    arc = arc or pi
    if not center or arc >= pi then
        return angle
    end
    local limitx, limity = math2.frompolar(center)
    local aimx, aimy = math2.frompolar(angle)
    if dot(limitx, limity, aimx, aimy) >= cos(arc) then
        return angle
    end
    if det(limitx, limity, aimx, aimy) < 0 then
        return center - arc
    end
    return center + arc
end

function math2.testrects(ax, ay, aw, ah, bx, by, bw, bh)
    if ax + aw < bx then return false end
    if bx + bw < ax then return false end
    if ay + ah < by then return false end
    if by + bh < ay then return false end
    return true
end

function math2.rectintersection(ax, ay, aw, ah, bx, by, bw, bh)
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

function math2.testcircles(ax, ay, ar, bx, by, br)
    local dx, dy = ax - bx, ay - by
    local dsq = lensq(dx, dy)
    local rr = ar + br
    local rrsq = rr * rr
    return dsq <= rrsq and dsq
end

---Barycentric coordinates of point p in triangle abc
---@return number? a how much is p outside edge bc; 1 = on the edge
---@return number? b how much is p outside edge ac; 1 = on the edge
---@return number? c how much is p outside edge ab; 1 = on the edge
function math2.bary(px, py, ax, ay, bx, by, cx, cy)
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

function math2.frombary(a, b, c, ax, ay, bx, by, cx, cy)
    local x = a*ax + b*bx + c*cx
    local y = a*ay + b*by + c*cy
    return x, y
end

---@param points number[] Every 2 elements is 1 point
---@param x number
---@param y number
function math2.pointinpolygon(points, x, y)
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

---@param points number[] Every 2 is a point
function math2.nearestpolylinepoint(points, x, y, i1, j1)
    i1 = i1 or 2
    j1 = j1 or (i1 + 2)
    local i = i1
    local x1, y1 = points[i-1], points[i]
    local nearestx, nearesty, nearesti, nearestj
    local nearestdsq = huge
    for j = j1, #points, 2 do
        local x2, y2 = points[j-1], points[j]
        local projx, projy = math2.projpointsegment(x, y, x1, y1, x2, y2)
        local dsq = distsq(x, y, projx, projy)
        if dsq < nearestdsq then
            nearestx, nearesty, nearestdsq = projx, projy, dsq
            nearesti, nearestj = i, j
        end
        x1, y1, i = x2, y2, j
    end
    return nearestx, nearesty, nearesti, nearestj
end

function math2.nearestpolygonpoint(polygon, x, y)
    return math2.nearestpolylinepoint(polygon, x, y, #polygon, 2)
end

---Gets point on line through (ax, ay) and (bx, by) that is closest to point (px, py)
---@return number projx closest point on segment x
---@return number projy closest point on segment y
function math2.projpointline(px, py, ax, ay, bx, by)
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
function math2.reflect(vx, vy, nx, ny)
    local projx, projy = math2.projpointline(vx, vy, 0, 0, nx, ny)
    return vx - 2*projx, vy - 2*projy
end

---Gets point on line segment from (ax, ay) to (bx, by) that is closest to point (px, py)
---@return number projx closest point on segment x
---@return number projy closest point on segment y
function math2.projpointsegment(px, py, ax, ay, bx, by)
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
local projpointsegment = math2.projpointsegment

---@param points number[] Every 2 elements is 1 point
---@param x number
---@param y number
function math2.keeppointinpolygon(points, x, y)
    local inside = false
    local i = #points
    local x1, y1 = points[i-1], points[i]
    local nearestx, nearesty, nearesti, nearestj
    local nearestdsq = huge
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

function math2.polysignedarea(points)
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
function math2.meancenter(points)
    local cx, cy = 0, 0
    for i = 2, #points, 2 do
        cx = cx + points[i-1]
        cy = cy + points[i]
    end
    local n = #points/2
    return cx/n, cy/n
end

---@param points number[] every 2 is a 2D point
function math2.centerofgrav(points)
    local cx, cy = 0, 0
    local x1, y1 = points[#points-1], points[#points]
    for i = 2, #points, 2 do
        local x2, y2 = points[i-1], points[i]
        local d = det(x1, y1, x2, y2)
        cx = cx + d * (x1 + x2)
        cy = cy + d * (y1 + y2)
        x1, y1 = x2, y2
    end
    local sareaX6 = math2.polysignedarea(points)*6
    return cx/sareaX6, cy/sareaX6
end

---@return number centerx
---@return number centery
---@return number radius
function math2.boundingcircle(points)
    local cx, cy = math2.meancenter(points)
    local rsq = 0
    for i = 2, #points, 2 do
        rsq = max(rsq, math2.distsq(points[i-1], points[i], cx, cy))
    end
    return cx, cy, sqrt(rsq)
end

function math2.boundingbox(points)
    local px1, py1, px2, py2 = huge, huge, -huge, -huge
    for i = 2, #points, 2 do
        local px, py = points[i-1], points[i]
        px1 = min(px1, px)
        py1 = min(py1, py)
        px2 = max(px2, px)
        py2 = max(py2, py)
    end
    return px1, py1, px2, py2
end

function math2.farthestpoint(points, x, y)
    local fari, fardsq = nil, -1
    for i = 2, #points, 2 do
        local dsq = distsq(x, y, points[i-1], points[i])
        if dsq > fardsq then
            fari, fardsq = i, dsq
        end
    end
    return fari, fardsq
end

function math2.testpointtri(px, py, ax, ay, bx, by, cx, cy)
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

function math2.testsegments(ax, ay, bx, by, cx, cy, dx, dy)
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
            math2.rectintersection(ax, ay, bx, by, cx, cy, dx, dy) ~= nil
    end
    local cax, cay = ax-cx, ay-cy
    local s = det(abx, aby, cax, cay)/div
    local t = det(cdx, cdy, cax, cay)/div
    return s >= 0 and s <= 1 and t >= 0 and t <= 1
end

function math2.intersectsegments(ax, ay, bx, by, cx, cy, dx, dy)
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
        local ix, iy, iw, ih = math2.rectintersection(
            abminx, abminy,
            abs(abx), abs(aby),
            cdminx, cdminy,
            abs(cdx), abs(cdy))
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

-- DEBUG
-- print(math2.intersectsegments(2,1,4,5,1,4,5,2)) -- should be 3,3

function math2.intersectlines(ax, ay, bx, by, cx, cy, dx, dy)
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

function math2.polylinelen(points, i, j)
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

function math2.polylinesegmentslen(points, i, j)
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

function math2.polylinesegmentslengths(points, i, j)
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

---@param points number[]
---@param x number? walker x
---@param y number? walker y
---@param i integer?
---@param speed number? default 1, sign indicates forward or backward
---@param stop integer?
---@return number x
---@return number y
---@return integer i
function math2.walkpolyline(points, x, y, i, speed, stop)
    local n = #points
    i = max(2, min(i or 2, n))
    x = x or points[i-1]
    y = y or points[i]

    speed = speed or 0
    local backward = speed < 0
    speed = abs(speed)

    local px, py = points[i-1], points[i]
    local d, dx, dy = math2.dist(x, y, px, py)
    if d > speed then
        speed = speed / d
        return x + dx * speed, y + dy * speed, i
    end

    stop = stop or (backward and 2 or n)
    stop = max(2, min(stop, n))
    if stop == i then
        return px, py, i
    end

    i = i + (backward and -2 or 2)
    speed = speed - d
    return math2.walkpolyline(points, px, py,
        i, backward and -speed or speed, stop)
end

---https://en.wikipedia.org/wiki/Hypotrochoid
function math2.hypertrochoid(a, r1, r2, d)
    local dr = r2-r1
    local drDr = dr/r1
    local cosa = cos(a)
    local sina = sin(a)

    local aXdrDr = a*drDr
    local cosaXdrDr = cos(aXdrDr)
    local sinaXdrDr = sin(aXdrDr)
    local x = dr*cosa + d*cosaXdrDr
    local y = dr*sina - d*sinaXdrDr
    return x, y
end

return math2