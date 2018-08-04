module Page.Home exposing (Model, Msg, view, initialModel)

import Html exposing (..)
import Html.Attributes exposing (..)
import Data.Session exposing (Session)
import Route exposing (Route)


type alias Model =
    {}


type Msg
    = NoOp


initialModel : Model
initialModel =
    {}


view : Session -> Model -> Html Msg
view session model =
    div []
        [ text "home page"
        , div []
            [ a [ Route.href Route.Login ] [ text "Login" ] ]
        ]
