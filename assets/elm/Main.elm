module Main exposing (Model(..))

import App
import Browser exposing (Document)
import Browser.Navigation as Nav
import Html
import Html.Styled as HtmlStyled exposing (..)
import Json.Decode as Decode exposing (Value)
import Page.Login as Login
import Route exposing (Route)
import Session exposing (Session)
import Url exposing (Url)
import Viewer exposing (Viewer)


type Model
    = NotFound Session
    | Redirect Session
    | Login Login.Model


init : Maybe Viewer -> Url -> Nav.Key -> ( Model, Cmd Msg )
init maybeViewer url navKey =
    changeRouteTo (Route.fromUrl url)
        (Redirect (Session.fromViewer navKey maybeViewer))



-- VIEW


view : Model -> Document Msg
view model =
    let
        viewPage toMsg config =
            let
                { title, content } =
                    config

                --Page.view (Session.viewer (toSession model)) page config
            in
            { title = title
            , body = List.map (Html.map toMsg) [ HtmlStyled.toUnstyled content ]
            }

        body2 =
            HtmlStyled.toUnstyled
                (text "Page not found")
    in
    case model of
        Login login ->
            viewPage GotLoginMsg (Login.view login)

        _ ->
            { title = "Ollerto"
            , body = [ body2 ]
            }



-- UPDATE


type Msg
    = Ignored
    | ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | GotSession Session
    | GotLoginMsg Login.Msg


toSession : Model -> Session
toSession page =
    case page of
        Redirect session ->
            session

        NotFound session ->
            session

        Login login ->
            Login.toSession login


changeRouteTo : Maybe Route -> Model -> ( Model, Cmd Msg )
changeRouteTo maybeRoute model =
    let
        session =
            toSession model
    in
    case maybeRoute of
        Nothing ->
            ( NotFound session, Cmd.none )

        Just Route.Root ->
            ( model, Route.replaceUrl (Session.navKey session) Route.Login )

        Just Route.Home ->
            case Session.viewer session of
                Nothing ->
                    ( model, Route.replaceUrl (Session.navKey session) Route.Login )

                _ ->
                    ( NotFound session, Cmd.none )

        Just Route.Login ->
            Login.init session
                |> updateWith Login GotLoginMsg model

        Just Route.Logout ->
            ( model, App.logout )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( ClickedLink urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl (Session.navKey (toSession model)) (Url.toString url) )

                Browser.External href ->
                    ( model
                    , Nav.load href
                    )

        ( ChangedUrl url, _ ) ->
            changeRouteTo (Route.fromUrl url) model

        ( GotLoginMsg subMsg, Login login ) ->
            Login.update subMsg login
                |> updateWith Login GotLoginMsg model

        ( _, _ ) ->
            let
                _ =
                    Debug.log "(msg, model)" ( msg, model )
            in
            ( model, Cmd.none )


updateWith : (subModel -> Model) -> (subMsg -> Msg) -> Model -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toModel toMsg model ( subModel, subCmd ) =
    ( toModel subModel
    , Cmd.map toMsg subCmd
    )



-- SUBSCRIPTION


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        NotFound _ ->
            Sub.none

        Redirect _ ->
            Session.changes GotSession (Session.navKey (toSession model))

        Login login ->
            Sub.map GotLoginMsg (Login.subscriptions login)



-- MAIN


main : Program Value Model Msg
main =
    App.application Viewer.decoder
        { init = init
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        , subscriptions = subscriptions
        , update = update
        , view = view
        }
