module Page.Login exposing (Model, Msg, initialModel, update, view)

-- Data
-- Request
-- Helpers
-- External

import Data.Session exposing (Session)
import Data.User as User exposing (User)
import GraphQL.Client.Http as GraphQLClient exposing (Error(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Request.User
import Route
import Task exposing (Task)
import Util


type alias Model =
    { errors : List String
    , email : Maybe String
    , password : Maybe String
    }


initialModel : Model
initialModel =
    { errors = []
    , email = Nothing
    , password = Nothing
    }


view : Session -> Model -> Html Msg
view session model =
    div []
        [ text "Login page"
        , div [] (List.map (\e -> text e) model.errors)
        , Html.form [ onSubmit SubmitForm ]
            [ input
                [ onInput SetEmail
                , placeholder "Email"
                ]
                []
            , input
                [ onInput SetPassword
                , type_ "password"
                , placeholder "password"
                ]
                []
            ]
        , button [ onClick SubmitForm ] [ text "login now" ]
        ]


type Msg
    = SubmitForm
    | SetEmail String
    | SetPassword String
    | ReceiveQueryResponse Request.User.AuthenticateUserResponse


update : Msg -> Model -> ( Model, Cmd Msg, Maybe User )
update msg model =
    case msg of
        SetEmail email ->
            Util.triple { model | email = Just email } Cmd.none Nothing

        SetPassword password ->
            Util.triple { model | password = Just password } Cmd.none Nothing

        SubmitForm ->
            case ( model.email, model.password ) of
                ( Just email, Just password ) ->
                    let
                        cmd =
                            { email = email, password = password }
                                |> Request.User.login
                                |> Task.attempt ReceiveQueryResponse
                    in
                    Util.triple model cmd Nothing

                _ ->
                    Util.triple { model | errors = [ "email and password are mandatory" ] } Cmd.none Nothing

        ReceiveQueryResponse (Ok { user, token }) ->
            let
                userData =
                    User.build user.id user.email token
            in
            Util.triple
                model
                (Cmd.batch [ User.storeSession userData, Route.modifyUrl Route.Home ])
                (Just userData)

        ReceiveQueryResponse (Err (GraphQLError grErros)) ->
            let
                errors =
                    List.map .message grErros
            in
            Util.triple { model | errors = errors } Cmd.none Nothing

        ReceiveQueryResponse (Result.Err (HttpError _)) ->
            Util.triple { model | errors = [ "Internal error!" ] } Cmd.none Nothing
