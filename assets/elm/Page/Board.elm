module Page.Board exposing (Msg, Model, view, update, initialModel)

-- Data

import Data.Session exposing (Session)
import Data.Board exposing (Board)

-- External

import Html exposing (..)


type Msg
    = NoOp


type alias Model =
    { board : Maybe Board
    }


initialModel =
    { board = Nothing }


view : Session -> Model -> Html Msg
view session model =
    div []
        [ text "View board"
        ]

update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    ( model, Cmd.none )
