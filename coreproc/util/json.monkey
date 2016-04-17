Strict

Import brl.json
Import mojo.app
Import coreproc.util.arr

Class JsonMap
    ' Convert a Json String to a JsonMap (which is a StringMap<String>)
    Function Load:StringMap<String>(jsonString$)
        Local jsonParser := New JsonParser(jsonString)
        Return Create(jsonParser.ParseValue())
    End

    ' Loads a json file and converts it to a JsonMap (StringMap<String>)
    Function LoadFromFile:StringMap<String>(jsonFile$)
        Local jsonString := LoadString("data/design.json")
        Return Load(jsonString)
    End

    ' Filters a JsonMap and returns a new filtered one (copy)
    Function GetSubnode:StringMap<String>(map:StringMap<String>, filter$)
        Local subNodes := New StringMap<String>
        For Local entry := EachIn map
            If (entry.Key() = filter)
                subNodes.Set(entry.Key().Replace(filter, ""), entry.Value()) 
            Else If (entry.Key().StartsWith(filter + "."))
                subNodes.Set(entry.Key().Replace(filter + ".", ""), entry.Value())
            Else If (entry.Key().StartsWith(filter + "["))
                subNodes.Set(entry.Key().Replace(filter, ""), entry.Value())
            End        
        Next
        Return subNodes
    End

    ' Tries to determine the length of an array in the stringmap
    Function GetLength%(map:StringMap<String>, key$)
        If (key = "")
            If (Not map.Get(key + "length")) Then Return 0
            Return Int(map.Get(key + "length"))
        Else
            If (Not map.Get(key + ".length")) Then Return 0
            Return Int(map.Get(key + ".length"))
        End
    End

    ' Converts the whole stringmap to an array
    Function ToString$(sMap:StringMap<String>)
        Local str$ = ""
        Local addNewLine := False
        For Local entry := EachIn sMap
            If (addNewLine) Then str += "~n" 
            If (entry.Key() = "")
                str += entry.Value()
            Else
                str += entry.Key() + " = " + entry.Value()
            End
            addNewLine = True
        Next
        Return str
    End

    ' Gets an array of stringmaps with each value of the given path
    Function GetArray:StringMap<String>[](sMap:StringMap<String>, path$)
        Local len := GetLength(sMap, path)
        Local result:StringMap<String>[len]
        For Local i := 0 Until len
            result[i] = JsonMap.GetSubnode(sMap, path + "[" + i + "]")
        Next
        Return result
    End

    Function Join$(sMap:StringMap<String>[], seperator$)
        Local retVal$
        For Local elements := EachIn sMap
            For Local text := EachIn elements.Values()
                retVal += text + seperator
            Next
        Next
        Return retVal[..-1]
    End

    ' Parses the json string and creates a StringMap<String>
    Function Create:StringMap<String>(val:JsonValue, path:StringStack = Null, jsonMap:StringMap<String> = Null)
        If (path = Null) Then path = New StringStack()
        If (jsonMap = Null) Then jsonMap = New StringMap<String>

        Local currPath := JoinArray(path.ToArray(), ".").Replace(".[", "[")

        If (JsonObject(val))
            For Local v := EachIn JsonObject(val).GetData()
                path.Push(v.Key())
                Create(v.Value(), path, jsonMap)
                path.Pop()
            Next
        Else If (JsonArray(val))
            For Local i := 0 Until JsonArray(val).Length()
                path.Push("[" + i + "]")
                Create(JsonArray(val).Get(i), path, jsonMap)
                path.Pop()
            Next
            jsonMap.Set(currPath + ".length", String(JsonArray(val).Length()))
        Else If (JsonNull(val))
            jsonMap.Set(currPath, "NULL")
        Else If (JsonBool(val))
            jsonMap.Set(currPath, Int(val.BoolValue()))
        Else If (JsonString(val))
            jsonMap.Set(currPath, val.StringValue())
        Else If (JsonNumber(val))
            jsonMap.Set(currPath, String(JsonNumber(val).FloatValue()))
        End 
        Return jsonMap
    End

    ' get element casted as int
    ' Gets the value and if not found returns the given default value
    Function GetInt%(sMap:StringMap<String>, element$, defaultValue% = 0)
        Return Int(GetString(sMap, element, defaultValue))
    End

    ' get element casted as float
    ' Gets the value and if not found returns the given default value
    Function GetFloat#(sMap:StringMap<String>, element$, defaultValue# = 0.0)
        Return Float(GetString(sMap, element, defaultValue))
    End

    ' get element casted as bool
    ' Gets the value and if not found returns the given default value
    Function GetBool?(sMap:StringMap<String>, element$, defaultValue? = False)
        Return Bool(Int(GetString(sMap, element, String(Int(defaultValue)))))
    End

    ' get element casted as string
    ' Gets the value and if not found returns the given default value
    Function GetString$(sMap:StringMap<String>, element$, defaultValue$ = "")
        If (sMap.Get(element))
            defaultValue = sMap.Get(element)
        End
        Return defaultValue
    End
End
