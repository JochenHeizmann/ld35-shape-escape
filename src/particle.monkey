Strict

Class Particle
    Const GRAVITY := 0.25
    Const LIFETIME := 1.25

    Field active? = False
    Field lifeTime#
    Field x#
    Field y#
    Field vx#
    Field vy#    
    Field type%
End

Function LaunchParticles:Void(particles:Particle[], x#, y#, particleCount%, particleType%)
    For Local i := 0 Until particles.Length()
        Local p := particles[i]
        If (p.active = False)
            p.active = True
            p.lifeTime = Particle.LIFETIME
            p.x = x 
            p.y = y
            p.vx = Rnd(-3, 3)
            p.vy = Rnd(-4.0, 1)
            p.type = particleType
            particleCount -= 1
        End
        If (particleCount <= 0) Then Return
    Next
End