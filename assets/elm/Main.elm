module Main exposing (..)

-- Data
-- Page
-- Tools
-- External

import Css
import Data.AuthToken as AuthToken
import Data.Connection as Connection exposing (Connection)
import Data.Session exposing (Session)
import Data.User as User exposing (User, Username)
import Html
import Html.Styled as HtmlStyled exposing (..)
import Json.Decode as Decode exposing (Value)
import Navigation exposing (Location)
import Page.Board as Board
import Page.Boards as Boards
import Page.Home as Home
import Page.Login as Login
import Phoenix
import Phoenix.Channel as Channel
import Phoenix.Message as PhxMsg
import Phoenix.Socket as Socket
import Ports
import Route exposing (Route)


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
    , connection : Connection Msg
    }


init : Value -> Location -> ( Model, Cmd Msg )
init value location =
    let
        user =
            User.fromValue value

        token =
            case user of
                Just u ->
                    AuthToken.toString u.token

                _ ->
                    ""

        ( model, routeCmd ) =
            setRoute (Route.fromLocation location)
                { pageState = Loaded Blank
                , session = { user = user }
                , connection = { socket = Socket.init ("ws://localhost:4000/socket/websocket?token=" ++ token), mapMessage = PhoenixMsg }
                }

        channel =
            Connection.absintheChannelName
                |> Channel.init

        ( socket, joinChannelCmd ) =
            Phoenix.join model.connection.mapMessage channel model.connection.socket

        connection =
            Connection.updateConnection socket model.connection
    in
    ( { model | connection = connection }, Cmd.batch [ routeCmd, joinChannelCmd ] )


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
        Just Route.Root ->
            case model.session.user of
                Nothing ->
                    ( model, Route.modifyUrl Route.Home )

                Just user ->
                    ( model, Route.modifyUrl (Route.Boards user.username) )

        Just Route.Home ->
            case model.session.user of
                Nothing ->
                    ( { model | pageState = Loaded (Home Home.initialModel) }, Cmd.none )

                Just user ->
                    ( model, Route.modifyUrl (Route.Boards user.username) )

        Just Route.Login ->
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
            let
                ( connection, cmd ) =
                    Board.init hashid model.connection (\m -> BoardMsg m)
            in
            ( { model | connection = connection, pageState = TransitioningFrom (Board Board.initialModel) }, cmd )

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
    | PhoenixMsg (PhxMsg.Msg Msg)



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
            text "404 !"

        Login subModel ->
            Login.view session subModel
                |> HtmlStyled.map LoginMsg

        Home subModel ->
            Home.view session subModel
                |> HtmlStyled.map HomeMsg

        Boards subModel ->
            Boards.view session subModel
                |> HtmlStyled.map BoardsMsg

        Board subModel ->
            Board.view session subModel
                |> HtmlStyled.map BoardMsg

        _ ->
            text ("Page " ++ toString page ++ " ...")



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
                ( pageModel, cmd ) =
                    Boards.update model.session subMsg subModel
            in
            ( { model | pageState = Loaded (Boards pageModel) }
            , Cmd.map BoardsMsg cmd
            )

        ( BoardMsg subMsg, Board subModel ) ->
            let
                ( pageModel, cmd, connection, mainPageMsg ) =
                    Board.update model.session model.connection (\m -> BoardMsg m) subMsg subModel
            in
            ( { model | pageState = Loaded (Board pageModel), connection = connection }
            , Cmd.batch [ Cmd.map BoardMsg cmd, mainPageMsg ]
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

        ( PhoenixMsg msg, _ ) ->
            let
                ( socket, cmd ) =
                    Phoenix.update PhoenixMsg msg model.connection.socket
            in
            ( { model | connection = Connection.updateConnection socket model.connection }, cmd )

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ pageSubscriptions (getPage model.pageState)
        , Sub.map SetUser sessionChange
        , Phoenix.listen PhoenixMsg model.connection.socket
        ]


pageSubscriptions : Page -> Sub Msg
pageSubscriptions page =
    case page of
        Board model ->
            model
                |> Board.subscriptions
                |> Sub.map BoardMsg

        _ ->
            Sub.none


sessionChange : Sub (Maybe User)
sessionChange =
    Ports.onSessionChange User.loadSession



-- MAIN


main : Program Value Model Msg
main =
    Navigation.programWithFlags (Route.fromLocation >> SetRoute)
        { init = init
        , view = view >> HtmlStyled.toUnstyled
        , update = update
        , subscriptions = subscriptions
        }
