Strict

Function Assert:Void(condition?, msg$ = "")
    #If CONFIG = "debug"
        If (Not condition)
            Print "[ASSERTION FAILED] " + msg
            DebugStop()
        End
    #End
End
