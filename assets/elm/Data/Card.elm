module Data.Card exposing (Card, object)

import GraphQL.Request.Builder as Builder


type alias Card =
    { id : String, title : String, position : Float, columnId : String }


object : Builder.ValueSpec Builder.NonNull Builder.ObjectType Card vars
object =
    Builder.object Card
        |> Builder.with (Builder.field "id" [] Builder.string)
        |> Builder.with (Builder.field "title" [] Builder.string)
        |> Builder.with (Builder.field "position" [] Builder.float)
        |> Builder.with (Builder.field "column_id" [] Builder.string)
