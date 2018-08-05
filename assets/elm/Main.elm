module Main exposing (..)

-- Data

import Data.User as User exposing (User, Username)
import Data.Session exposing (Session)


-- Page

import Page.Home as Home
import Page.Login as Login
import Page.Boards as Boards
import Page.Board as Board


-- Tools

import Route exposing (Route)
import Ports


-- External

import Json.Decode as Decode exposing (Value)
import Navigation exposing (Location)
import Html exposing (..)
import Task exposing (Task)


type Page
    = Blank
    | NotFound
    | Home Home.Model
    | Login Login.Model
    | Boards Boards.Model
    | Board Board.Model


type PageState
    = Loaded Page
    | TransitioningFrom Page



-- MODEL


type alias Model =
    { session : Session
    , pageState : PageState
    }


init : Value -> Location -> ( Model, Cmd Msg )
init value location =
    setRoute (Route.fromLocation location)
        { pageState = Loaded Blank
        , session = { user = User.fromValue value }
        }


getPage : PageState -> Page
getPage pageState =
    case pageState of
        Loaded page ->
            page
        TransitioningFrom page ->
            page

setRoute : Maybe Route -> Model -> ( Model, Cmd Msg )
setRoute maybeRoute model =
    case maybeRoute of
        Just (Route.Root) ->
            case model.session.user of
                Nothing ->
                    ( model, Route.modifyUrl Route.Home )

                Just user ->
                    ( model, Route.modifyUrl (Route.Boards user.username) )

        Just (Route.Home) ->
            case model.session.user of
                Nothing ->
                    ( { model | pageState = Loaded (Home Home.initialModel) }, Cmd.none )

                Just user ->
                    ( model, Route.modifyUrl (Route.Boards user.username) )

        Just (Route.Login) ->
            ( { model | pageState = Loaded (Login Login.initialModel) }, Cmd.none )

        Just (Route.Boards username) ->
            let
                cmd =
                    model.session
                    |> Boards.init
                    |> Cmd.map BoardsMsg
            in
            ( { model | pageState = TransitioningFrom (Boards Boards.initialModel) }, cmd )

        Just (Route.Board hashid) ->
            ( { model | pageState = Loaded (Board Board.initialModel) }, Cmd.none )
        _ ->
            ( model, Cmd.none )



-- MESSAGES


type Msg
    = NoOp
    | SetRoute (Maybe Route)
    | SetUser (Maybe User)
    | LoginMsg Login.Msg
    | HomeMsg Home.Msg
    | BoardsMsg Boards.Msg
    | BoardMsg Board.Msg



-- VIEW


view : Model -> Html Msg
view model =
    case model.pageState of
        Loaded page ->
            viewPage model.session False page
        TransitioningFrom page ->
            viewPage model.session True page



viewPage : Session -> Bool -> Page -> Html Msg
viewPage session isLoading page =
    case page of
        NotFound ->
            Html.text "404 !"

        Login subModel ->
            Login.view session subModel
                |> Html.map LoginMsg

        Home subModel ->
            Home.view session subModel
                |> Html.map HomeMsg

        Boards subModel ->
            Boards.view session subModel
                |> Html.map BoardsMsg

        Board subModel ->
            Board.view session subModel
                |> Html.map BoardMsg

        _ ->
            text ("Page " ++ (toString page) ++ " ...")



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    updatePage (getPage model.pageState) msg model


updatePage : Page -> Msg -> Model -> ( Model, Cmd Msg )
updatePage page msg model =
    case ( msg, page ) of
        ( SetRoute route, _ ) ->
            setRoute route model

        ( LoginMsg subMsg, Login subModel ) ->
            let
                ( pageModel, cmd, maybeUser ) =
                    Login.update subMsg subModel

                newModule =
                    case maybeUser of
                        Just user ->
                            { model | session = { user = maybeUser } }

                        Nothing ->
                            model
            in
                ( { newModule | pageState = Loaded (Login pageModel) }
                , Cmd.map LoginMsg cmd
                )

        ( BoardsMsg subMsg, Boards subModel ) ->
            let
                ( pageModel, cmd) =
                    Boards.update model.session subMsg subModel
            in
                ( { model | pageState = Loaded (Boards pageModel) }
                , Cmd.map BoardsMsg cmd
                )

        ( SetUser user, _ ) ->
            let
                session =
                    model.session

                cmd =
                    -- If we just signed out, then redirect to Home.
                    if session.user /= Nothing && user == Nothing then
                        Route.modifyUrl Route.Home
                    else
                        Cmd.none
            in
                ( { model | session = { session | user = user } }, cmd )

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map SetUser sessionChange


sessionChange : Sub (Maybe User)
sessionChange =
    Ports.onSessionChange User.loadSession



-- MAIN


main : Program Value Model Msg
main =
    Navigation.programWithFlags (Route.fromLocation >> SetRoute)
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
