module Request.Column exposing (ColumnMutationResponse, ColumnResponse, create, subscribeColumnChange, subscribeColumnChangeDecoder)

-- Data
-- Tools
-- External

import Data.AuthToken exposing (AuthToken)
import Data.Column exposing (Column, ColumnEvent)
import GraphQL.Client.Http as GraphQLClient
import GraphQL.Request.Builder as Builder exposing (..)
import GraphQL.Request.Builder.Arg as Arg
import GraphQL.Request.Builder.Variable as Var
import Json.Decode
import Json.Encode
import Request.Helper as Helper
import Task exposing (Task)


type alias ColumnResponse =
    Result GraphQLClient.Error Column


type alias ColumnMutationResponse =
    Result GraphQLClient.Error (Helper.MutationResult Column)


create : { r | name : String, boardId : String } -> Maybe AuthToken -> Task GraphQLClient.Error (Helper.MutationResult Column)
create { name, boardId } maybeToken =
    createColumnMutationRoot
        |> mutationDocument
        |> request { input = { name = name, boardId = boardId } }
        |> Helper.sendMutationRequest maybeToken


subscribeColumnChange : String -> Json.Encode.Value
subscribeColumnChange hashid =
    createColumnChangeSubscriptionroot
        |> queryDocument
        |> request { hashid = hashid }
        |> Helper.subscriptionPayload


subscribeColumnChangeDecoder : Json.Decode.Decoder ColumnEvent
subscribeColumnChangeDecoder =
    createColumnChangeSubscriptionroot
        |> queryDocument
        |> request { hashid = "" }
        |> Helper.subscriptionDecoder


createColumnMutationRoot : ValueSpec NonNull ObjectType (Helper.MutationResult Column) { b | input : { a | name : String, boardId : String } }
createColumnMutationRoot =
    let
        result =
            Builder.object Helper.MutationResult
                |> with (aliasAs "object" (field "column" [] (nullable Data.Column.object)))
                |> with (field "errors" [] (list Helper.errorObject))
    in
    extract
        (field "createColumn"
            [ ( "input", Arg.variable createColumnInput ) ]
            result
        )


createColumnInput : Var.Variable { b | input : { a | name : String, boardId : String } }
createColumnInput =
    Var.required "input"
        .input
        (Var.object "CreateColumnInput"
            [ Var.field "name" .name Var.string
            , Var.field "board_id" .boardId Var.string
            ]
        )


createColumnChangeSubscriptionroot : ValueSpec NonNull ObjectType ColumnEvent { a | hashid : String }
createColumnChangeSubscriptionroot =
    let
        hashid =
            Var.required "boardHashid" .hashid Var.string
    in
    extract
        (field "boardColumnEvent" [ ( "boardHashid", Arg.variable hashid ) ] Data.Column.columnEventObject)
