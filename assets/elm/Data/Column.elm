module Data.Column exposing (Column, object)

import GraphQL.Request.Builder as Builder


type alias Column =
    { id : String, name : String, order : Int }


object : Builder.ValueSpec Builder.NonNull Builder.ObjectType Column vars
object =
    Builder.object Column
        |> Builder.with (Builder.field "id" [] Builder.string)
        |> Builder.with (Builder.field "name" [] Builder.string)
        |> Builder.with (Builder.field "order" [] Builder.int)
