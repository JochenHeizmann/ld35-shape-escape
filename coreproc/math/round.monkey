Strict

Function Round%(val#)
    If (val - Int(val)) >= 0.5 Then Return Ceil(val)
    Return Floor(val)
End
