Strict

Import coreproc.coreapp
Import src.gameinput
Import src.gamestate
Import src.game
Import coreproc.io.psd

Class TitleScene Implements Scene
    Field psd:PSD

    Method Initialize:Void()
        psd = LoadPSD("design.json", Image.Mipmap)
        Assert(psd <> Null, "Couldnt load psd!")
        PlayMusic("sfx/theme.mp3", 1)        
    End

    Method Execute:Void()
        If (Millisecs() / 500 Mod 2 = 0)
            GetLayerByName(psd, "anykey.font").visible = False
        Else
            GetLayerByName(psd, "anykey.font").visible = True
        End
        RenderLayers(psd, "title")
        If (MouseHit() Or GetChar() > 0) Then SceneManager.Change("game")
    End

    Method Terminate:Void()
        psd = Null
    End
End