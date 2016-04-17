Strict

Import coreproc.coreapp

Function GetDeltaTime#()
    Return CoreApp.timer.frameTime
End

Function GetFPS%()
    Return CoreApp.timer.fps
End