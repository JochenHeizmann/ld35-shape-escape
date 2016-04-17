Strict

Class ArrayUtil<T> Abstract

    ' Allocate a 2-dimensional array.
    ' Eg: Local myArray := Array<Int>.Create2D(10, 10)
    Function Create2D:T[][](rows%, cols%)
        Local a:T[][] = New T[rows][]
        For Local i% = 0 Until rows
            a[i] = New T[cols]
        End

        Return a
    End

    ' Allocate a 3-dimensional array.
    ' Eg: Local myArray := Array<Int>.Create3D(10, 10, 2)
    Function Create3D:T[][][](x%, y%, z%)
        Local a:T[][][] = New T[x][][]
        For Local i% = 0 Until x
            a[i] = New T[y][]
            For Local j% = 0 Until y
                a[i][j] = New T[z]
            Next
        End

        Return a
    End

    ' Shuffles all elements of an array in random order.
    Function Shuffle:Void(input:T[])
        Local len% = input.Length()

        For Local idx% = 0 Until len
            Local randomIdx% = Floor(Rnd(0, len))
            Local swap:T = input[idx]

            input[idx] = input[randomIdx]
            input[randomIdx] = swap
        End
    End

    Function Rotate:Void(a:T[][])
        Local n := a.Length()
        Local tmp:T
        For Local i := 0 To n/2
            For Local j := i To n-i-1
                tmp = a[i][j]
                a[i][j] = a[j][n-i-1]
                a[j][n-i-1] = a[n-i-1][n-j-1]
                a[n-i-1][n-j-1] = a[n-j-1][i]
                a[n-j-1][i] = tmp
            Next
        Next
    End

    Function Copy2D:T[][](a:T[][])
        Local cpy:T[][]
        cpy = cpy.Resize(a.Length())
        For Local x := 0 Until a.Length()
            cpy[x] = cpy[x].Resize(a[x].Length())
            For Local y := 0 Until a[x].Length()
                cpy[x][y] = a[x][y]
            Next
        Next
        Return cpy
    End

    Function Reset:Void(a:T[][], defaultValue:T)
        For Local x := 0 Until a.Length()
            For Local y := 0 Until a[x].Length()
                a[x][y] = defaultValue
            Next
        Next
    End

    Function Reset:Void(a:T[], defaultValue:T)
        For Local i := 0 Until a.Length()
            a[i] = defaultValue
        Next
    End
    
    Function Flatten:T[](arr:T[][])
        Local elements := New Stack<T>()
        For Local x := 0 Until arr.Length()
            For Local y := 0 Until arr[x].Length()
                elements.Push(arr[x][y])
            Next
        Next
        Return elements.ToArray()
    End

    Function Flatten:T[](arr:T[][][])
        Local elements := New Stack<T>()
        For Local x := 0 Until arr.Length()
            For Local y := 0 Until arr[x].Length()
                For Local z := 0 Until arr[x][y].Length()
                    elements.Push(arr[x][y][z])
                Next
            Next
        Next
        Return elements.ToArray()
    End

End

' Joins an array together wit a seperator string
Function JoinArray$(arr$[], seperator$)
    If (arr.Length() = 0) Then Return ""
    If (arr.Length() = 1) Then Return arr[0]
    Local pathString := ""
    For Local i := 0 To arr.Length()-2
        pathString += arr[i] + seperator
    Next
    Return pathString + arr[arr.Length()-1]
End
