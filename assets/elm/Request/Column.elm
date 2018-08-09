module Request.Column exposing (ColumnResponse, ColumnMutationResponse, create)

-- Data

import Data.Column exposing (Column)
import Data.AuthToken exposing (AuthToken)


-- Tools

import Request.Helper as Helper


-- External

import GraphQL.Request.Builder as Builder exposing (..)
import GraphQL.Request.Builder.Variable as Var
import GraphQL.Request.Builder.Arg as Arg
import Task exposing (Task)
import GraphQL.Client.Http as GraphQLClient


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
