Strict

Import mojo2
Import coreproc.globals
Import coreproc.util.time

Class GameInput
    Field mouseX#
    Field mouseY#
    Field mouseHit?
    Field dt#
    
    Field activateWalker?
    Field activateFrog?
    Field activateBird?    
    Field activateStone?

    Field anyKeyHit?
    Field restartLevel?
End

Function ReadGameInput:Void(input:GameInput)
    Local out#[2]
    canvas.TransformCoords([MouseX(), MouseY()], out)

    input.dt = GetDeltaTime()

    input.mouseX = out[0]
    input.mouseY = out[1]

    input.activateWalker = KeyHit(KEY_A) > 0
    input.activateFrog = KeyHit(KEY_S) > 0
    input.activateBird = KeyHit(KEY_D) > 0
    input.activateStone = KeyHit(KEY_F) > 0
    input.anyKeyHit = GetChar() > 0 Or MouseHit() > 0
    input.mouseHit = MouseHit() > 0
    input.restartLevel = KeyHit(KEY_R) > 0
End
