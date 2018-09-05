module Request.Card exposing
    ( CardMutationResponse
    , create
    , queryList
    , queryListDecoder
    )

import Data.AuthToken exposing (AuthToken)
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


type alias CardMutationResponse =
    Result GraphQLClient.Error (Helper.MutationResult Card)


create : { r | title : String, columnId : String } -> Maybe AuthToken -> Task GraphQLClient.Error (Helper.MutationResult Card)
create { title, columnId } maybeToken =
    createCardMutationRoot
        |> mutationDocument
        |> request { input = { title = title, columnId = columnId } }
        |> Helper.sendMutationRequest maybeToken


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


createCardMutationRoot : ValueSpec NonNull ObjectType (Helper.MutationResult Card) { b | input : { a | title : String, columnId : String } }
createCardMutationRoot =
    let
        result =
            Builder.object Helper.MutationResult
                |> with (aliasAs "object" (field "card" [] (nullable Card.object)))
                |> with (field "errors" [] (list Helper.errorObject))
    in
    extract
        (field "createCard"
            [ ( "input", Arg.variable createCardInput ) ]
            result
        )


createCardInput : Var.Variable { b | input : { a | title : String, columnId : String } }
createCardInput =
    Var.required "input"
        .input
        (Var.object "CreateCardInput"
            [ Var.field "title" .title Var.string
            , Var.field "column_id" .columnId Var.string
            ]
        )
