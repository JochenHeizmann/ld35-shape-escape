Strict

Class InterpolateFunc
    Const LINEAR := 0
    Const ZERO := 1
    Const SINE := 2
    Const QUAD := 3
    Const CUBIC := 4
    Const QUART := 5
    Const QUINT := 6
    Const EXPO := 7
    Const ELASTIC := 8
    Const CIRCLE := 9
    Const BOUNCE := 10
    Const BACK := 11
End

Function InterpolateLinear#(progress#)
    Return progress
End

Function InterpolateZero#(progress#)
    Return 0
End

Function InterpolateSine#(progress#)
    Return 1 - Cos(progress * 180 / 2)
End

Function InterpolateQuad#(progress#)
    Return progress * progress;
End

Function InterpolateCubic#(progress#)
    Return progress * progress * progress
End

Function InterpolateQuart#(progress#)
    Return progress * progress * progress * progress;
End

Function InterpolateQuint#(progress#)
    Return progress * progress * progress * progress * progress;
End

Function InterpolateExpo#(progress#)
    If (progress = 0) Then Return 0
    Return Pow(2, 10 * (progress - 1))
End

Function InterpolateElastic#(progress#)
    Local v# = progress - 1
    Local p# = 0.3
    Return -Pow(2, 10 * v) * Sin((v - p / 4) * 2 * 180 / p)
End   

Function InterpolateCircle#(progress#)
    Return 1 - Sqrt(1 - progress * progress);
End

Function InterpolateBounce#(progress#)
    Local v# = 1 - progress
    Local c#, d#

    If (v < (1 / 2.75))
        c = v
        d = 0
    Else If (v < (2 / 2.75))
        c = v - 1.5 / 2.75
        d = 0.75
    Else If (v < (2.5 / 2.75))
        c = v - 2.25 / 2.75
        d = 0.9375
    Else
        c = v - 2.625 / 2.75
        d = 0.984375
    End
    Return 1 - (7.5625 * c * c + d)
End

Function InterpolateBack#(progress#)
    Const S# = 1.70158
    Return progress * progress * ((S + 1) * progress - S)
End

Function InterpolateReverse#(progress#)
    Return 1 - progress
End

Function InterpolatePingPong#(progress#)
    If (progress < 0.5)
        Return 2 * progress
    Else
        Return 1 - ((progress - 0.5) * 2.0)
    End    
End

Function InterpolateInOut#(interpolateFunc%, progress#)
    If (progress < 0.5)
        Return CallInterpolateFunc(interpolateFunc, 2 * progress) / 2
    Else
        Return 0.5 + (1 - CallInterpolateFunc(interpolateFunc, 1 - (2 * progress - 1))) / 2
    End
End

Function CallInterpolateFunc#(interpolateFunc%, progress#)
    Select (interpolateFunc)
        Case InterpolateFunc.LINEAR
            Return InterpolateLinear(progress)

        Case InterpolateFunc.ZERO
            Return InterpolateZero(progress)

        Case InterpolateFunc.SINE
            Return InterpolateSine(progress)

        Case InterpolateFunc.QUAD
            Return InterpolateQuad(progress)

        Case InterpolateFunc.CUBIC
            Return InterpolateCubic(progress)

        Case InterpolateFunc.QUART
            Return InterpolateQuart(progress)

        Case InterpolateFunc.QUINT
            Return InterpolateQuint(progress)

        Case InterpolateFunc.EXPO
            Return InterpolateExpo(progress)

        Case InterpolateFunc.ELASTIC
            Return InterpolateElastic(progress)

        Case InterpolateFunc.CIRCLE
            Return InterpolateCircle(progress)

        Case InterpolateFunc.BOUNCE
            Return InterpolateBounce(progress)

        Case InterpolateFunc.BACK
            Return InterpolateBack(progress)
    End    

    Error "Function with id " + interpolateFunc + " not found!"
    Return 0
End