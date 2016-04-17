Strict

Import config
Import src.gamescene
Import src.titlescene
Import coreproc.coreapp

#rem
    TODO:
        MUST-HAVE FOR LD35
        ------------------
        * Find a name!!!
        
        NICE-TO-HAVE
        ------------
        * Walker dies if he falls more than four tiles
        * Gems to collect
        * Add nice art / parallax scrolling ;)
        * Elevators
        * More Enemies
        * Keys (Collect them, then open doors with them)
        * Spider (can walk along ceilings and walls)
        * Bossfights?!? Somehow?!
        * CleanUp Code (this will be A LOT of work!)
#end

Function Main%()
    Local app := New CoreApp()
    app.settings.virtualWidth = 320
    app.settings.virtualHeight = 240
    app.settings.resolutionPolicy = ResolutionPolicy.SHOW_ALL | ResolutionPolicy.ALIGN_CENTER

    SceneManager.Register("title", New TitleScene())
    SceneManager.Register("game", New GameScene())

    Return 0
End
