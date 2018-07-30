module Page.Login exposing (Msg, Model, initialModel, view, update)

import Data.Session exposing (Session)

import Html exposing (..)

type alias Model =
    { errors : List String
    , email : String
    , password : String
    }


initialModel : Model
initialModel =
    { errors = []
    , email = ""
    , password = ""
    }


view : Session -> Model -> Html Msg
view session model =
    div []
    [
        text "Login page"
    ]


type Msg
    = SubmitForm
    | SetEmail String
    | SetPassword String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    (model, Cmd.none)

