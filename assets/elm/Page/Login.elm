module Page.Login exposing (Msg, Model, initialModel, view, update)

-- Data

import Data.Session exposing (Session)
import Data.User as User exposing (User)
import Util


-- Request

import Request.User


-- External

import Html.Events exposing (onClick, onSubmit, onInput)
import Html exposing (..)
import Html.Attributes exposing (..)
import GraphQL.Client.Http as GraphQLClient exposing (Error(..))
import Task exposing (Task)


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

        ReceiveQueryResponse (Ok {user, token}) ->
            Util.triple model Cmd.none (Just (User.build user.id user.email token))

        ReceiveQueryResponse (Err (GraphQLError grErros)) ->
            let
                errors =
                    List.map .message grErros
            in
                Util.triple { model | errors = errors } Cmd.none Nothing

        ReceiveQueryResponse (Result.Err (HttpError _)) ->
            Util.triple { model | errors = [ "Internal error!" ] } Cmd.none Nothing
