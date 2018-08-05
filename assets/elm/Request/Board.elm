module Request.Board exposing (list, BoardsResponse)

-- Data

import Data.Board exposing (Board)
import Data.AuthToken exposing (AuthToken)


-- Tools

import Request.Helper as Helper


-- External

import GraphQL.Request.Builder as Builder exposing (..)
import Task exposing (Task)
import GraphQL.Client.Http as GraphQLClient


type alias BoardsResponse =
    Result GraphQLClient.Error (List Board)


list : Maybe AuthToken -> Task GraphQLClient.Error (List Board)
list maybeToken =
    boardQueryroot
        |> queryDocument
        |> request {}
        |> Helper.sendQueryRequest maybeToken


boardQueryroot : ValueSpec NonNull ObjectType (List Board) vars
boardQueryroot =
    let
        board =
            object Board
                |> with (field "id" [] string)
                |> with (field "name" [] string)
                |> with (field "hashid" [] (map Data.Board.stringToHashid string))
    in
        extract
            (field "boards" [] (Builder.list board))
