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
    | ReceiveUpdateColumnPositionMutationResponse Request.Column.ColumnMutationResponse
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
                            ]
                        ]
                    ]
                ]

        _ ->
            text "loading ..."


viewColumns : BoardWithRelations -> Model -> Html Msg
viewColumns board model =
    div []
        (List.indexedMap (viewColumn model.dragColumn (List.length board.columns)) board.columns
            ++ [ viewNewColumn model ]
        )


viewColumn : Maybe DragColumn -> Int -> Int -> Data.Column.Column -> Html Msg
viewColumn maybeDragingColumn maxLength idx columnModel =
    case maybeDragingColumn of
        Nothing ->
            viewColumnWrapper columnModel Style.empty

        Just dragingColumn ->
            let
                moveingStyle =
                    if dragingColumn.column == columnModel then
                        Style.Board.movingColumn dragingColumn.startPosition dragingColumn.currentPosition

                    else
                        Style.empty

                isDraggingFromLeft =
                    dragingColumn.column.position < columnModel.position

                isLastColumnView =
                    (idx + 1) == maxLength

                currentPositionColumn =
                    dragingColumn.currentPosition.x // 272

                shouldShowTheShadow =
                    -- If a column is dragged more than the last column, keep the shadow style in the leftest column
                    if isLastColumnView && currentPositionColumn >= maxLength then
                        True

                    else
                        idx == currentPositionColumn

                shadowDiv =
                    if shouldShowTheShadow then
                        [ div [ css [ Style.batch Style.Board.columnWrapper Style.Board.columnShadowWrapper ] ] [] ]

                    else
                        []

                divs =
                    shadowDiv ++ [ viewColumnWrapper columnModel moveingStyle ]
            in
            -- if a column is dragged from left, put the shadow on the right of columns
            if isDraggingFromLeft then
                span [] (List.reverse divs)

            else
                span [] divs


viewColumnWrapper columnModel moveingStyle =
    div [ css [ Style.batch Style.Board.columnWrapper moveingStyle ] ]
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
    div [ css [ Style.Board.columnWrapper ] ]
        [ div [ css [ Style.Board.columnStyle ] ]
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
        ]


update : Session -> Connection mainMsg -> (Msg -> mainMsg) -> Msg -> Model -> ( Model, Cmd Msg, Connection mainMsg, Cmd mainMsg )
update session connection pageExternalMsg msg model =
    case msg of
        DragColumnStart column pos ->
            ( { model | dragColumn = Just <| DragColumn column pos pos }, Cmd.none, connection, Cmd.none )

        DragColumnAt pos ->
            ( { model | dragColumn = Maybe.map (\{ column, startPosition } -> DragColumn column startPosition pos) model.dragColumn }, Cmd.none, connection, Cmd.none )

        DragColumnEnd droppedPosition ->
            case ( model.board, model.dragColumn ) of
                ( Just board, Just dragColumn ) ->
                    let
                        boardId =
                            model.board |> Maybe.map .id |> Maybe.withDefault ""

                        ( cmd, maybeUpdatedColumn ) =
                            case calculateDropPosition droppedPosition dragColumn board of
                                Just newPosition ->
                                    let
                                        column =
                                            dragColumn.column

                                        newColumn =
                                            { column | position = newPosition }
                                    in
                                    ( session.user
                                        |> Maybe.map .token
                                        |> Request.Column.updatePosition newColumn boardId
                                        |> Task.attempt ReceiveUpdateColumnPositionMutationResponse
                                    , Just newColumn
                                    )

                                Nothing ->
                                    ( Cmd.none, Nothing )
                    in
                    case maybeUpdatedColumn of
                        Just updatedColumn ->
                            ( { model | dragColumn = Nothing, board = Just (updateColumnsInBoard updatedColumn board) }, cmd, connection, Cmd.none )

                        Nothing ->
                            ( { model | dragColumn = Nothing }, Cmd.none, connection, Cmd.none )

                _ ->
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

        ReceiveUpdateColumnPositionMutationResponse (Ok { object, errors }) ->
            case ( model.board, object ) of
                ( Just board, Just updatedColumn ) ->
                    let
                        columns =
                            List.map
                                (\c ->
                                    if c.id == updatedColumn.id then
                                        updatedColumn

                                    else
                                        c
                                )
                                board.columns

                        updatedBoard =
                            { board | columns = columns }
                    in
                    ( { model | board = Just <| sortBoardColumns updatedBoard }, Cmd.none, connection, Cmd.none )

                _ ->
                    ( model, Cmd.none, connection, Cmd.none )

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


calculateDropPosition droppedPosition dragColumn board =
    let
        columnIndex =
            droppedPosition.x // 272

        isDraggingFromLeft =
            dragColumn.startPosition.x < droppedPosition.x

        ( beforeIndex, afterIndex ) =
            if isDraggingFromLeft then
                ( columnIndex, columnIndex + 1 )

            else
                ( columnIndex - 1, columnIndex )

        maybeOneBefore =
            getAt board.columns beforeIndex

        maybeOneAfter =
            getAt board.columns afterIndex
    in
    case ( maybeOneBefore, maybeOneAfter ) of
        ( Nothing, Nothing ) ->
            Nothing

        ( Just oneBefore, Just oneAfter ) ->
            Just (oneBefore.position + (oneAfter.position - oneBefore.position) / 2)

        ( Just oneBefore, Nothing ) ->
            if oneBefore.id == dragColumn.column.id then
                let
                    lastColumnPosition =
                        getAt board.columns (List.length board.columns - 1)
                            |> Maybe.map .position
                            |> Maybe.withDefault 1024.0
                in
                Just (lastColumnPosition + lastColumnPosition / 2)

            else
                Just (oneBefore.position + oneBefore.position / 2)

        ( Nothing, Just oneAfter ) ->
            if oneAfter.id == dragColumn.column.id then
                let
                    firstColumnPosition =
                        getAt board.columns 0
                            |> Maybe.map .position
                            |> Maybe.withDefault 0.9999999
                in
                Just (firstColumnPosition - firstColumnPosition / 2)

            else
                Just (oneAfter.position - oneAfter.position / 2)


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


{-| Returns `Just` the element at the given index in the list,
or `Nothing` if the list is not long enough.
-}
getAt : List a -> Int -> Maybe a
getAt xs idx =
    if idx < 0 then
        Nothing

    else
        List.head <| List.drop idx xs


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
                    case columnEvent.action of
                        "created" ->
                            if not isAlreadyThere then
                                let
                                    updatedBoard =
                                        { board | columns = columnEvent.column :: board.columns }
                                in
                                Just <| sortBoardColumns updatedBoard

                            else
                                Just board

                        "updated" ->
                            Just <| sortBoardColumns (updateColumnsInBoard columnEvent.column board)

                        _ ->
                            Just board
    in
    { model | board = board }


updateColumnsInBoard : Data.Column.Column -> BoardWithRelations -> BoardWithRelations
updateColumnsInBoard column board =
    let
        columns =
            List.map
                (\columnIter ->
                    if columnIter.id == column.id then
                        column

                    else
                        columnIter
                )
                board.columns
    in
    sortBoardColumns { board | columns = columns }


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
