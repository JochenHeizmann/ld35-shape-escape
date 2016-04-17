Import mojo2
Import coreproc.vendor.skn3.xml
Import coreproc.globals

Class BitmapFont
    Const CHAR_COUNT:Int = 255

    Const ASC_SPACE:Int = 32
    Const ASC_LF:Int = 10
    Const ASC_CR:Int = 13
    Const ASC_UPPER_A:Int = 65

    Field name:String
    Field atlasName:String
    Field atlas:Image
    
    Field srcX:Int[]
    Field srcY:Int[]
    Field srcWidth:Int[]
    Field srcHeight:Int[]
    Field baseline:Float[]
    Field maxHeight:Int
    Field maxBaseline:Float
    Field maxCharWidth%
    Field maxCharHeight%
    
    Method New()
        srcX = New Int[CHAR_COUNT]
        srcY = New Int[CHAR_COUNT]
        srcWidth = New Int[CHAR_COUNT]
        srcHeight = New Int[CHAR_COUNT]
        baseline = New Float[CHAR_COUNT]
    End
    
    Method TextWidth:Int(str:String,offset:Int=0,length:Int=-1)
        If length <= 0 Then Return 0
        If offset < 0 Or offset+length > str.Length Then Return 0
        Local rv:Int = 0
        For Local i:Int = offset Until offset+length
            rv += srcWidth[str[i]]
        Next
        Return rv
    End
    
    Method TextHeight:Int(str:String,offset:Int=0,length:Int=-1)
        If length <= 0 Then Return 0
        If offset < 0 Or offset+length > str.Length Then Return 0
        Local rv:Int = 0
        For Local i:Int = offset Until offset+length
            If rv < srcHeight[str[i]] Then rv = srcHeight[str[i]]
        Next
        Return rv
    End
    
    Method DrawString:Void(str:String, x:Int, y:Int, alignX:Float=0, alignY:Float=0, useBaseline:Bool=False, leading% =  0, tracking# = 0)
        If (leading = 0) Then leading = srcHeight[ASC_UPPER_A]

        Local strlen:Int = str.Length
        Local rx:Int = 0
        Local ry:Int = 0 ' TODO: newlines
        Local bl:Float = 0
        Local totalWidth := [0]
        Local totalHeight:Int = srcHeight[ASC_UPPER_A]


        tracking = srcWidth[KEY_W] * tracking
        Local lineNo := 0
        For Local i:Int = 0 Until strlen
            If useBaseline Then bl = baseline[str[i]] Else bl = srcHeight[str[i]] - baseline[str[i]]
            Select str[i]
                Case ASC_SPACE
                Case ASC_LF
                    lineNo += 1
                    totalWidth = totalWidth.Resize(lineNo+1)

                    rx = 0
                    ry += leading
                Case ASC_CR
                    lineNo += 1
                    totalWidth = totalWidth.Resize(lineNo+1)

                    rx = 0
                    ry += leading
                Default
                    
            End
            rx += srcWidth[str[i]] + tracking
            If rx > totalWidth[lineNo] Then totalWidth[lineNo] = rx
        Next
        lineNo = 0
        rx = x-alignX*totalWidth[lineNo]
        ry = y-alignY*totalHeight
        For Local i:Int = 0 Until strlen
            If useBaseline Then bl = baseline[str[i]] Else bl = srcHeight[str[i]] - baseline[str[i]]
            Select str[i]
                Case ASC_SPACE
                Case ASC_LF
                    lineNo += 1
                    rx = x-alignX*totalWidth[lineNo]
                    ry += leading
                Case ASC_CR
                    lineNo += 1
                    rx = x-alignX*totalWidth[lineNo]
                    ry += leading
                Default
                    canvas.DrawRect(rx, ry - bl,atlas, srcX[str[i]], srcY[str[i]], srcWidth[str[i]], srcHeight[str[i]])
            End
            rx += srcWidth[str[i]] + tracking
        Next
    End
    
    Function LoadFonts:StringMap<BitmapFont>(xmlFile$, filter% = Image.Filter)
        Local fonts:StringMap<BitmapFont>

        Local pathParts := xmlFile.Split("/")
        Local fileName := pathParts[pathParts.Length()-1]
        Local basePath := xmlFile.Replace(fileName, "")

        Local doc := New XMLDoc
        fonts = New StringMap<BitmapFont>()

        Local content:String = app.LoadString(xmlFile)
        Local error:XMLError = New XMLError
        doc = ParseXML(content, error)
        If Not doc Or error.error Then Error "Unable to parse xml! " + error.message

        For Local fontNode := EachIn doc.GetChildren("font")
            Local f := New BitmapFont()
            f.name = fontNode.GetXMLAttribute("name").value
            Print "Loading font " + f.name
            f.atlasName = fontNode.GetXMLAttribute("atlas").value

            f.atlas = Image.Load(basePath +  f.atlasName, .5, .5, filter)
            If (Not f.atlas) Then f.atlas = Image.Load(f.atlasName, .5, .5, filter)
            If (Not f.atlas) Then Error "Cannot find font atlas: " + basePath +  f.atlasName

            f.maxCharWidth = Int(fontNode.GetXMLAttribute("maxCharWidth").value)
            f.maxCharHeight = Int(fontNode.GetXMLAttribute("maxCharHeight").value)

            For Local glyphNode := EachIn fontNode.GetChildren("glyph")
                Local code := 0
                f.baseline[code] = 0
                f.srcX[code] = 0
                f.srcY[code] = 0
                f.srcWidth[code] = 0
                f.srcHeight[code] = 0

                If (glyphNode.GetXMLAttribute("code"))
                    code = Int(glyphNode.GetXMLAttribute("code").value)
                End

                If (glyphNode.GetXMLAttribute("baseline"))
                    f.baseline[code] = Float(glyphNode.GetXMLAttribute("baseline").value)
                End

                If (glyphNode.GetXMLAttribute("srcX"))
                    f.srcX[code] = Int(glyphNode.GetXMLAttribute("srcX").value)
                End
                If (glyphNode.GetXMLAttribute("srcY"))
                    f.srcY[code] = Int(glyphNode.GetXMLAttribute("srcY").value)
                End
                If (glyphNode.GetXMLAttribute("srcWidth"))
                    f.srcWidth[code] = Int(glyphNode.GetXMLAttribute("srcWidth").value)
                End
                If (glyphNode.GetXMLAttribute("srcHeight"))
                    f.srcHeight[code] = Int(glyphNode.GetXMLAttribute("srcHeight").value)
                End

                If f.maxHeight < f.srcHeight[code] Then f.maxHeight = f.srcHeight[code]
                If f.maxBaseline < f.baseline[code] Then f.maxBaseline = f.baseline[code]
            Next
            fonts.Set(f.name, f)
        Next

        Return fonts
    End
End