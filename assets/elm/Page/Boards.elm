module Page.Boards exposing (Model, Msg, init, initialModel, update, view)

-- Data
-- Request
-- Tools
-- External

import Data.Board exposing (Board)
import Data.Session exposing (Session)
import GraphQL.Client.Http exposing (Error(..))
import Html.Styled as HtmlStyled exposing (..)
import Request.Board
import Route
import Task


type Msg
    = ReceiveQueryResponse Request.Board.BoardsResponse


type alias Model =
    { boards : List Board
    , errors : List String
    }


initialModel : Model
initialModel =
    { boards = [], errors = [] }


init : Session -> Cmd Msg
init session =
    session.user
        |> Maybe.map .token
        |> Request.Board.list
        |> Task.attempt ReceiveQueryResponse


view : Session -> Model -> Html Msg
view session model =
    div []
        [ text "Create Board"
        , viewUserBoards model
        ]


viewUserBoards : Model -> Html Msg
viewUserBoards model =
    let
        ahref =
            \board -> a [ Route.styledHref (Route.Board board.hashid) ] [ text board.name ]
    in
    div []
        [ text "Your boards: "
        , viewErrors model
        , ul [] (List.map (\b -> li [] [ ahref b ]) model.boards)
        ]


viewErrors : Model -> Html Msg
viewErrors model =
    case model.errors of
        [] ->
            text ""

        _ ->
            div []
                [ text "Couldn't fetch boards: "
                , ul [] (List.map (\e -> li [] [ text e ]) model.errors)
                ]


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        ReceiveQueryResponse (Ok boards) ->
            ( { model | boards = boards }, Cmd.none )

        ReceiveQueryResponse (Err (GraphQLError grErros)) ->
            let
                errors =
                    List.map .message grErros
            in
            ( { model | errors = errors }, Cmd.none )

        _ ->
            ( model, Cmd.none )
