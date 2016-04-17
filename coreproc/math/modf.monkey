Strict

Function Modf#(a:Float, n:Float)
  Local ret# = a - n * Floor(a / n)
  Return ret
End