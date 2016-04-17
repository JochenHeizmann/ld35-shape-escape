Strict

Import coreproc.io.psd
Import src.tiled
Import src.player
Import src.particle

Class MoveInOutFSM
    Const MOVE_IN := 0
    Const IDLE := 1
    Const MOVE_OUT := 2
    Const DONE := 3

    Field state%
    Field progress#
    Field speed# = 2.0
    Field delay# = 0.0

    Method Update:Void(dt#)
        Select state
            Case MOVE_IN
                If (delay > 0)
                    delay -= speed * dt
                Else
                    progress = Clamp(progress + speed * dt, 0.0, 1.0)
                    If (progress = 1.0) Then state = IDLE
                End

            Case MOVE_OUT
                progress = Clamp(progress - speed * dt, 0.0, 1.0)
                If (progress = 0.0) Then state = DONE
        End
    End

    Method Reset:Void()
        state = MOVE_IN
        progress = 0.0
        delay = 0.0
    End
End

Class BallObstacle
    Const ROTATION_SPEED# = 40.0
    Field x#
    Field y#
    Field height%
    Field stp#
End

Class GameState
    Const GRAVITY := 18

    Const GET_READY := 1
    Const RUNNING := 2
    Const TRANSFORMING := 4
    Const GAME_OVER := 8
    Const LEVEL_COMPLETED := 16
    Const GAME_COMPLETED := 32

    Field obstacles := New Stack<BallObstacle>

    Const MAX_COLLISION_ZONES := 100
    Field enemyZoneIdx := 0
    Field enemyZoneDynamicStart := 0
    Field enemyZones:Rect[]
    Field exitZone := New Rect

    Const MAX_PARTICLE_COUNT := 200
    Field particles:Particle[MAX_PARTICLE_COUNT]
    Field particleSprite:Sprite[3]

    Field state := RUNNING
    Field transformProgress#
    Field transformTo%

    Field moveInOut := New MoveInOutFSM()

    Field psd:PSD
    Field player := New Player()

    Const LEVELS := 7
    Field level% = 7
    
    Field map:TiledMap
    Field mapLookup%[]

    Field birdCount%
    Field frogCount%
    Field walkerCount%
    Field stoneCount%

    Field walkerHighlight:Sprite[]
    Field froggerHighlight:Sprite[]
    Field birdHighlight:Sprite[]
    Field stoneHighlight:Sprite[]

    Field bigBall:Sprite
    Field smallBall:Sprite

    Field sounds:Sound[3]
End
