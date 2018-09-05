module Data.Column exposing (Column, ColumnEvent, columnEventObject, object)

import GraphQL.Request.Builder as Builder


type alias Column =
    { id : String, name : String, position : Float }


type alias ColumnEvent =
    { column : Column, action : String }


object : Builder.ValueSpec Builder.NonNull Builder.ObjectType Column vars
object =
    Builder.object Column
        |> Builder.with (Builder.field "id" [] Builder.string)
        |> Builder.with (Builder.field "name" [] Builder.string)
        |> Builder.with (Builder.field "position" [] Builder.float)


columnEventObject : Builder.ValueSpec Builder.NonNull Builder.ObjectType ColumnEvent vars
columnEventObject =
    Builder.object ColumnEvent
        |> Builder.with (Builder.field "column" [] object)
        |> Builder.with (Builder.field "action" [] Builder.string)
