module Page.Home exposing (Model, Msg, initialModel, view)

import Data.Session exposing (Session)
import Html
import Html.Styled exposing (..)
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
            [ a [ Route.styledHref Route.Login ] [ text "Login" ] ]
        ]
