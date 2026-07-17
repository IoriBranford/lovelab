local math3 = {}
local math2 = require "math123.math2"

local det = math2.det
local sqrt = math.sqrt
local cos = math.cos
local sin = math.sin

function math3.dot(x, y, z, x2, y2, z2)
    return x2*x + y2*y + z2*z
end

function math3.cross(x, y, z, x2, y2, z2)
    return det(y, z, y2, z2),
        det(z, x, z2, x2),
        det(x, y, x2, y2)
end

function math3.lensq(x, y, z)
    return x*x+y*y+z*z
end

function math3.len(x, y, z)
    return sqrt(x*x + y*y + z*z)
end

function math3.norm(x, y, z)
    local l = sqrt(x*x + y*y + z*z)
    return x/l, y/l, z/l, l
end

function math3.rescale(x, y, z, l)
    if x == 0 and y == 0 and z == 0 then
        return 0, 0, 0
    end
    x, y, z = math3.norm(x, y, z)
    return x*l, y*l, z*l
end

function math3.distsq(x1, y1, z1, x2, y2, z2)
    local dx, dy, dz = x2-x1, y2-y1, z2-z1
    return dx*dx + dy*dy + dz*dz, dx, dy, dz
end

function math3.dist(x1, y1, z1, x2, y2, z2)
    local dx, dy, dz = x2-x1, y2-y1, z2-z1
    return sqrt(dx*dx + dy*dy + dz*dz), dx, dy, dz
end

function math3.fromspherical(axy, az, d)
    local x, y = math2.frompolar(axy, d)
    local sinz = sin(az)
    return x*sinz, y*sinz, d*cos(az)
end

function math3.tospherical(x, y, z)
    local d = math3.len(x, y, z)
    local axy, dxy = math2.topolar(x, y)
    local xy = y < 0 and -dxy or dxy
    local az = z == 0 and xy == 0 and 0
        or math.atan2(xy, z)
    return axy, az, d
end

---@param x number point
---@param y number point
---@param z number point
---@param nx number plane normal
---@param ny number plane normal
---@param nz number plane normal
---@param d number plane distance from origin along plane normal
function math3.pointsigneddistfromplane(x, y, z, nx, ny, nz, d)
    return math3.dot(x, y, z, nx, ny, nz) + d
end

--- @param px number point on the plane
--- @param py number point on the plane
--- @param pz number point on the plane
--- @param nx number plane normal
--- @param ny number plane normal
--- @param nz number plane normal
--- @return number d the d component of the plane equation nx\*x + ny\*y + nz\*z + d == 0
function math3.planedistfrom0(px, py, pz, nx, ny, nz)
    return -math3.dot(px, py, pz, nx, ny, nz)
end

---@param x number point
---@param y number point
---@param z number point
---@param nx number plane normal
---@param ny number plane normal
---@param nz number plane normal
---@param d number plane distance from origin along plane normal
function math3.projpointplane(x, y, z, nx, ny, nz, d)
    local sdist = math3.pointsigneddistfromplane(x, y, z, nx, ny, nz, d)
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
---@return number? lx
---@return number? ly
---@return number? lz
function math3.lineplaneintersectdist(ax, ay, az, bx, by, bz, nx, ny, nz, d)
    local ad = math3.pointsigneddistfromplane(ax, ay, az, nx, ny, nz, d)
    if ax == bx and ay == by and az == bz then
        return ad == 0 and 0 or nil
    end
    local lx, ly, lz = math3.norm(bx - ax, by - ay, bz - az)
    local ldotn = math3.dot(lx, ly, lz, nx, ny, nz)
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

function math3.intersectlineplane(ax, ay, az, bx, by, bz, nx, ny, nz, d)
    local t, lx, ly, lz = math3.lineplaneintersectdist(ax, ay, az, bx, by, bz, nx, ny, nz, d)
    if not t then return end
    if t == 0 then
        return ax, ay, az
    end
    if t == math.huge then
        return ax, ay, az, bx, by, bz
    end
    return ax + lx*t, ay + ly*t, az + lz*t
end

function math3.intersectsegmentplane(ax, ay, az, bx, by, bz, nx, ny, nz, d)
    local t, lx, ly, lz = math3.lineplaneintersectdist(ax, ay, az, bx, by, bz, nx, ny, nz, d)
    if not t then return end
    if t == 0 then
        return ax, ay, az
    end
    if t == math.huge then
        return ax, ay, az, bx, by, bz
    end
    if 0 < t and t*t <= math3.distsq(ax, ay, az, bx, by, bz) then
        return ax + lx*t, ay + ly*t, az + lz*t
    end
end

return math3