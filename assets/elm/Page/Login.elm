module Page.Login exposing (Msg, Model, initialModel, view, update)

import Data.Session exposing (Session)
import Request.User
import Html.Events exposing (onClick, onSubmit, onInput)
import Html exposing (..)
import Html.Attributes exposing (..)
import GraphQL.Client.Http as GraphQLClient exposing (Error(..))
import Task exposing (Task)


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
        [ text "Login page"
        , div [] (List.map (\e -> text e) model.errors)
        , Html.form [ onSubmit SubmitForm ]
            [ input [ onInput SetEmail, placeholder "Email" ] []
            , input [ onInput SetPassword, placeholder "password" ] []
            ]
        , button [ onClick SubmitForm ] [ text "login now" ]
        ]


type Msg
    = SubmitForm
    | SetEmail String
    | SetPassword String
    | ReceiveQueryResponse Request.User.AuthenticateUserResponse


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetEmail email ->
            ( { model | email = email }, Cmd.none )

        SetPassword password ->
            ( { model | password = password }, Cmd.none )

        SubmitForm ->
            let
                cmd =
                    model
                        |> Request.User.login
                        |> Task.attempt ReceiveQueryResponse
            in
                ( model, cmd )

        ReceiveQueryResponse (Ok authenticatedUser) ->
            let
                _ =
                    Debug.log "msg" authenticatedUser
            in
                ( model, Cmd.none )

        ReceiveQueryResponse (Err (GraphQLError grErros)) ->
            let
                errors =
                    List.map .message grErros
            in
                ( { model | errors = errors }, Cmd.none )

        ReceiveQueryResponse (Result.Err (HttpError _)) ->
            ( { model | errors = [ "Internal error!" ] }, Cmd.none )
