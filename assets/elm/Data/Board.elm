module Data.Board exposing (Board, BoardWithRelations, Hashid, boardWithRelationsToBoard, hashidParser, hashidToString, object, objectWithRelation, stringToHashid)

-- External

import Data.Column exposing (Column)
import GraphQL.Request.Builder as Builder
import UrlParser


type alias Board =
    { id : String, name : String, hashid : Hashid }


type alias BoardWithRelations =
    { id : String, name : String, hashid : Hashid, columns : List Column }


type Hashid
    = Hashid String


stringToHashid : String -> Hashid
stringToHashid id =
    Hashid id


hashidParser : UrlParser.Parser (Hashid -> a) a
hashidParser =
    UrlParser.custom "HASHID" (Ok << Hashid)


hashidToString : Hashid -> String
hashidToString (Hashid id) =
    id


object : Builder.ValueSpec Builder.NonNull Builder.ObjectType Board vars
object =
    Builder.object Board
        |> Builder.with (Builder.field "id" [] Builder.string)
        |> Builder.with (Builder.field "name" [] Builder.string)
        |> Builder.with (Builder.field "hashid" [] (Builder.map stringToHashid Builder.string))


objectWithRelation : Builder.ValueSpec Builder.NonNull Builder.ObjectType BoardWithRelations vars
objectWithRelation =
    Builder.object BoardWithRelations
        |> Builder.with (Builder.field "id" [] Builder.string)
        |> Builder.with (Builder.field "name" [] Builder.string)
        |> Builder.with (Builder.field "hashid" [] (Builder.map stringToHashid Builder.string))
        |> Builder.with (Builder.field "columns" [] (Builder.list Data.Column.object))


boardWithRelationsToBoard : BoardWithRelations -> Board
boardWithRelationsToBoard boardWithRel =
    Board boardWithRel.id boardWithRel.name boardWithRel.hashid
