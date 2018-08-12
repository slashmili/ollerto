module Page.Board exposing (Model, Msg, init, initialModel, update, view)

-- Data
-- Request
-- External

import Data.Board exposing (BoardWithRelations, Hashid)
import Data.Column exposing (Column)
import Data.Session exposing (Session)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Request.Board
import Request.Column
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
    { board : Maybe BoardWithRelations
    , newColumn : ColumnModelForm
    }


initialModel : Model
initialModel =
    { board = Nothing
    , newColumn = { name = "", errors = [], boardId = "" }
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
                , viewColumns model
                , viewNewColumn model
                ]

        -- TODO: show lists form
        _ ->
            text "loading ..."


viewColumns : Model -> Html Msg
viewColumns model =
    case model.board of
        Just board ->
            div []
                [ ul [] (List.map (\c -> li [] [ text c.name ]) board.columns)
                ]

        _ ->
            text ""


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

        ReceiveNewColumnMutationResponse (Ok { object, errors }) ->
            case ( model.board, object ) of
                ( Just board, Just newColumn ) ->
                    ( { model | board = Just { board | columns = board.columns ++ [ newColumn ] } }, Cmd.none )

                ( Just board, Nothing ) ->
                    -- TODO: read errors
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        _ ->
            let
                _ =
                    Debug.log "msg" msg
            in
            ( model, Cmd.none )
