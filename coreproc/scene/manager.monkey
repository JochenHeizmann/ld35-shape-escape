Strict

Import globals

Interface Scene
    Method Initialize:Void()
    Method Terminate:Void()
    Method Execute:Void()
End

Class SceneTransitionData
    Const STOPPED := 0
    Const IN := 1
    Const OUT := 2

    Field position# = 0.0
    Field duration# = 0.75
    Field state% = IN
End

Class SceneManager
    Const ENTERING := 0
    Const RUNNING := 1
    Const LEAVING := 2

    Global state% = ENTERING

    Global currentScene:Scene
    Global nextScene:Scene

    Global scenes := New StringMap<Scene>

    Global transition := New SceneTransitionData()

    Method New()
        Error "This is a static class! You are not allowed to instantiate it."
    End

    Function Register:Void(sceneName$, scene:Scene)
        If (scenes.IsEmpty()) Then currentScene = scene
        If (scenes.Get(sceneName)) Then Print "Warning! Scene " + sceneName + " already exsits! Overwriting now!"
        scenes.Set(sceneName, scene)
    End

    Function Change:Void(sceneName$)
        nextScene = scenes.Get(sceneName)
        If (Not nextScene) Then Error "Scene with name " + sceneName + " not found!"
    End

    Function Update:Void(deltaTime#)
        If (Not currentScene) Then Error("No active scene found! Have you already defined one with SceneManager.Register()?")

        If (state = ENTERING)
            nextScene = Null
            currentScene.Initialize()
            state = RUNNING

            transition.state = transition.IN
            transition.position = 0.0
        End

        If (state = RUNNING)
            If (transition.state = transition.IN)
                transition.position = Clamp(transition.position + deltaTime / transition.duration * 2.0, 0.0, 1.0)
                If (transition.position >= 1.0) Then transition.state = transition.STOPPED
            End

            currentScene.Execute()
            If (nextScene <> Null And nextScene <> currentScene)
                transition.state = transition.OUT
            End
            
            If (transition.state = transition.OUT)
                transition.position = Clamp(transition.position - deltaTime / transition.duration * 2.0, 0.0, 1.0)
                If (transition.position <= 0.0) Then state = LEAVING ; transition.state = transition.IN
            End        
        End

        If (state = LEAVING)
            currentScene.Terminate()
            currentScene = nextScene
            state = ENTERING
        End
    End

    Function IsTransitionRunning?()
        Return transition.state <> transition.STOPPED
    End

    Function GetTransitionProgress#()
        Return 1.0 - transition.position
    End
End
