Strict

Import src.gameinput
Import src.gamestate
Import src.blocktypes

Class Player
    Const CHAR_WALKER := 0
    Const CHAR_FROG := 1
    Const CHAR_BIRD := 2
    Const CHAR_STONE := 3
    Const CHAR_NUM := 4

    Const LEFT% = -1
    Const RIGHT% = 1    

    Field walker:Sprite[]
    Field frogger:Sprite[]
    Field bird:Sprite[]
    Field stone:Sprite[]
    Field currentFrame#

    Field x#
    Field y#
    Field vx# = 1.0
    Field vy#
    Field w# = 16.0
    Field h# = 16.0
    Field charType% = 0
    Field direction% = RIGHT
    Field friction := True
    Field gravity := True
    Field invincible := False
    Field highlight := False
    Const FROG_IDLE_TIME := 2.0
    Field waitForJumpCounter# = FROG_IDLE_TIME
End

Function InitWalker:Void(p:Player)
    p.vx = 60.0
    Local oh := p.h    
    p.w = p.walker[0].atlasW
    p.h = p.walker[0].atlasH
    p.y -= p.h-oh
    p.charType = Player.CHAR_WALKER
    p.friction = True
    p.gravity = True
    p.invincible = False
    p.currentFrame = 0
End

Function InitFrog:Void(p:Player)
    Local oh := p.h    
    p.w = p.frogger[0].atlasW
    p.h = p.frogger[0].atlasH
    p.y -= p.h-oh
    p.charType = Player.CHAR_FROG
    p.friction = False
    p.gravity = True
    p.charType = Player.CHAR_FROG
    p.waitForJumpCounter = 0'Player.FROG_IDLE_TIME
    p.invincible = False
    p.currentFrame = 0
End

Function InitBird:Void(p:Player)
    Local oh := p.h    
    p.w = p.bird[0].atlasW
    p.h = p.bird[0].atlasH
''    p.y -= p.h-oh
    p.friction = True
    p.vx = 60.0
    p.vy = -60.0
    p.gravity = False
    p.charType = Player.CHAR_BIRD
    p.invincible = False
    p.currentFrame = 0
End

Function InitStone:Void(p:Player)
    Local oh := p.h
    p.w = p.stone[0].atlasW
    p.h = p.stone[0].atlasH
    p.y -= p.h - oh
    p.friction = False
    p.vx = 0
    p.vy = 0
    p.gravity = True
    p.charType = Player.CHAR_STONE
    p.invincible = True
    p.currentFrame = 0
End

Function UpdatePlayer:Void(p:Player, input:GameInput, state:GameState)
    If (p.gravity) Then p.vy += GameState.GRAVITY

    Local pvx := p.vx * input.dt
    Local pvy := p.vy * input.dt

    Local steps := Max(Ceil(Abs(pvx)), Ceil(Abs(pvy)))

    Local pvx_step := pvx / steps
    Local pvy_step := pvy / steps

    Local mapLayer := GetMapLayerByName(state.map, "map")
    Local tw := state.map.tileWidth
    Local th := state.map.tileHeight
    Local mx%, my%
    Local oldX#, oldY#
    Local blockType%
    For Local i := 0 Until steps
        oldX = p.x
        oldY = p.y

        If (i = (steps-1)) Then pvx_step = pvx ; pvy_step = pvy

        ' check <---> X

        p.x += p.direction * pvx_step


        If (p.direction = Player.RIGHT)
            mx = (p.x + p.w) / tw
        Else
            mx = p.x / tw
        End
        my = (p.y + p.h - 1) / th

        blockType = state.mapLookup[mx + my * mapLayer.width]
        If (blockType = BlockTypes.BLOCK Or p.x < 0 Or p.x >= mapLayer.width * tw - p.w)
            p.x = oldX
            p.direction *= -1
        End

        ' check Y  '
        p.y += pvy_step
        mx = (p.x + p.w / 2.0) / tw
        If (pvy_step > 0)
            my = (p.y + p.h) / th
        Else
            my = p.y / th
        End

        blockType = state.mapLookup[mx + my * mapLayer.width]
        If (blockType = BlockTypes.BLOCK Or p.x < 0 Or p.x >= mapLayer.width * tw - p.w)
            p.y = oldY
            If (Not p.friction And p.vy > 0) Then p.vx = 0
            p.vy = 0
        End

        pvx -= pvx_step
        pvy -= pvy_step
    Next


End











        ' If (tx < 0 Or tx >= state.map.tileWidth * state.map.width)
        '     p.direction *= -1            
        ' End

        ' Local ty := p.y + pvy_step
        ' If (ty < 0) Then ty = 0
        ' If (ty >= state.map.tileHeight * state.map.height) Then ty = state.map.tileHeight * state.map.height

        ' Local mx#, my#

        ' If (p.direction = Player.RIGHT)
        '     mx = Int((tx + p.w) / state.map.tileWidth)
        ' Else
        '     mx = Int(tx / state.map.tileWidth)
        ' End

        ' my = Int((p.y + p.w / 2.0) / state.map.tileHeight)

        ' Local blockType := state.mapLookup[mx + my * mapLayer.width]
        ' If (blockType = BlockTypes.BLOCK)
        '     If (p.direction = Player.RIGHT)
        '         tx = (mx - 1) * state.map.tileWidth
        '     Else
        '         tx = (mx + 1 ) * state.map.tileWidth
        '     End
        '     p.direction  *= -1
        ' End

        ' p.x = tx

        ' mx = Int((p.x + p.w / 2.0) / state.map.tileWidth)

        ' my = Int((ty + p.h) / state.map.tileHeight) 
        ' blockType = state.mapLookup[mx + my * mapLayer.width]   

        ' If (blockType = BlockTypes.BLOCK)
        '     ty = (my) * state.map.tileHeight - p.h
        '     p.vy = 0
        '     If (Not p.friction) Then p.vx = 0
        ' End
        ' p.y = ty

