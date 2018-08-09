module Request.Board exposing (list, get, BoardsResponse, BoardResponse)

-- Data

import Data.Board exposing (Board, BoardWithRelations, Hashid)
import Data.Column
import Data.AuthToken exposing (AuthToken)


-- Tools

import Request.Helper as Helper


-- External

import GraphQL.Request.Builder as Builder exposing (..)
import GraphQL.Request.Builder.Variable as Var
import GraphQL.Request.Builder.Arg as Arg
import Task exposing (Task)
import GraphQL.Client.Http as GraphQLClient


type alias BoardsResponse =
    Result GraphQLClient.Error (List Board)


type alias BoardResponse =
    Result GraphQLClient.Error BoardWithRelations


get : Hashid -> Maybe AuthToken -> Task GraphQLClient.Error BoardWithRelations
get hashid maybeToken =
    boardQueryroot
        |> queryDocument
        |> request { hashid = Data.Board.hashidToString hashid }
        |> Helper.sendQueryRequest maybeToken


list : Maybe AuthToken -> Task GraphQLClient.Error (List Board)
list maybeToken =
    boardsQueryroot
        |> queryDocument
        |> request {}
        |> Helper.sendQueryRequest maybeToken


boardQueryroot : ValueSpec NonNull ObjectType BoardWithRelations { a | hashid : String }
boardQueryroot =
    let
        hashid =
            Var.required "hashid" .hashid Var.string
    in
        extract
            (field "board" [ ( "hashid", Arg.variable hashid ) ] Data.Board.objectWithRelation)


boardsQueryroot : ValueSpec NonNull ObjectType (List Board) vars
boardsQueryroot =
    extract
        (field "boards" [] (Builder.list Data.Board.object))
