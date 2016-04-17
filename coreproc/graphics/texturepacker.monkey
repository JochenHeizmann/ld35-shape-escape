Strict

Import mojo2
Import mojo.app
Import mojo2.graphics
Import coreproc.util.debug
Import coreproc.vendor.skn3.xml
Import brl.filesystem 
Import brl.filepath
Import coreproc.globals

Class Sprite
    Field image:Image
    Field atlasX%, atlasY%, atlasW%, atlasH%
    Field atlasOffsetX%, atlasOffsetY%
    Field handleX%, handleY%
    Field atlasOriginalW%, atlasOriginalH%
End

Class Spritesheet
    Field images := New StringMap<Image>
    Field frames := New StringMap<Sprite>
End

Function GetSpriteAnimation:Sprite[](images:StringMap<Sprite>, imageName$)
    Local animation := New Stack<Sprite>
    Local fileIterationPlaceholder := ""        
    If (imageName.Contains("{n1}")) Then fileIterationPlaceholder = "{n1}"
    If (imageName.Contains("{n}")) Then fileIterationPlaceholder = "{n}"

    Local i := 0
    If (fileIterationPlaceholder = "{n1}") Then i = 1

    If (fileIterationPlaceholder = "") Then Return [images.Get(imageName)]

    While (1)
        Local name := imageName.Replace(fileIterationPlaceholder, i)
        Local img := images.Get(name)
        If (img)
            animation.Push(img)
        Else
            Exit
        End
        i += 1
    Wend

    Return animation.ToArray()
End

Function GetImageAnimation:Image[](images:StringMap<Sprite>, imageName$)
    Local sprites := GetSpriteAnimation(images, imageName)
    Local imageCount := sprites.Length()
    Local imageFrames:Image[imageCount]
    For Local i := 0 Until imageCount
        imageFrames[i] = sprites[i].image
    Next
    Return imageFrames
End

Class TexturePacker
    Function LoadXml:Spritesheet(xmlFile$, flags:Int = Image.Filter) 
        If (Not xmlFile.Contains("://")) Then xmlFile = "monkey://data/" + xmlFile

        Local spritesheet := New Spritesheet()
        Local xmlFiles := New StringStack()

        ' Look up all relating files that we need
        Local fileIterationPlaceholder := ""        
        If (xmlFile.Contains("{n1}")) Then fileIterationPlaceholder = "{n1}"
        If (xmlFile.Contains("{n}")) Then fileIterationPlaceholder = "{n}"
        If (fileIterationPlaceholder = "")
            xmlFiles.Push(xmlFile)
        Else
            Local i := 0
            If (fileIterationPlaceholder = "{n1}") Then i = 1
            While (1)
                Local f := xmlFile.Replace(fileIterationPlaceholder, i)
                #if TARGET="html5"
                    If (LoadString(f) = "") Then Exit
                #else
                    If (FileSize(f) = 0) Then Exit
                #end
                xmlFiles.Push(f)
                i += 1
            Wend
        End

        ' Read all xml Files
        For Local xmlFile := EachIn xmlFiles
            Local content:String = LoadString(xmlFile)
            Local error:XMLError = New XMLError()
            
            Local xml := ParseXML(content, error)

            ' Lets do some sanity checks
            Assert(xml <> Null, "XML Doc is NULL!")
            Assert(Not error.error, "Unable to parse xml: " + error.ToString())
            Assert(xml.HasChildren(), "XML File has no childs.")
            Assert(xml.name = "textureatlas", "First Node must be 'TextureAtlas'")
            Assert(xml.HasAttribute("imagepath"), "Missing attribute 'imagepath' in 'TextureAtlas' node")

            ' Load in the base textures
            Local imagePath := xml.GetAttribute("imagepath")
            Local textureFile := ExtractDir(xmlFile) + "/" + imagePath
            If textureFile.StartsWith("/") Then textureFile = textureFile[1..]

            Local baseTexture := Image.Load(textureFile, .5, .5, flags)
            Assert(baseTexture <> Null, "Texture not found: " + textureFile)

            spritesheet.images.Set(imagePath, baseTexture)

            If (xml.HasAttribute("width")) Then Assert(baseTexture.Width() = xml.GetAttribute("width"), "Width of XML Attribute doesn't match image")
            If (xml.HasAttribute("height")) Then Assert(baseTexture.Height() = xml.GetAttribute("height"), "Height of XML Attribute doesn't match image")

            ' Grab all frames defined in the texture packer xml
            For Local child := EachIn xml.children
                ' Some more sanity checks
                Assert(child.name = "sprite", "Unknown node '" + child.name + "' found")

                For Local attr:String = EachIn ["n", "x", "y", "w", "h"]
                    Assert(child.HasAttribute(attr), "Missing attribute '" + attr + "' in sprite node")
                End

                For Local attr:String = EachIn ["r"]
                    Assert(Not child.HasAttribute(attr), "Attribute '" + attr + "' found but not yet implemented")
                Next

                Assert(Not(child.HasAttribute("r") And child.GetAttribute("r") <> "y"), "Invalid value for attribute 'r' in sprite node found")

                ' Read attirbutes
                Local name := child.GetAttribute("n")
                Local x := Int(child.GetAttribute("x"))
                Local y := Int(child.GetAttribute("y"))
                Local w := Int(child.GetAttribute("w"))
                Local h := Int(child.GetAttribute("h"))

                Local offsetX := 0, offsetY := 0, originalWidth := 0, originalHeight := 0
                If child.HasAttribute("ox") Then offsetX = Int(child.GetAttribute("ox"))
                If child.HasAttribute("oy") Then offsetY = Int(child.GetAttribute("oy"))
                If child.HasAttribute("ow") Then originalWidth = Int(child.GetAttribute("ow")) Else originalWidth = w
                If child.HasAttribute("oh") Then originalHeight = Int(child.GetAttribute("oh")) Else originalHeight = h

                Local frame := New Sprite()
                frame.image = New Image(baseTexture, x, y, w, h)
                frame.atlasX = x
                frame.atlasY = y
                frame.atlasW = w
                frame.atlasH = h
                frame.atlasOffsetX = offsetX
                frame.atlasOffsetY = offsetY
                frame.atlasOriginalW = originalWidth
                frame.atlasOriginalH = originalHeight
                frame.handleX = w / 2
                frame.handleY = h / 2

                spritesheet.frames.Set(name, frame)
            Next
        Next    

        Return spritesheet
    End
End

Function DrawSprite:Void(canvas:Canvas, sprite:Sprite, x#, y#, rotation# = 0.0, scaleX# = 1.0, scaleY# = 1.0)
    Assert(sprite <> Null, "[DrawSprite] Sprite = NULL!")
    Assert(sprite.image <> Null, "[DrawSprite] Sprite.image = NULL!")

    canvas.PushMatrix()

    canvas.Translate(x, y)
    canvas.Rotate(rotation)
    canvas.Scale(scaleX, scaleY)

    canvas.Translate(sprite.atlasOffsetX + sprite.handleX , sprite.atlasOffsetY + sprite.handleY)

''    canvas.DrawImage(sprite.image, 0, 0)

    canvas.Translate(-sprite.atlasOriginalW / 2 , -sprite.atlasOriginalH / 2)

    canvas.DrawImage(sprite.image, 0, 0)

    canvas.PopMatrix()
End

Function DrawSprite:Void(canvas:Canvas, sprite:Sprite[], x#, y#, rotation#, scaleX#, scaleY#, frame# = 0)
    Assert(frame < sprite.Length(), "[DrawSprite] Invalid Frame! (" + frame + ")")
    DrawSprite(canvas, sprite[frame], x, y, rotation, scaleX, scaleY)
End

Function DrawSprite:Void(canvas:Canvas, sprite:Sprite[], x#, y#, frame# = 0)
    Assert(frame < sprite.Length(), "[DrawSprite] Invalid Frame! (" + frame + ")")
    DrawSprite(canvas, sprite[frame], x, y)
End

Function DrawSprite:Void(sprite:Sprite, x#, y#, rotation#, scaleX#, scaleY#)
    DrawSprite(canvas, sprite, x, y, rotation, scaleX, scaleY)
End

Function DrawSprite:Void(sprite:Sprite, x#, y#)
    DrawSprite(canvas, sprite, x, y)
End

Function DrawSprite:Void(sprite:Sprite[], x#, y#, rotation#, scaleX#, scaleY#, frame# = 0)
    Assert(frame < sprite.Length(), "[DrawSprite] Invalid Frame! (" + frame + ")")
    DrawSprite(canvas, sprite[frame], x, y, rotation, scaleX, scaleY)
End

Function DrawSprite:Void(sprite:Sprite[], x#, y#, frame# = 0)
    Assert(frame < sprite.Length(), "[DrawSprite] Invalid Frame! (" + frame + ")")
    DrawSprite(canvas, sprite[frame], x, y)
End

