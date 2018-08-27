module Page.Board exposing (Model, Msg, init, initialModel, subscriptions, update, view)

import Data.Board exposing (Board, BoardWithRelations, Hashid, boardWithRelationsToBoard)
import Data.Card exposing (Card)
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
import Request.Card
import Request.Column
import Request.SubscriptionEvent as SubscriptionEvent
import Style
import Style.Board
import Task


type Msg
    = SubmitNewColumn
    | SetNewColumnName String
    | ShowCardComposeForm Data.Column.Column
    | JoinedAbsintheControl Value
    | BoardChangeEvent Value
    | SubscribedToBoard Value
    | BoardLoaded Value
    | CardsLoaded Value
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


type alias CardModelForm =
    { title : String
    , column : Data.Column.Column
    }


type alias DragColumn =
    { column : Data.Column.Column
    , startPosition : Position
    , currentPosition : Position
    }


type alias Model =
    { board : Maybe Board
    , columns : List Data.Column.Column
    , cards : Status (Dict String (List Card))
    , newColumn : ColumnModelForm
    , subscriptionEventType : Dict String EventType
    , dragColumn : Maybe DragColumn
    , newCard : Maybe CardModelForm
    }


type alias AbsintheSubscription =
    { subscriptionId : String
    }


type Status a
    = Loading
    | LoadingSlowly
    | Loaded a
    | Failed


initialModel : Model
initialModel =
    { board = Nothing
    , columns = []
    , cards = Loading
    , newColumn = { name = "", errors = [], boardId = "" }
    , subscriptionEventType = Dict.empty
    , dragColumn = Nothing
    , newCard = Nothing
    }


init : Hashid -> Connection msg -> (Msg -> msg) -> ( Connection msg, Cmd msg )
init hashid connection pageExternalMsg =
    let
        loadBoardPayload =
            Request.Board.queryGet hashid

        loadCardsPayload =
            Request.Card.queryList hashid

        ( socket, phxCmd ) =
            ( connection.socket, Cmd.none )
                |> queryPipeLine connection (pageExternalMsg << BoardLoaded) loadBoardPayload
                |> queryPipeLine connection (pageExternalMsg << CardsLoaded) loadCardsPayload
    in
    ( Connection.updateConnection socket connection, phxCmd )


queryPipeLine : Connection msg -> (Value -> msg) -> Json.Encode.Value -> ( Socket.Socket msg, Cmd msg ) -> ( Socket.Socket msg, Cmd msg )
queryPipeLine connection jsonValueToMsg payload ( socket, cmd ) =
    let
        pushEvent =
            Push.init "doc" Connection.absintheChannelName
                |> Push.withPayload payload
                |> Push.onOk jsonValueToMsg

        ( updatedSocket, newCmd ) =
            Phoenix.push connection.mapMessage pushEvent socket
    in
    ( updatedSocket, Cmd.batch [ cmd, newCmd ] )


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


viewColumns : Board -> Model -> Html Msg
viewColumns board model =
    div []
        (List.indexedMap (viewColumn model.dragColumn (List.length model.columns) model) model.columns
            ++ [ viewNewColumn model ]
        )


viewColumn : Maybe DragColumn -> Int -> Model -> Int -> Data.Column.Column -> Html Msg
viewColumn maybeDragingColumn maxLength model idx columnModel =
    case maybeDragingColumn of
        Nothing ->
            viewColumnWrapper columnModel Style.empty model

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
                    shadowDiv ++ [ viewColumnWrapper columnModel moveingStyle model ]
            in
            -- if a column is dragged from left, put the shadow on the right of columns
            if isDraggingFromLeft then
                span [] (List.reverse divs)

            else
                span [] divs


viewColumnWrapper columnModel moveingStyle model =
    div [ css [ Style.batch Style.Board.columnWrapper moveingStyle ] ]
        [ div [ css [ Style.Board.columnStyle ] ]
            [ div [ css [ Style.Board.columnHeaderStyle ] ]
                [ span [ css [ Style.Board.columnHeaderNameStyle ], onMouseDown (DragColumnStart columnModel) ] [ text columnModel.name ]
                ]
            , div [ css [ Style.Board.cards ] ] (maybeViewCards columnModel model.cards)
            , viewNewCard columnModel model
            ]
        ]


onMouseDown : (Position -> msg) -> Attribute msg
onMouseDown msg =
    on "mousedown" (Decode.map msg Mouse.position)


maybeViewCards : Data.Column.Column -> Status (Dict String (List Card)) -> List (Html Msg)
maybeViewCards column cardsDictStatus =
    case cardsDictStatus of
        Loaded cardsDict ->
            viewCards column cardsDict

        _ ->
            []


viewCards : Data.Column.Column -> Dict String (List Card) -> List (Html Msg)
viewCards column cardsDict =
    case Dict.get column.id cardsDict of
        Just cards ->
            cards
                |> List.map
                    (\item ->
                        a [ css [ Style.Board.card ] ]
                            [ div [ css [ Style.Board.cardDetails ] ]
                                [ text item.title
                                ]
                            ]
                    )

        Nothing ->
            []


viewNewCard : Data.Column.Column -> Model -> Html Msg
viewNewCard columnModel model =
    case model.newCard of
        Just newColumn ->
            if newColumn.column == columnModel then
                div [ css [ Style.Board.cardComposer ] ]
                    [ div [ css [ Style.Board.card ] ]
                        [ div [ css [ Style.Board.cardDetails ] ]
                            [ textarea
                                [ css [ Style.Board.cardTextareaComposer ]
                                , placeholder "Enter a title for this card…"
                                ]
                                []
                            , div []
                                [ button [ onClick (ShowCardComposeForm columnModel) ] [ text "Add Card" ]
                                ]
                            ]
                        ]
                    ]

            else
                a
                    [ css [ Style.Board.cardLinkComposer ]
                    , onClick (ShowCardComposeForm columnModel)
                    ]
                    [ span [ class "icon-sm icon-add" ] []
                    , span [] [ text "Add a card" ]
                    ]

        Nothing ->
            a
                [ css [ Style.Board.cardLinkComposer ]
                , onClick (ShowCardComposeForm columnModel)
                ]
                [ span [ class "icon-sm icon-add" ] []
                , span [] [ text "Add a card" ]
                ]


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
                            case calculateDropPosition droppedPosition dragColumn model of
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
                            let
                                columns =
                                    updateColumnIfAny updatedColumn model.columns
                            in
                            ( { model | dragColumn = Nothing, columns = columns }, cmd, connection, Cmd.none )

                        Nothing ->
                            ( { model | dragColumn = Nothing }, Cmd.none, connection, Cmd.none )

                _ ->
                    ( { model | dragColumn = Nothing }, Cmd.none, connection, Cmd.none )

        BoardLoaded value ->
            let
                newColumn =
                    model.newColumn

                ( maybeBoard, columns ) =
                    value
                        |> Decode.decodeValue Request.Board.queryGetDecoder
                        |> Result.map (\b -> boardWithRelationsToBoardAndColumns b)
                        |> Result.withDefault ( Nothing, [] )

                updatedModel =
                    { model | board = maybeBoard, columns = columns }

                ( updatedConnection, externalCmd ) =
                    case updatedModel.board of
                        Just board ->
                            joinedAbsintheChannel connection pageExternalMsg board

                        _ ->
                            ( connection, Cmd.none )
            in
            ( updatedModel, Cmd.none, updatedConnection, externalCmd )

        CardsLoaded value ->
            let
                cards =
                    value
                        |> Decode.decodeValue Request.Card.queryListDecoder
                        |> Result.map (\cards -> foldByColumnId cards)
                        |> Result.withDefault Dict.empty
            in
            ( { model | cards = Loaded cards }, Cmd.none, connection, Cmd.none )

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
            case object of
                Just updatedColumn ->
                    let
                        columns =
                            model.columns
                                |> updateColumnIfAny updatedColumn
                                |> sortColumns
                    in
                    ( { model | columns = columns }, Cmd.none, connection, Cmd.none )

                Nothing ->
                    ( model, Cmd.none, connection, Cmd.none )

        ReceiveNewColumnMutationResponse (Ok { object, errors }) ->
            case ( model.board, object ) of
                ( Just board, Just newColumn ) ->
                    let
                        columns =
                            newColumn
                                :: model.columns
                                |> sortColumns
                    in
                    ( { model | columns = columns }, Cmd.none, connection, Cmd.none )

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
                                |> Result.map (\event -> updateColumnsInModelWithEvent event model)
                                |> Result.withDefault model
                    in
                    ( updatedModel, Cmd.none, connection, Cmd.none )

        ShowCardComposeForm column ->
            ( { model | newCard = Just { column = column, title = "" } }, Cmd.none, connection, Cmd.none )

        _ ->
            let
                _ =
                    Debug.log "msg" msg
            in
            ( model, Cmd.none, connection, Cmd.none )


calculateDropPosition droppedPosition dragColumn model =
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
            getAt model.columns beforeIndex

        maybeOneAfter =
            getAt model.columns afterIndex
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
                        getAt model.columns (List.length model.columns - 1)
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
                        getAt model.columns 0
                            |> Maybe.map .position
                            |> Maybe.withDefault 0.9999999
                in
                Just (firstColumnPosition - firstColumnPosition / 2)

            else
                Just (oneAfter.position - oneAfter.position / 2)


joinedAbsintheChannel : Connection msg -> (Msg -> msg) -> Board -> ( Connection msg, Cmd msg )
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


updateColumnsInModelWithEvent : ColumnEvent -> Model -> Model
updateColumnsInModelWithEvent columnEvent model =
    let
        isAlreadyThere =
            List.any (\c -> c.id == columnEvent.column.id) model.columns
    in
    case columnEvent.action of
        "created" ->
            if not isAlreadyThere then
                { model | columns = sortColumns <| columnEvent.column :: model.columns }

            else
                model

        "updated" ->
            { model | columns = sortColumns <| updateColumnIfAny columnEvent.column model.columns }

        _ ->
            model


boardWithRelationsToBoardAndColumns : BoardWithRelations -> ( Maybe Board, List Data.Column.Column )
boardWithRelationsToBoardAndColumns board =
    ( Just <| boardWithRelationsToBoard board, board.columns )


updateColumnIfAny : Data.Column.Column -> List Data.Column.Column -> List Data.Column.Column
updateColumnIfAny updatedColumn columns =
    List.map
        (\column ->
            if column.id == updatedColumn.id then
                updatedColumn

            else
                column
        )
        columns


sortColumns : List Data.Column.Column -> List Data.Column.Column
sortColumns columns =
    List.sortBy .position columns


dictGetWithDefault : List a -> comparable -> Dict comparable (List a) -> List a
dictGetWithDefault defaultValue targetKey dict =
    dict
        |> Dict.get targetKey
        |> Maybe.map (\list -> list)
        |> Maybe.withDefault defaultValue


foldByColumnId : List Card -> Dict String (List Card)
foldByColumnId cards =
    let
        toDict =
            \item dict -> Dict.insert item.columnId (item :: dictGetWithDefault [] item.columnId dict) dict
    in
    List.foldr toDict Dict.empty cards


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.dragColumn of
        Nothing ->
            Sub.batch []

        Just _ ->
            Sub.batch [ Mouse.moves DragColumnAt, Mouse.ups DragColumnEnd ]
