FidgetMetatables = {}

--yes this is global. its used in other scripts of the lib instead of doing singular requires.
Fidget = {}
Fidget.physicsSim = require("Fidget.Physics Simulation Vars.Physics Simulation")
if Fidget.physicsSim.runBelowMax or (not Fidget.physicsSim.runBelowMax and avatar:getPermissionLevel() == "MAX") then
Fidget.rigidbodies, Fidget.particles  = require("Fidget.Rigidbody Init.Rigidbody")
Fidget.joints = require("Fidget.Rigidbody Init.Joints")
Fidget.links = require("Fidget.Rigidbody Init.Links")
Fidget.quaternions = require("Fidget.quaternions")
end
return Fidget