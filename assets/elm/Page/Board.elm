module Page.Board exposing (Model, Msg, init, initialModel, subscriptions, update, view)

import Data.Board exposing (BoardWithRelations, Hashid)
import Data.Column exposing (ColumnEvent)
import Data.Connection as Connection exposing (Connection)
import Data.Session exposing (Session)
import Dict exposing (Dict)
import Html
import Html.Styled as HtmlStyled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (onClick, onInput, onSubmit)
import Json.Decode as Decode exposing (Value)
import Json.Encode
import Phoenix
import Phoenix.Channel as Channel
import Phoenix.Push as Push
import Phoenix.Socket as Socket
import Request.Board
import Request.Column
import Request.SubscriptionEvent as SubscriptionEvent
import Task


type Msg
    = SubmitNewColumn
    | SetNewColumnName String
    | JoinedAbsintheControl Value
    | BoardChangeEvent Value
    | SubscribedToBoard Value
    | BoardLoaded Value
    | ReceiveNewColumnMutationResponse Request.Column.ColumnMutationResponse


type EventType
    = ColumnChangeEvent


type alias ColumnModelForm =
    { name : String
    , boardId : String
    , errors : List String
    }


type alias Model =
    { board : Maybe BoardWithRelations
    , newColumn : ColumnModelForm
    , subscriptionEventType : Dict String EventType
    }


type alias AbsintheSubscription =
    { subscriptionId : String
    }


initialModel : Model
initialModel =
    { board = Nothing
    , newColumn = { name = "", errors = [], boardId = "" }
    , subscriptionEventType = Dict.empty
    }


init : Hashid -> Connection msg -> (Msg -> msg) -> ( Connection msg, Cmd msg )
init hashid connection pageExternalMsg =
    let
        payload =
            Request.Board.queryGet hashid

        pushEvent =
            Push.init "doc" Connection.absintheChannelName
                |> Push.withPayload payload
                |> Push.onOk (pageExternalMsg << BoardLoaded)

        ( socket, phxCmd ) =
            Phoenix.push connection.mapMessage pushEvent connection.socket
    in
    ( Connection.updateConnection socket connection, phxCmd )


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
        , HtmlStyled.form [ onSubmit SubmitNewColumn ]
            [ input
                [ onInput SetNewColumnName
                , placeholder "name"
                ]
                []
            ]
        , button [ onClick SubmitNewColumn ] [ text "Create" ]
        ]


update : Session -> Connection mainMsg -> (Msg -> mainMsg) -> Msg -> Model -> ( Model, Cmd Msg, Connection mainMsg, Cmd mainMsg )
update session connection pageExternalMsg msg model =
    case msg of
        BoardLoaded value ->
            let
                newColumn =
                    model.newColumn

                updatedModel =
                    value
                        |> Decode.decodeValue Request.Board.queryGetDecoder
                        |> Result.map (\b -> { model | board = Just b, newColumn = { newColumn | boardId = b.id } })
                        |> Result.withDefault model

                ( updatedConnection, externalCmd ) =
                    case updatedModel.board of
                        Just board ->
                            joinedAbsintheChannel connection pageExternalMsg board

                        _ ->
                            ( connection, Cmd.none )
            in
            ( updatedModel, Cmd.none, updatedConnection, externalCmd )

        SetNewColumnName name ->
            let
                newColumn =
                    model.newColumn
            in
            ( { model | newColumn = { newColumn | name = name } }, Cmd.none, connection, Cmd.none )

        SubmitNewColumn ->
            let
                cmd =
                    session.user
                        |> Maybe.map .token
                        |> Request.Column.create model.newColumn
                        |> Task.attempt ReceiveNewColumnMutationResponse
            in
            ( model, cmd, connection, Cmd.none )

        ReceiveNewColumnMutationResponse (Ok { object, errors }) ->
            case ( model.board, object ) of
                ( Just board, Just newColumn ) ->
                    ( { model | board = Just { board | columns = newColumn :: board.columns } }, Cmd.none, connection, Cmd.none )

                ( Just board, Nothing ) ->
                    -- TODO: read errors
                    ( model, Cmd.none, connection, Cmd.none )

                _ ->
                    ( model, Cmd.none, connection, Cmd.none )

        SubscribedToBoard result ->
            case SubscriptionEvent.subscriptionId result of
                Just subId ->
                    let
                        subscriptionEventType =
                            Dict.insert subId ColumnChangeEvent model.subscriptionEventType

                        ( updateConnection, externalCmd ) =
                            subscribedToColumnChange connection pageExternalMsg subId
                    in
                    ( { model | subscriptionEventType = subscriptionEventType }, Cmd.none, updateConnection, externalCmd )

                Nothing ->
                    ( model, Cmd.none, connection, Cmd.none )

        BoardChangeEvent event ->
            let
                eventType =
                    event
                        |> SubscriptionEvent.subscriptionId
                        |> Maybe.andThen (\subId -> Dict.get subId model.subscriptionEventType)
            in
            case eventType of
                Nothing ->
                    ( model, Cmd.none, connection, Cmd.none )

                Just ColumnChangeEvent ->
                    let
                        updatedModel =
                            event
                                |> SubscriptionEvent.decodeEvent Request.Column.subscribeColumnChangeDecoder
                                |> Result.map (\e -> updateColumnsInModel e model)
                                |> Result.withDefault model
                    in
                    ( updatedModel, Cmd.none, connection, Cmd.none )

        _ ->
            let
                _ =
                    Debug.log "msg" msg
            in
            ( model, Cmd.none, connection, Cmd.none )


joinedAbsintheChannel : Connection msg -> (Msg -> msg) -> BoardWithRelations -> ( Connection msg, Cmd msg )
joinedAbsintheChannel connection pageExternalMsg board =
    let
        payload =
            Request.Column.subscribeColumnChange (Data.Board.hashidToString board.hashid)

        pushEvent =
            Push.init "doc" Connection.absintheChannelName
                |> Push.withPayload payload
                |> Push.onOk (pageExternalMsg << SubscribedToBoard)

        ( socket, phxCmd ) =
            Phoenix.push connection.mapMessage pushEvent connection.socket
    in
    ( Connection.updateConnection socket connection, phxCmd )


subscribedToColumnChange : Connection msg -> (Msg -> msg) -> String -> ( Connection msg, Cmd msg )
subscribedToColumnChange connection pageExternalMsg subId =
    let
        subCan =
            subId
                |> Channel.init
                |> Channel.on "subscription:data" (pageExternalMsg << BoardChangeEvent)

        ( socket, phxCmd ) =
            Phoenix.subscribe connection.mapMessage subCan connection.socket
    in
    ( Connection.updateConnection socket connection, phxCmd )


updateColumnsInModel : ColumnEvent -> Model -> Model
updateColumnsInModel columnEvent model =
    let
        board =
            case model.board of
                Nothing ->
                    Nothing

                Just board ->
                    let
                        isAlreadyThere =
                            List.any (\c -> c.id == columnEvent.column.id) board.columns
                    in
                    if not isAlreadyThere && columnEvent.action == "created" then
                        Just { board | columns = columnEvent.column :: board.columns }

                    else
                        Just board
    in
    { model | board = board }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
