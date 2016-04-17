Strict

Import coreproc.globals
Import manager

Function RenderSolidColorTransition:Void(r# = 0, g# = 0, b# = 0)
    If (SceneManager.IsTransitionRunning())
        Local alpha := Clamp(SceneManager.GetTransitionProgress(), 0.0, 1.0)
        canvas.SetColor(r, g, b, alpha)
        canvas.DrawRect(0, 0, canvas.Width(), canvas.Height())
        canvas.SetColor(1.0, 1.0, 1.0, 1.0)
    End
End