Strict

Import coreproc.io.psd

Function RenderLabel:Void(t:TextLabel, spatial:Spatial)
    Assert(t <> Null, "TextLabel is null!")
    Assert(spatial <> Null, "Spatial is null!")
    Assert(t.font <> Null, "Font not found to render text: " + t.txt)
    Local x := spatial.x
    Local y := spatial.y
    If (t.alignX = 0.5)
        x += spatial.width / 2
    Else If (t.alignX = 1.0)
        x += spatial.width
    End

    canvas.PushMatrix()
    canvas.Translate(x, y)
    canvas.Scale(spatial.scaleX, spatial.scaleY)

    canvas.SetColor(t.r, t.g, t.b)
    t.font.DrawString(t.txt, 0, 0, t.alignX, t.alignY, False, t.leading, t.tracking)

    canvas.PopMatrix()
    canvas.SetColor(1, 1, 1)
End

Function SetLabelByName:Void(row:TextLabel, newText$)
    row.txt = newText
End

Function RenderPicture:Void(picture:Picture, spatial:Spatial)
    canvas.PushMatrix()
    canvas.Translate(spatial.x + spatial.width / 2, spatial.y + spatial.height / 2)
    canvas.Scale(spatial.scaleX, spatial.scaleY)
    DrawSprite(picture.sprite, 0, 0, picture.frame)
    canvas.PopMatrix()
End

Function RenderLayers:Void(psd:PSD, layers:Layer[])
    Assert(layers.Length() > 0, "Nothing to render")
    For Local layer := EachIn layers
        If (Not layer.visible) Then Continue        
        Local id := layer.id

        Local spatial := psd.spatials.Get(id)
        Local picture := psd.pictures.Get(id)
        Local label   := psd.textLabels.Get(id)

        If (picture) Then 
            RenderPicture(picture, spatial)
        Else If (label And spatial)
            RenderLabel(label, spatial)
        End
    Next
End

Function RenderLayers:Void(psd:PSD, path$ = "")
    Assert(GetLayersByPath(psd, path).Length() > 0, "Nothing to render for " + path)
    RenderLayers(psd, GetLayersByPath(psd, path))
End

