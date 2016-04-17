Strict

Function IsTouchDevice?()    
    #If TARGET="ios" Or TARGET="android" Or TARGET="winrt"
        Return True
    #else
        Return False
    #end
End