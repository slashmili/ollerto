module Page.Board exposing (Model, Msg, init, initialModel, subscriptions, update, view)

import Data.Board exposing (BoardWithRelations, Hashid)
import Data.Column exposing (ColumnEvent)
import Data.Session exposing (Session)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Json.Decode as Decode exposing (Value)
import Json.Encode
import Phoenix
import Phoenix.Channel as Channel
import Phoenix.Message as PhxMsg
import Phoenix.Push as Push
import Phoenix.Socket as Socket
import Request.Board
import Request.Column
import Request.SubscriptionEvent as SubscriptionEvent
import Task


type Msg
    = SubmitNewColumn
    | SetNewColumnName String
    | SetSocket (Socket.Socket Msg)
    | PhoenixMsg (PhxMsg.Msg Msg)
    | JoinedAbsintheControl Value
    | BoardChangeEvent Value
    | SubscribedToBoard Value
    | ReceiveQueryResponse Request.Board.BoardResponse
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
    , phxSocket : Socket.Socket Msg
    , subscriptionEventType : Dict String EventType
    }


type alias AbsintheSubscription =
    { subscriptionId : String
    }


initialModel : Model
initialModel =
    { board = Nothing
    , newColumn = { name = "", errors = [], boardId = "" }
    , phxSocket = initSocket
    , subscriptionEventType = Dict.empty
    }


absintheChannelName =
    "__absinthe__:control"


initSocket =
    Socket.init "ws://localhost:4000/socket/websocket"


channel =
    absintheChannelName
        |> Channel.init
        |> Channel.onJoin JoinedAbsintheControl


init : Hashid -> Session -> Cmd Msg
init hashid session =
    let
        ( socket, phxCmd ) =
            Phoenix.join PhoenixMsg channel initSocket

        setSocketCmd =
            SetSocket socket
                |> Task.succeed
                |> Task.perform identity

        boardCmd =
            session.user
                |> Maybe.map .token
                |> Request.Board.get hashid
                |> Task.attempt ReceiveQueryResponse
    in
    Cmd.batch [ setSocketCmd, phxCmd, boardCmd ]


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
        SetSocket socket ->
            ( { model | phxSocket = socket }, Cmd.none )

        JoinedAbsintheControl _ ->
            case model.board of
                Just board ->
                    let
                        subscriptionDoc =
                            "subscription { boardColumnEvent: boardColumnEvent(boardHashid: \"" ++ Data.Board.hashidToString board.hashid ++ "\") {action column { id name}}}"

                        payload =
                            Request.Column.subscribeColumnChange (Data.Board.hashidToString board.hashid)

                        pushEvent =
                            Push.init "doc" absintheChannelName
                                |> Push.withPayload payload
                                |> Push.onOk SubscribedToBoard

                        ( socket, phxCmd ) =
                            Phoenix.push PhoenixMsg pushEvent model.phxSocket
                    in
                    ( { model | phxSocket = socket }, phxCmd )

                _ ->
                    ( model, Cmd.none )

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
                    ( { model | board = Just { board | columns = newColumn :: board.columns } }, Cmd.none )

                ( Just board, Nothing ) ->
                    -- TODO: read errors
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        PhoenixMsg phxMsg ->
            let
                ( phxSocket, phxCmd ) =
                    Phoenix.update PhoenixMsg phxMsg model.phxSocket
            in
            ( { model | phxSocket = phxSocket }, phxCmd )

        SubscribedToBoard result ->
            case SubscriptionEvent.subscriptionId result of
                Just subId ->
                    let
                        subCan =
                            subId
                                |> Channel.init
                                |> Channel.on "subscription:data" BoardChangeEvent

                        -- msg: BoardChangeEvent { subscriptionId = "__absinthe__:doc:17682868", result = { data = { boardColumnEvent = { column = { name = "Doing", id = "d70c7200-2d12-43a4-b6a5-7666d150a09f" }, action = "created" } } } }
                        ( phxSocket, phxCmd ) =
                            Phoenix.subscribe PhoenixMsg subCan model.phxSocket

                        subscriptionEventType =
                            Dict.insert subId ColumnChangeEvent model.subscriptionEventType
                    in
                    ( { model | phxSocket = phxSocket, subscriptionEventType = subscriptionEventType }, phxCmd )

                Nothing ->
                    ( model, Cmd.none )

        BoardChangeEvent event ->
            let
                eventType =
                    event
                        |> SubscriptionEvent.subscriptionId
                        |> Maybe.andThen (\subId -> Dict.get subId model.subscriptionEventType)
            in
            case eventType of
                Nothing ->
                    ( model, Cmd.none )

                Just ColumnChangeEvent ->
                    let
                        updatedModel =
                            event
                                |> SubscriptionEvent.decodeEvent Request.Column.subscribeColumnChangeDecoder
                                |> Result.map (\e -> updateColumnsInModel e model)
                                |> Result.withDefault model
                    in
                    ( updatedModel, Cmd.none )

        _ ->
            let
                _ =
                    Debug.log "msg" msg
            in
            ( model, Cmd.none )


updateColumnsInModel : ColumnEvent -> Model -> Model
updateColumnsInModel columnEvent model =
    let
        board =
            case model.board of
                Nothing ->
                    Nothing

                Just board ->
                    if columnEvent.action == "created" then
                        Just { board | columns = columnEvent.column :: board.columns }

                    else
                        Just board
    in
    { model | board = board }


subscriptions : Model -> Sub Msg
subscriptions model =
    Phoenix.listen PhoenixMsg model.phxSocket
