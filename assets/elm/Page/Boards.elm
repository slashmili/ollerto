module Page.Boards exposing (Msg, Model, view, update, initialModel)

-- Data

import Data.Session exposing (Session)


-- External

import Html.Events exposing (onClick, onSubmit, onInput)
import Html exposing (..)
import Html.Attributes exposing (..)


type Msg
    = NoOp


type alias Model =
    { name : String
    }


initialModel =
    { name = "" }


view : Session -> Model -> Html Msg
view session model =
    div []
        [ text "Create Board"
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )
