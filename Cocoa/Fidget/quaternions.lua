local quaternions = {}
local vec4 = vectors.vec4
local vec3 = vectors.vec3
local unpack4 = vec4().unpack
local unpack3 = vec3().unpack
local math_sqrt = math.sqrt
function quaternions.multiply(q1, q2)
    local q1w, q1x, q1y, q1z = unpack4(q1)
    local q2w, q2x, q2y, q2z = unpack4(q2) 
    return vec4(
        q1w * q2w - q1x * q2x - q1y * q2y - q1z * q2z,
        q1w * q2x + q1x * q2w + q1y * q2z - q1z * q2y,
        q1w * q2y - q1x * q2z + q1y * q2w + q1z * q2x,
        q1w * q2z + q1x * q2y - q1y * q2x + q1z * q2w
    )
end

function quaternions.toRotationMatrix3(q)
    local w, x, y, z = unpack4(q)

    local xx, yy, zz = x*x, y*y, z*z
    local xy, xz, yz = x*y, x*z, y*z
    local wx, wy, wz = w*x, w*y, w*z

    return matrices.mat3(
        vec3(1 - 2*(yy + zz), 2*(xy - wz),     2*(xz + wy)),
        vec3(2*(xy + wz),     1 - 2*(xx + zz), 2*(yz - wx)),
        vec3(2*(xz - wy),     2*(yz + wx),     1 - 2*(xx + yy))
    )
end

function quaternions.fromRotationMatrix3(R)
    local q = vec4(0, 0, 0, 0)
    local v11, v22, v33 = R.v11, R.v22, R.v33
    local trace = v11 + v22 + v33
    
    if trace > 0 then
        local s = 0.5 / math_sqrt(trace + 1.0)
        q = vec4(
            0.25 / s,            
            (R.v23 - R.v32) * s, 
            (R.v31 - R.v13) * s, 
            (R.v12 - R.v21) * s  
        )
    else
        if (v11 > v22) and (v11 > v33) then
            local s = 2 * math_sqrt(1 + v11 - v22 - v33)
            q = vec4(
                (R.v23 - R.v32) / s, 
                0.25 * s,            
                (R.v21 + R.v12) / s, 
                (R.v31 + R.v13) / s  
            )
        elseif v22 > v33 then
            local s = 2 * math_sqrt(1 + v22 - v11 - v33)
            q = vec4(
                (R.v31 - R.v13) / s, 
                (R.v21 + R.v12) / s, 
                0.25 * s,            
                (R.v32 + R.v23) / s  
            )
        else
            local s = 2 * math_sqrt(1 + v33 - v11 - v22)
            q = vec4(
                (R.v12 - R.v21) / s,
                (R.v31 + R.v13) / s,
                (R.v32 + R.v23) / s,
                0.25 * s             
            )
        end
    end

    return q 
end
local pihalf = -math.pi/2
function quaternions.toEulerAngles(q)
    return vec3(
    math.atan2(2*(q.x*q.y+q.z*q.w),1-2*(q.y^2 + q.z^2)),
    pihalf+2*math.atan2(math_sqrt(1+2*(q.x*q.z-q.y*q.w)),math_sqrt(1-2*(q.x*q.z-q.y*q.w))),
    math.atan2(2*(q.x*q.w + q.y*q.z),1-2*(q.z^2+q.w^2)))
end

function quaternions.fromEulerAngles(yaw, pitch, roll)
    if type(yaw) == "Vector3" then
        yaw,pitch,roll = unpack3(yaw)
    end
    local cy = math.cos(yaw * 0.5)
    local sy = math.sin(yaw * 0.5)
    local cp = math.cos(pitch * 0.5)
    local sp = math.sin(pitch * 0.5)
    local cr = math.cos(roll * 0.5)
    local sr = math.sin(roll * 0.5)

    local w = cy * cp * cr + sy * sp * sr
    local x = cy * cp * sr - sy * sp * cr
    local y = cy * sp * cr + sy * cp * sr
    local z = sy * cp * cr - cy * sp * sr

    return vec4(w, x, y, z)
end

return quaternions