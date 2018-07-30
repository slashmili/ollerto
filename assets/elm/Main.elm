module Main exposing (..)

import Page.Home as Home
import Page.Login as Login
import Data.Session exposing (Session)
import Route exposing (Route)
import Json.Decode as Decode exposing (Value)
import Navigation exposing (Location)
import Html exposing (..)
import Ports


type Page
    = Blank
    | NotFound
    | Home Home.Model
    | Login Login.Model


type PageState
    = Loaded Page



-- MODEL


type alias Model =
    { session : Session
    , pageState : PageState
    }


init : Value -> Location -> ( Model, Cmd Msg )
init value location =
        setRoute (Route.fromLocation location)
            { pageState = Loaded Blank
            , session = { user = Nothing }
            }


setRoute : Maybe Route -> Model -> ( Model, Cmd Msg )
setRoute maybeRoute model =
    case maybeRoute of
        Just Route.Root ->
            (model, Route.modifyUrl Route.Home)

        Just (Route.Home) ->
            ( { model | pageState = Loaded (Home Home.initialModel) }, Cmd.none )

        Just (Route.Login) ->
            ( { model | pageState = Loaded (Login Login.initialModel) }, Cmd.none )


        _ ->
            ( model, Cmd.none )



-- MESSAGES


type Msg
    = NoOp
    | SetRoute (Maybe Route)
    | LoginMsg Login.Msg
    | HomeMsg Home.Msg



-- VIEW


view : Model -> Html Msg
view model =
    case model.pageState of
        Loaded page ->
            viewPage model.session page


viewPage : Session -> Page -> Html Msg
viewPage session page =
    case page of
        NotFound ->
            Html.text "404 !"

        Login subModel ->
            Login.view session subModel
                |> Html.map LoginMsg
        Home subModel ->
            Home.view session subModel
            |> Html.map HomeMsg
        _ ->
            text ("Page " ++ (toString page) ++ " ...")




-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model.pageState of
        Loaded page ->
            updatePage page msg model


updatePage : Page -> Msg -> Model -> ( Model, Cmd Msg )
updatePage page msg model =
    case ( msg, page ) of
        ( SetRoute route, _ ) ->
            setRoute route model

        ( LoginMsg subMsg, Login subModel ) ->
            let
                ( pageModel, cmd ) =
                    Login.update subMsg subModel
            in
                ( { model | pageState = Loaded (Login pageModel) }
                , Cmd.map LoginMsg cmd
                )

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- MAIN


main : Program Value Model Msg
main =
    Navigation.programWithFlags (Route.fromLocation >> SetRoute)
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
