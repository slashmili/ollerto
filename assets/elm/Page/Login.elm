module Page.Login exposing (Form, Model, Msg, Problem(..), init, subscriptions, toSession, update, view)

import Api.Mutation as Mutation
import Api.Object.AuthenticateUserResult as AuthenticateUserResult
import Api.Object.User
import Api.Scalar
import App exposing (Cred)
import Browser.Navigation as Nav
import Graphql.Http
import Graphql.Operation exposing (RootMutation)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, with)
import Html.Styled as HtmlStyled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (onInput, onSubmit)
import Route exposing (Route)
import Session exposing (Session)
import Style
import Style.Login exposing (..)
import Username
import Viewer exposing (Viewer)


type alias Model =
    { session : Session
    , problems : List Problem
    , form : Form
    }


type alias Form =
    { email : String
    , password : String
    }


init : Session -> ( Model, Cmd msg )
init session =
    ( { session = session
      , problems = []
      , form =
            { email = ""
            , password = ""
            }
      }
    , Cmd.none
    )


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Login"
    , content =
        div
            [ cssPage ]
            [ div [ cssContent ]
                [ h1 [] [ text "Log in to Ollerto" ]
                , span [ css [ Style.quiet ] ]
                    [ text "or "
                    , a [ cssLink, Route.href Route.Login ] [ text "create an account" ]
                    ]
                , div [ cssLoginFormContainer ]
                    [ div [] (List.map viewProblem model.problems)
                    , viewForm model.problems model.form
                    ]
                ]
            ]
    }


viewProblem : Problem -> Html msg
viewProblem problem =
    let
        errorMessage =
            case problem of
                InvalidEntry k str ->
                    str

                ServerError str ->
                    str
    in
    text errorMessage


anyKeyProblem : ValidatedField -> List Problem -> Bool
anyKeyProblem expectedkey problems =
    let
        filterFuc =
            \problem ->
                case problem of
                    InvalidEntry key _ ->
                        key == expectedkey

                    _ ->
                        False
    in
    problems
        |> List.filter filterFuc
        |> List.head
        |> Maybe.map (\_ -> True)
        |> Maybe.withDefault False


viewForm : List Problem -> Form -> Html Msg
viewForm problems form =
    let
        anyEmailProblem =
            anyKeyProblem Email problems
    in
    HtmlStyled.form [ onSubmit SubmittedForm ]
        [ label [ cssInputLabel ] [ text "Email" ]
        , input
            [ cssTextInput
            , Style.onlyIf anyEmailProblem cssTextInputError
            , onInput EnteredEmail
            , value form.email
            , placeholder "Email or username"
            ]
            []
        , label [ cssInputLabel ] [ text "Password" ]
        , input
            [ cssTextInput
            , type_ "password"
            , onInput EnteredPassword
            , value form.password
            , placeholder "Password"
            ]
            []
        , button [ cssSubmitButton ] [ text "Log in" ]
        ]



-- UPDATE


type Msg
    = SubmittedForm
    | EnteredEmail String
    | EnteredPassword String
    | GotAuthResponse (Result (Graphql.Http.Error Response) Response)
    | GotSession Session


type ValidatedField
    = Email
    | Password


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SubmittedForm ->
            case validate model.form of
                Ok validateForm ->
                    ( { model | problems = [] }
                    , Graphql.Http.send GotAuthResponse (login validateForm)
                    )

                Err problems ->
                    ( { model | problems = problems }, Cmd.none )

        EnteredEmail email ->
            updateForm (\form -> { form | email = email }) model

        EnteredPassword password ->
            updateForm (\form -> { form | password = password }) model

        GotAuthResponse (Err (Graphql.Http.GraphqlError _ errors)) ->
            let
                problems =
                    List.map (\e -> InvalidEntry Email e.message) errors
            in
            ( { model | problems = problems }, Cmd.none )

        GotAuthResponse (Err (Graphql.Http.HttpError _)) ->
            ( { model | problems = [ ServerError "Can not reach remote server" ] }, Cmd.none )

        GotAuthResponse (Ok { maybeResponse }) ->
            case maybeResponse of
                Nothing ->
                    ( model, Cmd.none )

                Just response ->
                    let
                        viewer =
                            case response.user.id of
                                Api.Scalar.Id userId ->
                                    userId
                                        |> Username.create
                                        |> App.createCred response.token
                                        |> Viewer.create
                    in
                    ( model, Viewer.store viewer )

        GotSession session ->
            ( { model | session = session }
            , Route.replaceUrl (Session.navKey session) Route.Home
            )


updateForm : (Form -> Form) -> Model -> ( Model, Cmd Msg )
updateForm transform model =
    ( { model | form = transform model.form }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Session.changes GotSession (Session.navKey model.session)



-- HTTP


type alias Response =
    { maybeResponse : Maybe AuthenticateResult }


type alias AuthenticateResult =
    { token : String, user : UserResponse }


type alias UserResponse =
    { id : Api.Scalar.Id, email : String }


login : TrimmedForm -> Graphql.Http.Request Response
login (Trimmed form) =
    let
        input =
            { input = { email = form.email, password = form.password } }

        userSelection =
            Api.Object.User.selection UserResponse
                |> with Api.Object.User.id
                |> with Api.Object.User.email

        selectionSet =
            AuthenticateUserResult.selection AuthenticateResult
                |> with AuthenticateUserResult.token
                |> with (AuthenticateUserResult.user userSelection)
    in
    Mutation.selection Response
        |> with (Mutation.authenticateUser input selectionSet)
        |> App.mutation



-- FORM


type TrimmedForm
    = Trimmed Form


type Problem
    = InvalidEntry ValidatedField String
    | ServerError String


fieldsToValidate : List ValidatedField
fieldsToValidate =
    [ Email
    , Password
    ]


validate : Form -> Result (List Problem) TrimmedForm
validate form =
    let
        trimmedForm =
            trimFields form
    in
    case List.concatMap (validateField trimmedForm) fieldsToValidate of
        [] ->
            Ok trimmedForm

        problems ->
            Err problems


validateField : TrimmedForm -> ValidatedField -> List Problem
validateField (Trimmed form) field =
    List.map (InvalidEntry field) <|
        case field of
            Email ->
                if String.isEmpty form.email then
                    [ "email can't be blank." ]

                else
                    []

            Password ->
                if String.isEmpty form.password then
                    [ "password can't be blank." ]

                else
                    []


trimFields : Form -> TrimmedForm
trimFields form =
    Trimmed
        { email = String.trim form.email
        , password = String.trim form.password
        }



-- EXPORT


toSession : Model -> Session
toSession model =
    model.session
