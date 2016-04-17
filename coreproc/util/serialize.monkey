Strict

Import reflection
Import brl.datastream

Interface Serializable
    Method OnSerialize?(varName$, typeName$, object:Object, stream:Stream)
    Method OnDeserialize?(varName$, typeName$, stream:Stream)
End

' Use this function to serialize any object to a binary stream
' NOTE: You have to add a reflection filter based on the
' object time you want to serialize
Function Serialize:Void(className$, obj:Object, stream:Stream)
    If (Not stream) Then Error "No valid stream object!"
    If (Not obj) Then Error "No valid object instance given!"
    Local c := GetClass(className)

    If (Not c) Then Print "[REFLECTION | SERIALIZE] ClassName " + className + " not found. Have you enabled correct reflection filter?" ; Return

    For Local f := EachIn c.GetFields(true)
        Select(f.Type().Name)
            Case "monkey.boxes.BoolObject"
                stream.WriteByte(UnboxBool(f.GetValue(obj)))

            Case "monkey.boxes.IntObject"
                stream.WriteInt(UnboxInt(f.GetValue(obj)))

            Case "monkey.boxes.FloatObject"
                stream.WriteFloat(UnboxFloat(f.GetValue(obj)))

            Case "monkey.boxes.StringObject"
                Local str := UnboxString(f.GetValue(obj))
                stream.WriteInt(str.Length())
                stream.WriteString(str)

            Case "monkey.boxes.ArrayObject<Int>"
                Local arr := ArrayBoxer<Int>.Unbox(f.GetValue(obj))
                stream.WriteInt(arr.Length())
                For Local element := EachIn arr
                    stream.WriteInt(element)
                Next

            Case "monkey.boxes.ArrayObject<Bool>"
                Local arr := ArrayBoxer<Bool>.Unbox(f.GetValue(obj))
                stream.WriteInt(arr.Length())
                For Local element := EachIn arr
                    stream.WriteByte(element)
                Next

            Case "monkey.boxes.ArrayObject<Float>"
                Local arr := ArrayBoxer<Float>.Unbox(f.GetValue(obj))
                stream.WriteInt(arr.Length())
                For Local element := EachIn arr
                    stream.WriteFloat(element)
                Next

            Case "monkey.boxes.ArrayObject<String>"
                Local arr := ArrayBoxer<String>.Unbox(f.GetValue(obj))
                stream.WriteInt(arr.Length())
                For Local element := EachIn arr
                    stream.WriteInt(element.Length())
                    stream.WriteString(element)
                Next

            Default 
                If (f.Type().Name.StartsWith("monkey.boxes.ArrayObject")) 
                    Local result := False
                    If (Serializable(obj))
                        result = Serializable(obj).OnSerialize(f.Name, f.Type().Name, f.GetValue(obj), stream)
                    End
                    If (Not result)
                        Print "Skipping " + f.Name + ":" + f.Type().Name
                    End
                Else
                    Serialize(f.Type().Name, f.GetValue(obj), stream)
                End
        End
    Next
End

' Use this function to deserialize any object from a binary stream
' save with the Serialize function.
Function Deserialize:Void(className$, obj:Object, stream:Stream)    
    If (Not stream) Then Error "No valid stream object!"
    If (Not obj) Then Error "No valid object instance given!"
    Local c := GetClass(className)
    If (Not c) Then Print "[REFLECTION | SERIALIZE] ClassName " + className + " not found. Have you enabled correct reflection filter?" ; Return
    For Local f := EachIn c.GetFields(true)
        Select(f.Type().Name)
            Case "monkey.boxes.BoolObject"
                Local val := stream.ReadByte()
                f.SetValue(obj, BoxBool(Bool(val)))

            Case "monkey.boxes.IntObject"
                Local val := stream.ReadInt()
                f.SetValue(obj, BoxInt(val))

            Case "monkey.boxes.FloatObject"
                Local val := stream.ReadFloat()
                f.SetValue(obj, BoxFloat(val))

            Case "monkey.boxes.StringObject"
                Local len := stream.ReadInt()
                Local val := stream.ReadString(len)
                f.SetValue(obj, BoxString(val))

            Case "monkey.boxes.ArrayObject<Int>"
                Local len := stream.ReadInt()
                Local arr%[len]
                For Local i := 0 Until len
                    arr[i] = stream.ReadInt()
                Next
                f.SetValue(obj, ArrayBoxer<Int>.Box(arr))

            Case "monkey.boxes.ArrayObject<Bool>"
                Local len := stream.ReadInt()
                Local arr?[len]
                For Local i := 0 Until len
                    arr[i] = Bool(stream.ReadByte())
                Next
                f.SetValue(obj, ArrayBoxer<Bool>.Box(arr))

            Case "monkey.boxes.ArrayObject<Float>"
                Local len := stream.ReadInt()
                Local arr#[len]
                For Local i := 0 Until len
                    arr[i] = stream.ReadFloat()
                Next
                f.SetValue(obj, ArrayBoxer<Float>.Box(arr))

            Case "monkey.boxes.ArrayObject<String>"
                Local len := stream.ReadInt()
                Local arr$[len]
                For Local i := 0 Until len
                    Local strLen := stream.ReadInt()
                    arr[i] = stream.ReadString(strLen)
                Next
                f.SetValue(obj, ArrayBoxer<String>.Box(arr))

            Default 
                If (f.Type().Name.StartsWith("monkey.boxes.ArrayObject"))                    
                    Local result := False
                    If (Serializable(obj))
                        result = Serializable(obj).OnDeserialize(f.Name, f.Type().Name, stream)
                    End
                    If (Not result)
                        Print "Skipping " + f.Name + ":" + f.Type().Name
                    End
                Else
                    Deserialize(f.Type().Name, f.GetValue(obj), stream)
                End
        End
    Next
End