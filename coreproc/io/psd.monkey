Strict

Import coreproc.util.json
Import coreproc.graphics.texturepacker
Import coreproc.bitmapfont
Import mojo2

Class Layer
    Field id%
    Field name$
    Field path$
    Field visible? = True
End

Class Spatial
    Field x#
    Field y#
    Field width#
    Field height#
    Field scaleX#
    Field scaleY#
End

Class Picture
    Field name$
    Field sprite:Sprite[]
    Field frame#
End

Class TextLabel
    Field layerId%
    Field txt$
    Field font:BitmapFont
    Field r#, g#, b#
    Field alignX#, alignY#
    Field leading%
    Field tracking#
End

Class PSD
    Field fonts:StringMap<BitmapFont>
    Field spritesheet:Spritesheet

    Field data:StringMap<String>

    Field layers := New IntMap<Layer>
    Field layerIdByName := New StringMap<Int>

    Field spatials := New IntMap<Spatial>
    Field pictures := New IntMap<Picture>
    Field textLabels := New IntMap<TextLabel>
End

Function LoadPSD:PSD(filename$, filter% = Image.Filter)
    Return LoadPSD(JsonMap.LoadFromFile(filename), filter)
End

Function LoadPSD:PSD(data:StringMap<String>, filter% = Image.Filter)
    Local psd := New PSD()
    psd.data = data

    '
    ' Load Spritesheets --------------------------------------------------------
    '
    Local file := data.Get("document.spritesheet")
    Local spritesheet := TexturePacker.LoadXml(file, filter)
    psd.spritesheet = spritesheet

    '
    ' Load Fonts ---------------------------------------------------------------
    '
    Local fontFile := JsonMap.GetString(data, "document.fonts")
    If (fontFile <> "")
        psd.fonts =  BitmapFont.LoadFonts(fontFile, filter)
        Assert(psd.fonts <> Null, "Fonts not loaded")
    End

    '
    ' Add components -----------------------------------------------------------
    '
    For Local component := EachIn JsonMap.GetArray(data, "components")
        Local id := JsonMap.GetInt(component, ("zIndex"))

        '
        ' Set Base Layer
        '
        Local layer := New Layer()
        layer.id = id
        layer.name = JsonMap.GetString(component, "name")
        layer.path = JsonMap.Join(JsonMap.GetArray(component, "path"), "/")

        psd.layers.Set(id, layer)
        psd.layerIdByName.Set(layer.name, id)

        '
        ' Set Spatial component
        '
        Local spatial := New Spatial()
        spatial.x = JsonMap.GetInt(component, "x")
        spatial.y = JsonMap.GetInt(component, "y")
        spatial.width = JsonMap.GetInt(component, "width")
        spatial.height = JsonMap.GetInt(component, "height")
        spatial.scaleX = JsonMap.GetFloat(component, "scale.x")
        spatial.scaleY = JsonMap.GetFloat(component, "scale.y")
        psd.spatials.Set(id, spatial)

        Local type := JsonMap.GetString(component, "type")
        Select (type)
            '
            ' Set Picture component
            '
            Case "layer", "animation"
                Local filename := component.Get("filename")
                
                Local pic := New Picture()
                pic.name = filename

                Local file := filename
                If (type = "animation")
                    file = filename.Replace("1.png", "{n1}.png")
                    file = file.Replace("0.png", "{n}.png")
                End

                pic.sprite = GetSpriteAnimation(spritesheet.frames, file)

                pic.frame = 0

                psd.pictures.Set(id, pic)

            '
            ' Set Text Label component
            '
            Case "textLayer"
                Local text := New TextLabel()
                text.r = JsonMap.GetFloat(component, "text.color.red") / 255.0
                text.g = JsonMap.GetFloat(component, "text.color.green") / 255.0
                text.b = JsonMap.GetFloat(component, "text.color.blue") / 255.0
                text.txt = JsonMap.GetString(component, "text.text")

                If (JsonMap.GetString(component, "text.align") = "center")
                    text.alignX = 0.5          
                Else If (JsonMap.GetString(component, "text.align") = "right")
                    text.alignX = 1.0
                End

                Local atlasName := JsonMap.GetString(component, "text.atlas_name")
                text.font = psd.fonts.Get(atlasName)
                Assert(text.font <> Null, "Font not found!")

                If (JsonMap.GetString(component, "text.leading") = "auto")
                    text.leading = 0
                Else
                    text.leading = JsonMap.GetInt(component, "text.leading")
                End

                psd.textLabels.Set(id, text)
        End
    End

    Return psd
End

Function GetLayersByPath:Layer[](psd:PSD, path$)
    Local layers := New Stack<Layer>()
    For Local layer := EachIn psd.layers.Values()
        If (layer.path.StartsWith(path))
            layers.Push(layer)
        End
    Next
    Return layers.ToArray()
End

Function GetLayerByName:Layer(psd:PSD, name$)
    Local id := psd.layerIdByName.Get(name)
    Return psd.layers.Get(id)
End

Function GetPictureByName:Picture(psd:PSD, name$)
    Local id := psd.layerIdByName.Get(name)
    Return psd.pictures.Get(id)
End

Function GetSpatialByName:Spatial(psd:PSD, name$)
    Local id := psd.layerIdByName.Get(name)
    Return psd.spatials.Get(id)
End


