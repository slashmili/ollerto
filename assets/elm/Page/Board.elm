module Page.Board exposing (Msg, Model, init, view, update, initialModel)

-- Data

import Data.Session exposing (Session)
import Data.Board exposing (Board, Hashid)


-- Request

import Request.Board


-- External

import Html exposing (..)
import Task


type Msg
    = ReceiveQueryResponse Request.Board.BoardResponse


type alias Model =
    { board : Maybe Board
    }


initialModel : Model
initialModel =
    { board = Nothing }


init : Hashid -> Session -> Cmd Msg
init hashid session =
    session.user
        |> Maybe.map .token
        |> Request.Board.get hashid
        |> Task.attempt ReceiveQueryResponse


view : Session -> Model -> Html Msg
view session model =
    case model.board of
        Just board ->
            div []
                [ h1 [] [ text board.name ]
                ]

        _ ->
            text "loading ..."


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        ReceiveQueryResponse (Ok board) ->
            ( { model | board = Just board }, Cmd.none )

        _ ->
            ( model, Cmd.none )
