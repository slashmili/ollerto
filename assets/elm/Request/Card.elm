module Request.Card exposing (queryList, queryListDecoder)

import Data.Board exposing (Hashid)
import Data.Card as Card exposing (Card)
import GraphQL.Client.Http as GraphQLClient
import GraphQL.Request.Builder as Builder exposing (..)
import GraphQL.Request.Builder.Arg as Arg
import GraphQL.Request.Builder.Variable as Var
import Json.Decode
import Json.Encode
import Request.Helper as Helper
import Task exposing (Task)


queryList : Hashid -> Json.Encode.Value
queryList hashid =
    cardsQueryroot
        |> queryDocument
        |> request { hashid = Data.Board.hashidToString hashid }
        |> Helper.queryPayload


queryListDecoder : Json.Decode.Decoder (List Card)
queryListDecoder =
    cardsQueryroot
        |> queryDocument
        |> request { hashid = "" }
        |> Helper.queryDecoder


cardsQueryroot : ValueSpec NonNull ObjectType (List Card) { a | hashid : String }
cardsQueryroot =
    let
        hashid =
            Var.required "hashid" .hashid Var.string
    in
    extract
        (field "cards" [ ( "hashid", Arg.variable hashid ) ] (Builder.list Card.object))
