module Request.Board exposing (BoardResponse, BoardsResponse, get, list, queryGet, queryGetDecoder)

-- Data
-- Tools
-- External

import Data.AuthToken exposing (AuthToken)
import Data.Board exposing (Board, BoardWithRelations, Hashid)
import Data.Column
import GraphQL.Client.Http as GraphQLClient
import GraphQL.Request.Builder as Builder exposing (..)
import GraphQL.Request.Builder.Arg as Arg
import GraphQL.Request.Builder.Variable as Var
import Json.Decode
import Json.Encode
import Request.Helper as Helper
import Task exposing (Task)


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


queryGet : Hashid -> Json.Encode.Value
queryGet hashid =
    boardQueryroot
        |> queryDocument
        |> request { hashid = Data.Board.hashidToString hashid }
        |> Helper.queryPayload


queryGetDecoder : Json.Decode.Decoder BoardWithRelations
queryGetDecoder =
    boardQueryroot
        |> queryDocument
        |> request { hashid = "" }
        |> Helper.queryDecoder


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
