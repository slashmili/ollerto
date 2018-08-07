module Page.Board exposing (Msg, Model, init, view, update, initialModel)

-- Data

import Data.Session exposing (Session)
import Data.Board exposing (Board, Hashid)
import Data.Column exposing (Column)


-- Request

import Request.Board
import Request.Column


-- External

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onSubmit, onInput)
import Task


type Msg
    = SubmitNewColumn
    | SetNewColumnName String
    | ReceiveQueryResponse Request.Board.BoardResponse
    | ReceiveNewColumnMutationResponse Request.Column.ColumnMutationResponse


type alias ColumnModelForm =
    { name : String
    , boardId : String
    , errors : List String
    }


type alias Model =
    { board : Maybe Board
    , newColumn : ColumnModelForm
    , columns : List Column
    }


initialModel : Model
initialModel =
    { board = Nothing
    , newColumn = { name = "", errors = [], boardId = "" }
    , columns = []
    }


init : Hashid -> Session -> Cmd Msg
init hashid session =
    session.user
        |> Maybe.map .token
        |> Request.Board.get hashid
        |> Task.attempt ReceiveQueryResponse


view : Session -> Model -> Html Msg
view session model =
    case model.board of
        Just board ->
            div []
                [ h1 [] [ text board.name ]
                , viewNewColumn model
                ]

        -- TODO: show lists form
        _ ->
            text "loading ..."


viewNewColumn : Model -> Html Msg
viewNewColumn model =
    div []
        [ text "New column"
        , Html.form [ onSubmit SubmitNewColumn ]
            [ input
                [ onInput SetNewColumnName
                , placeholder "name"
                ]
                []
            ]
        , button [ onClick SubmitNewColumn ] [ text "Create" ]
        ]


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        ReceiveQueryResponse (Ok board) ->
            let
                newColumn =
                    model.newColumn
            in
                ( { model | board = Just board, newColumn = { newColumn | boardId = board.id } }, Cmd.none )

        SetNewColumnName name ->
            let
                newColumn =
                    model.newColumn
            in
                ( { model | newColumn = { newColumn | name = name } }, Cmd.none )

        SubmitNewColumn ->
            let
                cmd =
                    session.user
                        |> Maybe.map .token
                        |> Request.Column.create model.newColumn
                        |> Task.attempt ReceiveNewColumnMutationResponse
            in
                ( model, cmd )

        _ ->
            let
                _ =
                    Debug.log "msg" msg
            in
                ( model, Cmd.none )
