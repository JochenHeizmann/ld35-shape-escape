Strict

Class Rect
    Field x# = 0
    Field y# = 0
    Field w# = 0
    Field h# = 0

    Method New(x# = 0, y# = 0, w# = 0, h# = 0)
        Set(x, y, w, h)
    End
    
    Method IsPointInside?(x#, y#)
        Return (x >= Self.x And y >= Self.y And x <= Self.x + Self.w And y <= Self.y + Self.h)
    End    

    Method Set:Void(x#, y#, w#, h#)
        Self.x = x
        Self.y = y
        Self.w = w
        Self.h = h
    End
    
    Method Move:Void(dx#, dy#)
        x += dx
        y += dy        
    End

    Function IsInside?(rect1:Rect, rect2:Rect)
        Local left1 := rect1.x
        Local top1 := rect1.y
        Local right1 := left1 + rect1.w
        Local bottom1 := top1 + rect1.h

        Local left2 := rect2.x
        Local top2 := rect2.y
        Local right2 := left2 + rect2.w
        Local bottom2 := top2 + rect2.h

        Local result := (left1 >= left2) And (right1 <= right2) And (top1 >= top2) And (bottom1 <= bottom2)
        Return result
    End

    Function Intersect?(rect1:Rect, rect2:Rect)
        Local x1 := rect1.x
        Local y1 := rect1.y
        Local w1 := rect1.w
        Local h1 := rect1.h
        Local x2 := rect2.x
        Local y2 := rect2.y
        Local w2 := rect2.w
        Local h2 := rect2.h

        Return Intersect(x1, y1, w1, h1, x2, y2, w2, h2)
    End

    Function Intersect?(x1#, y1#, w1#, h1#, x2#, y2#, w2#, h2#)
        If (x1 > (x2 + w2) Or (x1 + w1) < x2) Then Return False
        If (y1 > (y2 + h2) Or (y1 + h1) < y2) Then Return False
        Return True
    End        
    
    Function GetIntersectionDepth#[](rectA:Rect, rectB:Rect)
        Local halfWidthA := rectA.w / 2.0
        Local halfHeightA := rectA.h / 2.0
        Local halfWidthB := rectB.w / 2.0
        Local halfHeightB := rectB.h / 2.0

        Local centerAx := rectA.x + halfWidthA
        Local centerAy := rectA.y + halfHeightA
        Local centerBx := rectB.x + halfWidthB
        Local centerBy := rectB.y + halfHeightB

        Local distanceX := centerAx - centerBx
        Local distanceY := centerAy - centerBy
        Local minDistanceX := halfWidthA + halfWidthB
        Local minDistanceY := halfHeightA + halfHeightB

        If (Abs(distanceX) >= minDistanceX Or Abs(distanceY) >= minDistanceY)
            Return [0.0, 0.0]
        End            

        Local depthX#, depthY#
        If (distanceX > 0)
            depthX = minDistanceX - distanceX
        Else
            depthX = -minDistanceX - distanceX
        End
        If (distanceY > 0)
            depthY = minDistanceY - distanceY
        Else
            depthY = -minDistanceY - distanceY
        End

        Return [depthX, depthY]
    End
End