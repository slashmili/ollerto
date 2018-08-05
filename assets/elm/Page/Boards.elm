module Page.Boards exposing (Msg, Model, view, update, initialModel, init)

-- Data

import Data.Session exposing (Session)
import Data.Board exposing (Board)


-- Request

import Request.Board


-- Tools

import Route


-- External

import Html.Events exposing (onClick, onSubmit, onInput)
import Html exposing (..)
import Html.Attributes exposing (..)
import Task exposing (Task)
import GraphQL.Client.Http as GraphQLClient


type Msg
    = NoOp
    | ReceiveQueryResponse Request.Board.BoardsResponse


type alias Model =
    { boards : List Board
    }


initialModel =
    { boards = [] }


init : Session -> Cmd Msg
init session =
    session.user
        |> Maybe.map .token
        |> Request.Board.list
        |> Task.attempt ReceiveQueryResponse


view : Session -> Model -> Html Msg
view session model =
    div []
        [ text "Create Board"
        , (viewUserBoards model)
        ]


viewUserBoards : Model -> Html Msg
viewUserBoards model =
    let
        ahref =
            (\board -> a [ Route.href (Route.Board board.hashid) ] [ text board.name ])
    in
        div []
            [ text "Your boards: "
            , ul [] (List.map (\b -> li [] [ (ahref b) ]) model.boards)
            ]


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        ReceiveQueryResponse (Ok boards) ->
            ( { model | boards = boards }, Cmd.none )

        _ ->
            ( model, Cmd.none )
