Strict

Import brl.json
Import brl.filestream
Import brl.databuffer
Import mojo2
Import coreproc.util.debug
Import coreproc.graphics.texturepacker

Class MapLayer
    Field data%[]
    Field width%
    Field height%
    Field opacity#
    Field visible?
    Field name$
    Field properties := New StringMap<String>
End

Class Tileset
    Field firstGid%
    Field image:Sprite[]
    Field name$
    Field tileproperties := New IntMap<StringMap<String>>
End

Class TiledMap
    Field width%
    Field height%
    Field layers:MapLayer[]
    Field properties := New StringMap<String>
    Field tileWidth%
    Field tileHeight%
    Field tilesets:Tileset[]
End

Function LoadMap:TiledMap(jsonFile$, filter% = Image.Filter)
    If (Not jsonFile.Contains("://")) Then jsonFile = "monkey://data/" + jsonFile

    Local f := DataBuffer.Load(jsonFile)
    Assert(f <> Null, "Couldn't load " + jsonFile)

    Local json := f.PeekString(0)
    Assert(json <> "", "Json File is empty! " + jsonFile)

    Local j := JsonParser(json)
    Local root := JsonObject(j.ParseValue())
    Assert(root <> Null, "Cannot find root node: " + jsonFile)

    Local m := New TiledMap()
    m.width = JsonNumber(root.Get("width")).IntValue()
    m.height = JsonNumber(root.Get("height")).IntValue()
    m.tileWidth = JsonNumber(root.Get("tilewidth")).IntValue()
    m.tileHeight = JsonNumber(root.Get("tileheight")).IntValue()

    Local layers := JsonArray(root.Get("layers"))
    Assert(layers <> Null, "No layers found!")

    m.layers = m.layers.Resize(layers.Length())

    For Local i := 0 Until layers.Length()
        Local layer := JsonObject(layers.Get(i))
        Assert(layer <> Null, "Layer not found: " + i)        

        Local type := JsonString(layer.Get("type")).StringValue()

        ' TODO: Add support for object groups
        If (type <> "tilelayer") Then Continue

        Local mapLayer := New MapLayer
        mapLayer.width = JsonNumber(layer.Get("width")).IntValue()
        mapLayer.height = JsonNumber(layer.Get("height")).IntValue()
        mapLayer.opacity = JsonNumber(layer.Get("opacity")).FloatValue()
        mapLayer.visible = JsonBool(layer.Get("visible")).BoolValue()
        mapLayer.name = JsonString(layer.Get("name")).StringValue()

        Local mapProperties := JsonObject(layer.Get("properties"))
        If (mapProperties)
            For Local prop := EachIn mapProperties.GetData()
                mapLayer.properties.Set(prop.Key(), JsonString(prop.Value()).StringValue())
            Next
        End
        
        Local mapData := JsonArray(layer.Get("data"))
        Assert(mapData <> Null, "Map Data not found!")
        mapLayer.data = mapLayer.data.Resize(mapLayer.width * mapLayer.height)

        For Local j := 0 Until mapData.Length()
            Local tileId := JsonNumber(mapData.Get(j)).IntValue()
            mapLayer.data[j] = tileId
        Next

        m.layers[i] = mapLayer
    Next

    Local tilesets := JsonArray(root.Get("tilesets"))
    Assert(tilesets <> Null, "No Tilesets found " + jsonFile)
    m.tilesets = m.tilesets.Resize(tilesets.Length())

    For Local i := 0 Until tilesets.Length()
        Local tileset := JsonObject(tilesets.Get(i))
        Assert(tileset <> Null, "Tileset not found " + i + " / " + jsonFile)

        Local tset := New Tileset()

        tset.firstGid = JsonNumber(tileset.Get("firstgid")).IntValue()
        tset.name = JsonString(tileset.Get("name")).StringValue()

        Local tileWidth := JsonNumber(tileset.Get("tilewidth")).IntValue()
        Local tileHeight := JsonNumber(tileset.Get("tileheight")).IntValue()
        Local imageWidth := JsonNumber(tileset.Get("imagewidth")).IntValue()
        Local imageHeight := JsonNumber(tileset.Get("imageheight")).IntValue()

        ' TODO: Clean Up Path
        Local imageFileName := JsonString(tileset.Get("image")).StringValue().Replace("../", "")

        tset.image = tset.image.Resize((imageWidth / tileWidth) * (imageHeight / tileHeight))

        Local baseTexture := Image.Load(imageFileName, 0.5, 0.5, filter)
        For Local y := 0 Until imageHeight/tileHeight
            For Local x := 0 Until imageWidth/tileWidth
                Local idx := x + (y * imageWidth / tileWidth)
                Local sprite := New Sprite()
                sprite.image = New Image(baseTexture, x * tileWidth, y * tileHeight, tileWidth, tileHeight)
                sprite.atlasW = tileWidth
                sprite.atlasH = tileHeight
                sprite.atlasOriginalW = tileWidth
                sprite.atlasOriginalH = tileHeight
                sprite.handleX = tileWidth
                sprite.handleY = tileHeight
                tset.image[idx] = sprite
            Next
        Next


        ' Field tileproperties := New IntMap<StringMap<String>>
        Local properties := JsonObject(tileset.Get("tileproperties"))
        If (properties)
            Local s := New StringMap<String>
            For Local prop := EachIn properties.GetData()
                Local id% = Int(prop.Key())
                Local props := New StringMap<String>()
                
                For Local entry := EachIn JsonObject(prop.Value()).GetData()
                    props.Set(entry.Key(), JsonString(entry.Value()).StringValue())
                Next

                tset.tileproperties.Set(id, props)
            Next
        End

        m.tilesets[i] = tset
    End

    Return m
End

Function RenderMap:Void(m:TiledMap)
    canvas.PushMatrix()

    Local tileset := m.tilesets[0]

    For Local layer := EachIn m.layers
        If (Not layer) Then Continue
        If (Not layer.visible) Then Continue

        For Local x := 0 Until layer.width
            For Local y := 0 Until layer.height
                Local index := x + (y * layer.width)
                Local gId := layer.data[index] - tileset.firstGid
                If (gId >= 0)
                    DrawSprite(tileset.image[gId], x * m.tileWidth, y * m.tileHeight)
                End
            Next
        Next

        canvas.SetAlpha(layer.opacity)
    Next
    canvas.SetAlpha(1)

    canvas.PopMatrix()
End

Function GetMapLayerByName:MapLayer(m:TiledMap, layerName$)
    For Local layer := EachIn m.layers
        If (layer And layer.name = layerName) Then Return layer
    Next
    Return Null
End
