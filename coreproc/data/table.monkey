Strict

Import coreproc.util.debug

Class Table<T>
    Field autoIncrement := 0
    Field rows := New IntMap<T>    ' Global indexes := New List<Index<T>>

    Method GetAllRows:MapValues<Int,T>()
        Return rows.Values()
    End

    Method GetById:T(id%)
        Return rows.Get(id)
    End

    Method Insert%(row:T)
        autoIncrement += 1
        row.id = autoIncrement

        Assert(Not rows.Get(row.id), "Row with id " + row.id + " already exists!")
        
        rows.Set(row.id, row)

        UpdateIndicies(row)

        Return row.id
    End

    Method Count%()
        Return rows.Count()
    End

    Method Update:Void(row:T)
        Assert(rows.Get(row.id) <> Null, "Row with id " + row.id + " doesn't exist")        
        rows.Set(row.id, row)
        UpdateIndicies(row)
    End

    Method Delete:Void(row:T)
        RemoveIndicies(row)
        rows.Remove(row.id)
    End

    Method Delete:Void(rowId%)
        Delete(rows.Get(rowId))
    End

    ' You can overwrite this methods if you'd like to use indicies
    Method UpdateIndicies:Void(row:T)
    End

    Method RemoveIndicies:Void(row:T)
    End
End