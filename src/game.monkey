Strict

Import coreproc.io.psd
Import coreproc.graphics.texturepacker
Import coreproc.math.modf
Import coreproc.math.interpolate
Import src.tiled
Import src.gui
Import src.player
Import src.gameinput
Import src.gamestate
Import src.blocktypes
Import src.tileids

Function InitLevel:Void(gameState:GameState)
    gameState.player.direction = Player.RIGHT
    gameState.state = GameState.GET_READY
    gameState.moveInOut.Reset()
    gameState.moveInOut.state = MoveInOutFSM.IDLE
    gameState.moveInOut.progress = 1.0
    Local label := gameState.psd.textLabels.Get(gameState.psd.layerIdByName.Get("messagebox/text.font"))
    SetLabelByName(label, "GET READY")

    gameState.enemyZones = gameState.enemyZones.Resize(gameState.MAX_COLLISION_ZONES)
    For Local i := 0 Until gameState.MAX_COLLISION_ZONES
        gameState.enemyZones[i] = New Rect(0,0,-1,-1)
    Next
    gameState.enemyZoneDynamicStart = 0
    gameState.enemyZoneIdx = 0

    gameState.map = LoadMap("map/level" + gameState.level + ".json", Image.Mipmap)


    gameState.mapLookup = gameState.mapLookup.Resize(gameState.map.width * gameState.map.height)
    ArrayUtil<Int>.Reset(gameState.mapLookup, BlockTypes.NOTHING)

    For Local mapLayer := EachIn gameState.map.layers
        Local mapData := mapLayer.data
        For Local idx := 0 Until mapData.Length()
            Local mapX := idx Mod gameState.map.width
            Local mapY := idx / gameState.map.width
            Local pixelX := mapX * gameState.map.tileWidth
            Local pixelY := mapY * gameState.map.tileHeight
            Local id := mapData[idx] - gameState.map.tilesets[0].firstGid
            Local props := gameState.map.tilesets[0].tileproperties.Get(id)
            If (props)
                For Local e := EachIn props
                    If (e.Key() = "block" And e.Value() = "1")
                        gameState.mapLookup[idx] = BlockTypes.BLOCK                    
                    Else If (e.Key() = "obstacle" And e.Value() = "1")
                        AddEnemyZone(gameState, pixelX, pixelY, gameState.map.tileWidth, gameState.map.tileHeight)
                        gameState.mapLookup[idx] = BlockTypes.OBSTACLE
                    Else If (e.Key() = "exit" And e.Value() = "1")
                        gameState.exitZone.x = pixelX
                        gameState.exitZone.y = pixelY
                        gameState.exitZone.w = gameState.map.tileWidth
                        gameState.exitZone.h = gameState.map.tileHeight
                    End
                Next
            End
        Next
    Next

    gameState.enemyZoneDynamicStart = gameState.enemyZoneIdx

    InitWalker(gameState.player)

    gameState.obstacles.Clear()

    For Local mapLayer := EachIn gameState.map.layers
        If (mapLayer)
            For Local idx := 0 Until mapLayer.data.Length()
                Local mapX := idx Mod mapLayer.width
                Local mapY := idx / mapLayer.width
                Local pixelX := mapX * gameState.map.tileWidth
                Local pixelY := mapY * gameState.map.tileHeight
                Select mapLayer.data[idx]
                    Case TileIds.START
                        gameState.player.direction = Player.RIGHT
                        gameState.player.x = pixelX
                        gameState.player.y = pixelY - gameState.player.h + gameState.map.tileHeight
                        mapLayer.data[idx] = 0

                    Case TileIds.BALL_BIG
                        mapLayer.data[idx] = 0
                        Local height := 0
                        Local cy := mapY
                        While (1) ' check downwards
                            cy += 1
                            Local nextIdx := mapX + cy * gameState.map.width
                            If (nextIdx < 0) Then Exit
                            If (nextIdx >= mapLayer.data.Length()) Then Exit
                            Local tileId := mapLayer.data[nextIdx]
                            If (tileId = TileIds.BALL_SMALL) 
                                mapLayer.data[nextIdx] = 0
                                height += 1
                            Else
                                Exit
                            End
                        Wend
                        If (height = 0) 
                            cy = mapY
                            While (1) 'check upwards
                                cy -= 1
                                Local nextIdx := mapX + cy * gameState.map.width
                                If (nextIdx < 0) Then Exit
                                If (nextIdx >= mapLayer.data.Length()) Then Exit
                                Local tileId := mapLayer.data[nextIdx]
                                If (tileId = TileIds.BALL_SMALL) 
                                    mapLayer.data[nextIdx] = 0
                                    height -= 1
                                Else
                                    Exit
                                End
                            Wend
                        End

                        Local e := New BallObstacle
                        e.x = pixelX + gameState.map.tileWidth / 2.0
                        e.y = pixelY + gameState.map.tileHeight / 2.0 + (height * gameState.map.tileHeight)
                        e.height = height
                        gameState.obstacles.Push(e)
                End
            Next

            If (mapLayer.properties.Get("birdCount")) Then gameState.birdCount = Int(mapLayer.properties.Get("birdCount"))
            If (mapLayer.properties.Get("frogCount")) Then gameState.frogCount = Int(mapLayer.properties.Get("frogCount"))
            If (mapLayer.properties.Get("walkerCount")) Then gameState.walkerCount = Int(mapLayer.properties.Get("walkerCount"))
            If (mapLayer.properties.Get("stoneCount")) Then gameState.stoneCount = Int(mapLayer.properties.Get("stoneCount"))
        End
    Next

    GetLayerByName(gameState.psd, "hud/frog_empty.png").visible = False
    GetLayerByName(gameState.psd, "hud/walker_empty.png").visible = False
    GetLayerByName(gameState.psd, "hud/stone_empty.png").visible = False
    GetLayerByName(gameState.psd, "hud/bird_empty.png").visible = False

    For Local i := 0 Until gameState.MAX_PARTICLE_COUNT
        If (Not gameState.particles[i])        
            gameState.particles[i] = New Particle()
        End
    Next
End

Function UpdateGame:Void(input:GameInput, state:GameState)
    GetLayerByName(state.psd, "hud/bird_hover.png").visible = False
    GetLayerByName(state.psd, "hud/frog_hover.png").visible = False
    GetLayerByName(state.psd, "hud/walker_hover.png").visible = False
    GetLayerByName(state.psd, "hud/stone_hover.png").visible = False
    GetLayerByName(state.psd, "hud/replay_hover.png").visible = False

    Local spatial := GetSpatialByName(state.psd, "hud/walker_hover.png")
    If (state.player.charType <> Player.CHAR_WALKER And state.walkerCount > 0 And Rect.IsInside(New Rect(input.mouseX, input.mouseY, 1, 1), New Rect(spatial.x, spatial.y, spatial.width, spatial.height)))
        GetLayerByName(state.psd, "hud/walker_hover.png").visible = True
        If (input.mouseHit) Then input.activateWalker = True
    End

    spatial = GetSpatialByName(state.psd, "hud/stone_hover.png")
    If (state.player.charType <> Player.CHAR_STONE And state.stoneCount > 0 And Rect.IsInside(New Rect(input.mouseX, input.mouseY, 1, 1), New Rect(spatial.x, spatial.y, spatial.width, spatial.height)))
        GetLayerByName(state.psd, "hud/stone_hover.png").visible = True
        If (input.mouseHit) Then input.activateStone = True
    End

    spatial = GetSpatialByName(state.psd, "hud/frog_hover.png")
    If (state.player.charType <> Player.CHAR_FROG And state.frogCount > 0 And Rect.IsInside(New Rect(input.mouseX, input.mouseY, 1, 1), New Rect(spatial.x, spatial.y, spatial.width, spatial.height)))
        GetLayerByName(state.psd, "hud/frog_hover.png").visible = True
        If (input.mouseHit) Then input.activateFrog = True
    End

    spatial = GetSpatialByName(state.psd, "hud/bird_hover.png")
    If (state.player.charType <> Player.CHAR_BIRD And state.birdCount > 0 And Rect.IsInside(New Rect(input.mouseX, input.mouseY, 1, 1), New Rect(spatial.x, spatial.y, spatial.width, spatial.height)))
        GetLayerByName(state.psd, "hud/bird_hover.png").visible = True
        If (input.mouseHit) Then input.activateBird = True
    End


    spatial = GetSpatialByName(state.psd, "hud/replay_hover.png")
    If (Rect.IsInside(New Rect(input.mouseX, input.mouseY, 1, 1), New Rect(spatial.x, spatial.y, spatial.width, spatial.height)))
         GetLayerByName(state.psd, "hud/replay_hover.png").visible = True
        If (input.mouseHit) Then input.restartLevel = True
    End


    Local walkerLabel := state.psd.textLabels.Get(state.psd.layerIdByName.Get("walker_count.font"))
    Local frogLabel := state.psd.textLabels.Get(state.psd.layerIdByName.Get("frog_count.font"))
    Local birdLabel := state.psd.textLabels.Get(state.psd.layerIdByName.Get("bird_count.font"))
    Local stoneLabel := state.psd.textLabels.Get(state.psd.layerIdByName.Get("stone_count.font"))

    If (state.walkerCount = 0) 
        walkerLabel.r = 1
        walkerLabel.g = 0
        walkerLabel.b = 0
        GetLayerByName(state.psd, "hud/walker_empty.png").visible = True
    Else
        walkerLabel.r = 1
        walkerLabel.g = 1
        walkerLabel.b = 1
    End

    If (state.frogCount = 0) 
        frogLabel.r = 1
        frogLabel.g = 0
        frogLabel.b = 0
        GetLayerByName(state.psd, "hud/frog_empty.png").visible = True
    Else
        frogLabel.r = 1
        frogLabel.g = 1
        frogLabel.b = 1
    End

    If (state.birdCount = 0) 
        birdLabel.r = 1
        birdLabel.g = 0
        birdLabel.b = 0
        GetLayerByName(state.psd, "hud/bird_empty.png").visible = True
    Else
        birdLabel.r = 1
        birdLabel.g = 1
        birdLabel.b = 1
    End

    If (state.stoneCount = 0) 
        stoneLabel.r = 1
        stoneLabel.g = 0
        stoneLabel.b = 0
        GetLayerByName(state.psd, "hud/stone_empty.png").visible = True
    Else
        stoneLabel.r = 1
        stoneLabel.g = 1
        stoneLabel.b = 1
    End
    
    SetLabelByName(stoneLabel, "X" + state.stoneCount)
    SetLabelByName(walkerLabel, "X" + state.walkerCount)
    SetLabelByName(frogLabel, "X" + state.frogCount)
    SetLabelByName(birdLabel, "X" + state.birdCount)

    RenderLayers(state.psd, "game/background")

    Local p := state.player

    If (state.state & GameState.RUNNING)
        If (input.activateWalker And p.charType <> Player.CHAR_WALKER And state.walkerCount > 0)
            state.walkerCount -= 1
            state.transformTo = Player.CHAR_WALKER
            state.transformProgress = 0.0
            state.state = GameState.TRANSFORMING
        Else If (input.activateFrog And p.charType <> Player.CHAR_FROG And state.frogCount > 0)
            state.frogCount -= 1
            state.transformTo = Player.CHAR_FROG
            state.transformProgress = 0.0
            state.state = GameState.TRANSFORMING
        Else If (input.activateBird And p.charType <> Player.CHAR_BIRD And state.birdCount > 0)
            state.birdCount -= 1
            state.transformTo = Player.CHAR_BIRD
            state.transformProgress = 0.0
            state.state = GameState.TRANSFORMING
        Else If (input.activateStone And p.charType <> Player.CHAR_STONE And state.stoneCount > 0)
            state.stoneCount -= 1
            state.transformProgress = 0.0
            state.transformTo = Player.CHAR_STONE
            state.state = GameState.TRANSFORMING
        End

        If (p.charType = Player.CHAR_WALKER)
            ' WALKER
            UpdatePlayer(p, input, state)
        Else If (p.charType = Player.CHAR_STONE)
            ' WALKER
            UpdatePlayer(p, input, state)
        Else If (p.charType = Player.CHAR_FROG)

            p.waitForJumpCounter -= input.dt
            If (p.waitForJumpCounter <= 0)
                p.waitForJumpCounter = Player.FROG_IDLE_TIME
                p.vx = 220.0
                p.vy = -360.0
                PlaySound(state.sounds[2])

            End
            p.vx *= 0.98

            UpdatePlayer(p, input, state)
        Else If (p.charType = Player.CHAR_BIRD)
            ' check y movement
            Local ty := p.y + p.vy * input.dt

            If (ty < 0) Then ty = 0
            If (ty >= state.map.tileHeight * state.map.height) Then ty = state.map.tileHeight * state.map.height

            Local mapLayer := GetMapLayerByName(state.map, "map")
            Local mx := Int((p.x + p.w / 2.0) / state.map.tileWidth)
            Local my := Int((ty) / state.map.tileHeight)
            Local blockType := state.mapLookup[mx + my * mapLayer.width]
            If (blockType = BlockTypes.BLOCK)
                ty = (1 + my) * state.map.tileHeight
            End
            p.y = ty

            ' check x movement

            Local tx := Clamp(p.x + p.vx * p.direction * input.dt, 0.0, Float(state.map.tileWidth * (state.map.width-1)))

            If (p.direction = Player.RIGHT)
                mx = Int((p.x + p.w) / state.map.tileWidth)
            Else
                mx = Int((p.x) / state.map.tileWidth)
            End
            my = Int((p.y + p.h / 2.0) / state.map.tileHeight)
            Local idx := mx + my * mapLayer.width
            blockType = state.mapLookup[idx]
            If (blockType = BlockTypes.BLOCK)
                If (p.direction = Player.RIGHT)
                    tx = (mx - 1) * state.map.tileWidth
                Else
                    tx = (mx + 1) * state.map.tileWidth
                End
            End
            p.x = tx
        End
    End

    If (state.state = GameState.TRANSFORMING)
        If (state.transformTo = Player.CHAR_WALKER)
            GetLayerByName(state.psd, "hud/walker_hover.png").visible = True
        Else If (state.transformTo = Player.CHAR_FROG)
            GetLayerByName(state.psd, "hud/frog_hover.png").visible = True
        Else If (state.transformTo = Player.CHAR_BIRD)
            GetLayerByName(state.psd, "hud/bird_hover.png").visible = True
        Else If (state.transformTo = Player.CHAR_STONE)
            GetLayerByName(state.psd, "hud/stone_hover.png").visible = True
        End

        If (state.transformProgress = 0.0)
            PlaySound(state.sounds[1])
        End
        state.transformProgress += input.dt * 20
        If (Int(state.transformProgress) Mod 2 = 0)
            p.highlight = True
        Else
            p.highlight = False
        End
        If (state.transformProgress >= 5.0)
            If (state.transformTo = Player.CHAR_WALKER And state.player.charType <> Player.CHAR_WALKER)
                InitWalker(p)
            Else If (state.transformTo = Player.CHAR_FROG And state.player.charType <> Player.CHAR_FROG)
                InitFrog(p)
            Else If (state.transformTo = Player.CHAR_BIRD And state.player.charType <> Player.CHAR_BIRD)
                InitBird(p)
            Else If (state.transformTo = Player.CHAR_STONE And state.player.charType <> Player.CHAR_STONE)
                InitStone(p)
            End
            ' TODO: Resolve possible collisions

            If (state.transformProgress >= 10.0) Then state.state = GameState.RUNNING
        End
    End

    canvas.PushMatrix()
    Local mapX := Clamp(Int(-p.x + 160), Int(-state.map.width * state.map.tileWidth - (CoreApp.visibleRegion.w - CoreApp.visibleRegion.x)), 0)
    Local mapY := Clamp(Int(-p.y + 120), Int(-state.map.height * state.map.tileHeight + (CoreApp.visibleRegion.h - CoreApp.visibleRegion.y)), 0)
    canvas.Translate(mapX, mapY)
    RenderMap(state.map)

    canvas.PushMatrix()
    canvas.Translate(p.x, p.y)

    If (KeyDown(KEY_P))
        canvas.DrawRect(0,0, p.w, p.h)
    End

    If (state.state & GameState.TRANSFORMING And Not p.highlight)
    Else If (state.state & GameState.GAME_OVER)
    Else
        If (p.charType = Player.CHAR_WALKER)
            If (state.state & GameState.RUNNING) 
                p.currentFrame = Modf(p.currentFrame + input.dt * 8.0, p.walker.Length())
            Else
                If (p.currentFrame >= p.walker.Length()) Then p.currentFrame = 0
            End

            ' canvas.SetColor(0.5,0,0.7)
            ' canvas.DrawRect(0,0,p.w,p.h)
            canvas.PushMatrix()
            canvas.Translate(p.w / 2, p.h / 2)
            If (p.direction = Player.LEFT) Then canvas.Scale(-1, 1)
            If (state.state & GameState.TRANSFORMING)
                DrawSprite(state.walkerHighlight, 0 ,0)
            Else
                DrawSprite(p.walker, 0, 0, p.currentFrame)
            End
            canvas.PopMatrix()
        Else If (p.charType = Player.CHAR_FROG)
            If (state.state & GameState.RUNNING)
                If (p.vy = 0 And p.vx = 0)
                    p.currentFrame = 0
                Else
                    p.currentFrame = 1
                End
            End
            If (p.currentFrame >= p.frogger.Length()) Then p.currentFrame = 0
            canvas.PushMatrix()
            canvas.Translate(p.w / 2, p.h / 2 - 2)
            If (p.direction = Player.LEFT) Then canvas.Scale(-1, 1)
            If (state.state & GameState.TRANSFORMING)
                DrawSprite(state.froggerHighlight, 0 ,0)
            Else
                DrawSprite(p.frogger, 0, 0, p.currentFrame)
            End
            canvas.PopMatrix()
        Else If (p.charType = Player.CHAR_BIRD)
            ' canvas.SetColor(0.5,0,0.7)
            ' canvas.DrawRect(0,0,p.w,p.h)

            If (state.state & GameState.RUNNING) Then p.currentFrame = Modf(p.currentFrame + input.dt * 12.0, p.bird.Length())
            canvas.PushMatrix()
            canvas.Translate(p.w / 2, p.h / 2)
            If (state.state & GameState.TRANSFORMING)
                DrawSprite(state.birdHighlight, 0 ,0)
            Else
                If (p.currentFrame >= p.bird.Length()) Then p.currentFrame = 0
                DrawSprite(p.bird, 0, 0, p.currentFrame)
            End
            canvas.PopMatrix()
        Else If (p.charType = Player.CHAR_STONE)
            canvas.PushMatrix()
            canvas.Translate(p.w / 2, p.h / 2)
            If (state.state & GameState.TRANSFORMING)
                DrawSprite(state.stoneHighlight, 0 ,0)
            Else
                DrawSprite(p.stone, 0, 0, 0)
            End
            canvas.PopMatrix()
        End        
    End
    canvas.PopMatrix()

    For Local i := 0 Until state.MAX_PARTICLE_COUNT
        Local p := state.particles[i]
        If (p.active) 
            p.lifeTime -= input.dt
            Local ox := p.x
            Local oy := p.y
            p.x += p.vx

            Local mx := Int((p.x) / state.map.tileWidth)
            Local my := Int((p.y) / state.map.tileHeight)
            Local mapLayer := GetMapLayerByName(state.map, "map")
            Local blockType := state.mapLookup[mx + my * mapLayer.width]
            If (blockType = BlockTypes.BLOCK)
                p.vx *= -1
                p.x = ox
            End

            p.y += p.vy
            p.vy += Particle.GRAVITY
            mx = Int((p.x) / state.map.tileWidth)
            my = Int((p.y) / state.map.tileHeight)
            blockType = state.mapLookup[mx + my * mapLayer.width]
            If (blockType = BlockTypes.BLOCK)
                p.y = oy
                p.vy *= -0.7
            End
    

            Local s := Min(Floor( (p.lifeTime * 2) / 0.25 + 0.5) * 0.25, 1.0)

            canvas.PushMatrix()
            canvas.Translate(p.x, p.y)
            canvas.Scale(s, s)
            DrawSprite(state.particleSprite[p.type], 0, 0)
            canvas.PopMatrix()
    
            If (p.lifeTime < 0) Then p.active = False
        End
    Next

    ' Render Enemies
    For Local o := EachIn state.obstacles
        o.stp += input.dt * BallObstacle.ROTATION_SPEED
        canvas.PushMatrix()
        canvas.Translate(o.x, o.y)

        Local h := -o.height
        Local dy := 1
        If (h < 0) Then dy = -1
        Local i := -dy
        Local tw := state.map.tileWidth
        Local th := state.map.tileHeight
        Repeat
            i += dy
            Local cx#, cy#
            If (o.height > 0)
                cx = Sin(o.stp) * i * tw
                cy = (Cos(o.stp) * i * th)
            Else
                cx = Cos(o.stp + 90) * i * tw
                cy = (Sin(o.stp + 90) * i * th)
            End
            If (i = h)
                DrawSprite(state.bigBall, cx, cy)
                AddEnemyZone(state, o.x + cx - 6, o.y + cy - 6, 12, 12)
            Else
                DrawSprite(state.smallBall, cx, cy)
                AddEnemyZone(state, o.x + cx - 4, o.y + cy - 4, 8, 8)
            End
        Until (i=h)
        canvas.PopMatrix()
    Next

    'Check PLAYER <--> ENEMIES COLLISION
    If (state.state & GameState.RUNNING And state.player.invincible = False)
        Local playerRect := New Rect(state.player.x, state.player.y, state.player.w, state.player.h)
        For Local i := state.enemyZoneIdx To 0 Step -1
            Local r := state.enemyZones[i]
            If (Rect.Intersect(playerRect, r)) 
                InitGameOver(state)
                Exit
            End
            If (KeyDown(KEY_P)) Then canvas.DrawRect(r.x, r.y, r.w, r.h)
        Next

        If (Rect.Intersect(playerRect, state.exitZone))
            state.state = GameState.LEVEL_COMPLETED
            state.moveInOut.Reset()
            Local label := state.psd.textLabels.Get(state.psd.layerIdByName.Get("messagebox/text.font"))
            SetLabelByName(label, "LEVEL COMPLETED")
            PlayMusic("sfx/victory.mp3", 0)

        End
    End
    state.enemyZoneIdx = state.enemyZoneDynamicStart

    canvas.PopMatrix()

    RenderLayers(state.psd, "game/hud")

    If (state.state & GameState.GAME_OVER)
        If (input.anyKeyHit And state.moveInOut.state <> MoveInOutFSM.MOVE_OUT)
            state.moveInOut.state = MoveInOutFSM.MOVE_OUT
        End
        If (state.moveInOut.state = MoveInOutFSM.DONE)
            InitLevel(state)
        End
        state.moveInOut.Update(input.dt)
        canvas.PushMatrix()
        canvas.Translate(0, InterpolateCubic(1.0 - state.moveInOut.progress) * CoreApp.visibleRegion.h)
        RenderLayers(state.psd, "messagebox")
        canvas.PopMatrix()
    End

    If (state.state & GameState.LEVEL_COMPLETED)
        If (input.anyKeyHit And state.moveInOut.state <> MoveInOutFSM.MOVE_OUT)
            state.moveInOut.state = MoveInOutFSM.MOVE_OUT
        End
        If (state.moveInOut.state = MoveInOutFSM.DONE)
            state.level += 1
            If (state.level <= GameState.LEVELS)
                InitLevel(state)
                PlayMusic("sfx/theme.mp3", 1)
            Else
                state.state = GameState.GAME_COMPLETED
                state.moveInOut.Reset()
                Local label := state.psd.textLabels.Get(state.psd.layerIdByName.Get("messagebox/text.font"))
                SetLabelByName(label, "WOW! YOU'VE COMPLETED~nTHIS GAME!")
            End
        End
        state.moveInOut.Update(input.dt)
        canvas.PushMatrix()
        canvas.Translate(0, InterpolateCubic(1.0 - state.moveInOut.progress) * CoreApp.visibleRegion.h)
        RenderLayers(state.psd, "messagebox")
        canvas.PopMatrix()
    End

    If (state.state & GameState.GAME_COMPLETED)
        If (input.anyKeyHit And state.moveInOut.state <> MoveInOutFSM.MOVE_OUT)
            state.moveInOut.state = MoveInOutFSM.MOVE_OUT
        End
        If (state.moveInOut.state = MoveInOutFSM.DONE)
            SceneManager.Change("title")
        End
        state.moveInOut.Update(input.dt)
        canvas.PushMatrix()
        canvas.Translate(0, InterpolateCubic(1.0 - state.moveInOut.progress) * CoreApp.visibleRegion.h)
        RenderLayers(state.psd, "messagebox")
        canvas.PopMatrix()
    End

    If (state.state & GameState.GET_READY)
        If (input.anyKeyHit And state.moveInOut.state <> MoveInOutFSM.MOVE_OUT)
            state.moveInOut.state = MoveInOutFSM.MOVE_OUT
        End
        If (state.moveInOut.state = MoveInOutFSM.DONE)
            state.state = GameState.RUNNING
        End
        state.moveInOut.Update(input.dt)
        canvas.PushMatrix()
        canvas.Translate(0, InterpolateCubic(1.0 - state.moveInOut.progress) * CoreApp.visibleRegion.h)
        RenderLayers(state.psd, "messagebox")
        canvas.PopMatrix()
    End

    If (input.restartLevel And state.state & GameState.RUNNING)
        Local particleCount := 15
        LaunchParticles(state.particles, state.player.x + state.player.w / 2, state.player.y + state.player.h / 2, particleCount, state.player.charType)
        state.state = GameState.GAME_OVER
        PlaySound(state.sounds[0])
    End
End

Function AddEnemyZone:Void(state:GameState, x#, y#, w#, h#)
    state.enemyZoneIdx += 1
    If (state.enemyZoneIdx >= GameState.MAX_COLLISION_ZONES) Then Error "MAX_COLLISION_ZONES REACHED!!!"
    Local r := state.enemyZones[state.enemyZoneIdx]
    r.x = x
    r.y = y
    r.w = w
    r.h = h
End

Function InitGameOver:Void(state:GameState)
    state.state = GameState.GAME_OVER
    state.moveInOut.Reset()
    state.moveInOut.delay = 2.0
    Local label := state.psd.textLabels.Get(state.psd.layerIdByName.Get("messagebox/text.font"))
    SetLabelByName(label, "YOU DIED!")

    PlaySound(state.sounds[0])

    Local particleCount := 15
    LaunchParticles(state.particles, state.player.x + state.player.w / 2, state.player.y + state.player.h / 2, particleCount, state.player.charType)
End