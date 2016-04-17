Strict

Import coreproc.coreapp
Import src.gameinput
Import src.gamestate
Import src.game

Class GameScene Implements Scene
    Field gameState:GameState
    Field gameInput:GameInput

    Method Initialize:Void()
        gameState = New GameState()
        gameInput = New GameInput()        

        gameState.psd = LoadPSD("design.json", Image.Mipmap)
        Assert(gameState.psd <> Null, "Couldn't load psd!")

        gameState.player.walker = GetSpriteAnimation(gameState.psd.spritesheet.frames, "walker{n1}.png")
        Assert(gameState.player.walker.Length() <> 0, "Couldn't find walker frames!")

        gameState.player.frogger = GetSpriteAnimation(gameState.psd.spritesheet.frames, "frog{n1}.png")
        Assert(gameState.player.frogger.Length() <> 0, "Couldn't find frogger frames!")

        gameState.player.bird = GetSpriteAnimation(gameState.psd.spritesheet.frames, "bird{n1}.png")
        Assert(gameState.player.bird.Length() <> 0, "Couldn't find Bird frames!")

        gameState.player.stone = GetSpriteAnimation(gameState.psd.spritesheet.frames, "stone{n1}.png")
        Assert(gameState.player.stone.Length() <> 0, "Couldn't find Stone frames!")

        gameState.walkerHighlight = GetSpriteAnimation(gameState.psd.spritesheet.frames, "walkerhighlight.png")
        Assert(gameState.walkerHighlight.Length() <> 0, "Couldn't find Walker Highlight frames!")

        gameState.birdHighlight = GetSpriteAnimation(gameState.psd.spritesheet.frames, "birdhighlight.png")
        Assert(gameState.birdHighlight.Length() <> 0, "Couldn't find Bird Highlight frames!")

        gameState.stoneHighlight = GetSpriteAnimation(gameState.psd.spritesheet.frames, "stonehighlight.png")
        Assert(gameState.stoneHighlight.Length() <> 0, "Couldn't find Stone Highlight frames!")

        gameState.froggerHighlight = GetSpriteAnimation(gameState.psd.spritesheet.frames, "froghighlight.png")
        Assert(gameState.froggerHighlight.Length() <> 0, "Couldn't find Frogger Highlight frames!")

        gameState.particleSprite[0] = gameState.psd.spritesheet.frames.Get("particles/blue.png")
        gameState.particleSprite[1] = gameState.psd.spritesheet.frames.Get("particles/green.png")
        gameState.particleSprite[2] = gameState.psd.spritesheet.frames.Get("particles/black.png")

        gameState.bigBall = gameState.psd.spritesheet.frames.Get("ball_big.png")
        gameState.smallBall = gameState.psd.spritesheet.frames.Get("ball_small.png")

        gameState.sounds[0] = LoadSound("sfx/explosion.mp3")
        gameState.sounds[1] = LoadSound("sfx/transform.mp3")
        gameState.sounds[2] = LoadSound("sfx/frogjump.mp3")

        InitLevel(gameState)        
    End

    Method Execute:Void()
        ReadGameInput(gameInput)

        If KeyDown(KEY_Q) Then gameInput.dt = 0
        If KeyHit(KEY_W) Then gameInput.dt = 1.0 / 60.0

        UpdateGame(gameInput, gameState)

        If (KeyHit(KEY_ESCAPE)) Then SceneManager.Change("title")
    End

    Method Terminate:Void()
        gameState = Null
        gameInput = Null
    End
End