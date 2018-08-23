module Page.Board exposing (Model, Msg, init, initialModel, subscriptions, update, view)

import Data.Board exposing (BoardWithRelations, Hashid)
import Data.Column exposing (ColumnEvent)
import Data.Connection as Connection exposing (Connection)
import Data.Session exposing (Session)
import Dict exposing (Dict)
import Html
import Html.Styled as HtmlStyled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (on, onClick, onInput, onSubmit)
import Json.Decode as Decode exposing (Value)
import Json.Encode
import Mouse exposing (Position)
import Phoenix
import Phoenix.Channel as Channel
import Phoenix.Push as Push
import Phoenix.Socket as Socket
import Request.Board
import Request.Column
import Request.SubscriptionEvent as SubscriptionEvent
import Style
import Style.Board
import Task


type Msg
    = SubmitNewColumn
    | SetNewColumnName String
    | JoinedAbsintheControl Value
    | BoardChangeEvent Value
    | SubscribedToBoard Value
    | BoardLoaded Value
    | ReceiveNewColumnMutationResponse Request.Column.ColumnMutationResponse
    | DragColumnAt Position
    | DragColumnEnd Position
    | DragColumnStart Data.Column.Column Position


type EventType
    = ColumnChangeEvent


type alias ColumnModelForm =
    { name : String
    , boardId : String
    , errors : List String
    }


type alias DragColumn =
    { column : Data.Column.Column
    , startPosition : Position
    , currentPosition : Position
    }


type alias Model =
    { board : Maybe BoardWithRelations
    , newColumn : ColumnModelForm
    , subscriptionEventType : Dict String EventType
    , dragColumn : Maybe DragColumn
    }


type alias AbsintheSubscription =
    { subscriptionId : String
    }


initialModel : Model
initialModel =
    { board = Nothing
    , newColumn = { name = "", errors = [], boardId = "" }
    , subscriptionEventType = Dict.empty
    , dragColumn = Nothing
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
            div [ css [ Style.Board.boardWrapper ] ]
                [ div [ css [ Style.Board.boardMainContent ] ]
                    [ header [ css [ Style.Board.boardHeader ] ]
                        [ span [ css [ Style.Board.boardHeaderName ] ] [ text board.name ]
                        ]
                    , div [ css [ Style.Board.boardCanvas ] ]
                        [ div [ css [ Style.Board.columns ] ]
                            [ viewColumns board model
                            , viewNewColumn model
                            ]
                        ]
                    ]
                ]

        _ ->
            text "loading ..."


viewColumns : BoardWithRelations -> Model -> Html Msg
viewColumns board model =
    div []
        (List.indexedMap (viewColumn model.dragColumn) board.columns)


viewColumn : Maybe DragColumn -> Int -> Data.Column.Column -> Html Msg
viewColumn maybeDragingColumn idx columnModel =
    let
        maybeCurrentColumnDraggingColumn =
            maybeDragingColumn
                |> Maybe.andThen
                    (\{ column, startPosition, currentPosition } ->
                        if column == columnModel then
                            Just (DragColumn column startPosition currentPosition)

                        else
                            Nothing
                    )

        moveStyle =
            maybeCurrentColumnDraggingColumn
                |> Maybe.map
                    (\dragColumn ->
                        Style.Board.movingColumn dragColumn.startPosition dragColumn.currentPosition
                    )
                |> Maybe.withDefault Style.empty

        shouldShowTheShadow =
            case maybeDragingColumn of
                Nothing ->
                    False

                Just dragColumn ->
                    idx == (dragColumn.currentPosition.x // 272) + 1
    in
    if shouldShowTheShadow then
        span []
            [ div [ css [ Style.batch Style.Board.columnWrapper Style.Board.columnShadowWrapper ] ] []
            , viewColumnWrapper columnModel moveStyle
            ]

    else
        viewColumnWrapper columnModel moveStyle


viewColumnWrapper columnModel moveStyle =
    div [ css [ Style.batch Style.Board.columnWrapper moveStyle ] ]
        [ div [ css [ Style.Board.columnStyle ] ]
            [ div [ css [ Style.Board.columnHeaderStyle ] ]
                [ span [ css [ Style.Board.columnHeaderNameStyle ], onMouseDown (DragColumnStart columnModel) ] [ text columnModel.name ]
                ]
            , div [ css [ Style.Board.cards ] ] viewCards
            ]
        ]


onMouseDown : (Position -> msg) -> Attribute msg
onMouseDown msg =
    on "mousedown" (Decode.map msg Mouse.position)


viewCards : List (Html Msg)
viewCards =
    List.range 1 10
        |> List.map
            (\i ->
                a [ css [ Style.Board.card ] ]
                    [ div [ css [ Style.Board.cardDetails ] ]
                        [ text ("Card #" ++ toString i)
                        ]
                    ]
            )


viewNewColumn : Model -> Html Msg
viewNewColumn model =
    div []
        [ text "New column"
        , HtmlStyled.form [ onSubmit SubmitNewColumn ]
            [ input
                [ onInput SetNewColumnName
                , placeholder "name"
                , value model.newColumn.name
                ]
                []
            ]
        , button [ onClick SubmitNewColumn ] [ text "Create" ]
        ]


update : Session -> Connection mainMsg -> (Msg -> mainMsg) -> Msg -> Model -> ( Model, Cmd Msg, Connection mainMsg, Cmd mainMsg )
update session connection pageExternalMsg msg model =
    case msg of
        DragColumnStart column pos ->
            ( { model | dragColumn = Just <| DragColumn column pos pos }, Cmd.none, connection, Cmd.none )

        DragColumnAt pos ->
            ( { model | dragColumn = Maybe.map (\{ column, startPosition } -> DragColumn column startPosition pos) model.dragColumn }, Cmd.none, connection, Cmd.none )

        DragColumnEnd pos ->
            ( { model | dragColumn = Nothing }, Cmd.none, connection, Cmd.none )

        BoardLoaded value ->
            let
                newColumn =
                    model.newColumn

                updatedModel =
                    value
                        |> Decode.decodeValue Request.Board.queryGetDecoder
                        |> Result.map (\b -> { model | board = Just <| sortBoardColumns b, newColumn = { newColumn | boardId = b.id } })
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
                newColumn =
                    model.newColumn

                resetNewColumn =
                    { newColumn | name = "", errors = [] }

                cmd =
                    session.user
                        |> Maybe.map .token
                        |> Request.Column.create newColumn
                        |> Task.attempt ReceiveNewColumnMutationResponse
            in
            ( { model | newColumn = resetNewColumn }, cmd, connection, Cmd.none )

        ReceiveNewColumnMutationResponse (Ok { object, errors }) ->
            case ( model.board, object ) of
                ( Just board, Just newColumn ) ->
                    let
                        updatedBoard =
                            { board | columns = newColumn :: board.columns }
                    in
                    ( { model | board = Just <| sortBoardColumns updatedBoard }, Cmd.none, connection, Cmd.none )

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
                        let
                            updatedBoard =
                                { board | columns = columnEvent.column :: board.columns }
                        in
                        Just <| sortBoardColumns updatedBoard

                    else
                        Just board
    in
    { model | board = board }


sortBoardColumns : BoardWithRelations -> BoardWithRelations
sortBoardColumns board =
    let
        sortedColumns =
            List.sortBy .position board.columns
    in
    { board | columns = sortedColumns }


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.dragColumn of
        Nothing ->
            Sub.batch []

        Just _ ->
            Sub.batch [ Mouse.moves DragColumnAt, Mouse.ups DragColumnEnd ]
