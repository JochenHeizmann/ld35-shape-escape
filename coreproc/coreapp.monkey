Strict

Import mojo2
Import coreproc.globals
Import coreproc.math.round
Import coreproc.math.rect
Import scene.manager
Import scene.transitions

Class FrameTimer
    Field currentTime#
    Field newTime#
    Field frameTime#
    Field pausedTime#

    Field avgSmoothing# = 0.99
    Field avgTime#    
    Field fps%
End

Class AppConfig
    Global virtualWidth% = -1
    Global virtualHeight% = -1
    Global frameRate% = 60 
    Global resolutionPolicy%   
End

Class ResolutionPolicy
    Const EXACT_FIT := 1

    Const FIXED_WIDTH := 2
    Const FIXED_HEIGHT := 4

    Const NO_BORDER := 8
    Const SHOW_ALL := 16

    Const ALIGN_TOP := 32
    Const ALIGN_BOTTOM := 64
    Const ALIGN_CENTER := 128

    Const ALIGN_LEFT := 256
    Const ALIGN_RIGHT := 512
End

Class CoreApp Extends App
    Global settings:AppConfig = New AppConfig()
    Global timer:FrameTimer = New FrameTimer()
    Global visibleRegion := New Rect()
    
    ' override this method if you want to do additional setup stuff
    Method Setup:Void()
    End

    ' override this method if you want to implement your own gameloop
    Method GameLoop:Void(delta#)
        canvas.Clear()
        SceneManager.Update(delta)
        RenderSolidColorTransition()
    End

    Method OnCreate%()
        If (settings.virtualWidth = -1) Then settings.virtualWidth = DeviceWidth()
        If (settings.virtualHeight = -1) Then settings.virtualHeight = DeviceHeight()

        ' Do custom setup
        Setup()

        ' Create window render canvas
        canvas = New Canvas()

        ' We calculate how to scale the app based on the give
        ' ResolutionPolicy
        Local policy := settings.resolutionPolicy
        If (policy & ResolutionPolicy.SHOW_ALL)
            Local ratioH := Float(DeviceHeight()) / Float(settings.virtualHeight)
            Local ratioW := Float(DeviceWidth()) / Float(settings.virtualWidth)
            If (ratioH = ratioW) Then policy = ResolutionPolicy.EXACT_FIT
            If (ratioH > ratioW) Then policy = ResolutionPolicy.FIXED_WIDTH
            If (ratioH < ratioW) Then policy = ResolutionPolicy.FIXED_HEIGHT
        End

        If (policy & ResolutionPolicy.EXACT_FIT)
            visibleRegion.x = 0
            visibleRegion.y = 0
            visibleRegion.w = settings.virtualWidth
            visibleRegion.h = settings.virtualHeight
        Else If (policy & ResolutionPolicy.FIXED_WIDTH)
            Local ratio := Float(DeviceWidth()) / Float(settings.virtualWidth)
            visibleRegion.x = 0
            visibleRegion.y = 0
            visibleRegion.w = settings.virtualWidth
            visibleRegion.h = DeviceHeight() / ratio

            Local diff := visibleRegion.h - settings.virtualHeight
            If (settings.resolutionPolicy & ResolutionPolicy.ALIGN_BOTTOM)
                visibleRegion.y = -diff                
            Else If (settings.resolutionPolicy & ResolutionPolicy.ALIGN_TOP)
                visibleRegion.y = 0
            Else If (settings.resolutionPolicy & ResolutionPolicy.ALIGN_CENTER)
                visibleRegion.y = -diff / 2.0
            End
        Else If (policy & ResolutionPolicy.FIXED_HEIGHT)
            Local ratio := Float(DeviceHeight()) / Float(settings.virtualHeight)
            visibleRegion.x = 0
            visibleRegion.y = 0
            visibleRegion.w = DeviceHeight() / ratio
            visibleRegion.h = settings.virtualHeight

            Local diff := visibleRegion.w - settings.virtualWidth
            If (settings.resolutionPolicy & ResolutionPolicy.ALIGN_RIGHT)
                visibleRegion.x = -diff                
            Else If (settings.resolutionPolicy & ResolutionPolicy.ALIGN_LEFT)
                visibleRegion.x = 0
            Else If (settings.resolutionPolicy & ResolutionPolicy.ALIGN_CENTER)
                visibleRegion.x = -diff / 2.0
            End
        Else If (policy & ResolutionPolicy.NO_BORDER)
            Local ratioH := Float(DeviceHeight()) / Float(settings.virtualHeight)
            Local ratioW := Float(DeviceWidth()) / Float(settings.virtualWidth)
            Local ratio := Max(ratioW, ratioH)
            visibleRegion.x = 0
            visibleRegion.y = 0
            visibleRegion.w = DeviceWidth() / ratio
            visibleRegion.h = DeviceHeight() / ratio

            Local diffX := visibleRegion.w - settings.virtualWidth
            Local diffY := visibleRegion.h - settings.virtualHeight

            If (settings.resolutionPolicy & ResolutionPolicy.ALIGN_RIGHT)
                visibleRegion.x = -diffX
            Else If (settings.resolutionPolicy & ResolutionPolicy.ALIGN_LEFT)
                visibleRegion.x = 0
            Else If (settings.resolutionPolicy & ResolutionPolicy.ALIGN_CENTER)
                visibleRegion.x = -diffX / 2.0
            End

            If (settings.resolutionPolicy & ResolutionPolicy.ALIGN_BOTTOM)
                visibleRegion.y = -diffY               
            Else If (settings.resolutionPolicy & ResolutionPolicy.ALIGN_TOP)
                visibleRegion.y = 0
            Else If (settings.resolutionPolicy & ResolutionPolicy.ALIGN_CENTER)
                visibleRegion.y = -diffY / 2.0
            End            
        End

        canvas.SetProjection2d (visibleRegion.x, visibleRegion.x + visibleRegion.w, visibleRegion.y, visibleRegion.y + visibleRegion.h)

        canvas.Clear()

        ' Set Update Rate & Initilize Timer
        SetUpdateRate(settings.frameRate)
        timer.currentTime = Millisecs() / 1000.0
        timer.avgTime = 1.0 / settings.frameRate

        Return 0
    End

    Method OnUpdate%()
        ' Calculate Time
        timer.newTime = Millisecs() / 1000.0
        timer.frameTime = timer.newTime - timer.currentTime 
        timer.currentTime = timer.newTime
        timer.avgTime = (timer.avgTime * timer.avgSmoothing) + (timer.frameTime * (1.0 - timer.avgSmoothing))        
        timer.fps = Round(1.0 / timer.avgTime)

        GameLoop(timer.frameTime)

        #if TARGET="glfw"
            If KeyHit(KEY_CLOSE) Or KeyHit(KEY_ESCAPE) Then Error ""
        #end

        Return 0
    End

    Method OnRender%()
        canvas.Flush
        Return 0
    End

    Method OnLoading%()
        Local t$ = "Loading...Please stand by"
        canvas.SetColor(0, 0, 0)
        canvas.Clear()
        canvas.SetColor(0,255, 255)
        canvas.SetAlpha(0.5)
        canvas.DrawText(t, settings.virtualWidth / 2, settings.virtualHeight - 40, .5, .5)
        Return 0
    End Method

    Method OnResume%()
        timer.currentTime += ((Millisecs() - timer.pausedTime) / 1000.0)
        timer.pausedTime = 0
        Return 0
    End Method

    Method OnSuspend%()
        timer.pausedTime = Millisecs()
        Return 0
    End Method

    Method OnBack%()
        Return 0
    End
End