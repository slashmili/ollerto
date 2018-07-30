module Main exposing (..)

import Json.Decode as Decode exposing (Value)
import Navigation exposing (Location)
import Html exposing (Html, div, text, program)

import Ports



-- MODEL


type alias Model =
    String


init : Value -> Location -> ( Model, Cmd Msg )
init value location=
    let
        _ = Debug.log "value" value
        _ = Debug.log "location" location
    in
    ( "Hello 2!", Cmd.none )



-- MESSAGES


type Msg
    = NoOp



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ text model ]



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- MAIN

fromLocation: Location -> Msg
fromLocation location =
    NoOp

main : Program Value Model Msg
main =
    Navigation.programWithFlags fromLocation
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
