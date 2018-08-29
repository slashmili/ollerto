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
import Html.Styled.Events exposing (keyCode, on, onClick, onInput, onSubmit)
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
    | SetNewCardTitle String
    | SubmitNewCard CardModelForm
    | KeyDownOnNewCard CardModelForm Int
    | JoinedAbsintheControl Value
    | BoardChangeEvent Value
    | SubscribedToBoard Value
    | BoardLoaded Value
    | CardsLoaded Value
    | ReceiveNewColumnMutationResponse Request.Column.ColumnMutationResponse
    | ReceiveUpdateColumnPositionMutationResponse Request.Column.ColumnMutationResponse
    | ReceiveNewCardMutationResponse Request.Card.CardMutationResponse
    | DraggingColumnAt Position
    | DraggingColumnEnd Position
    | DraggingColumnStart Data.Column.Column Position
    | DraggingCardAt Position
    | DraggingCardEnd Position
    | DraggingCardStart Card Position


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


type alias DraggingColumn =
    { column : Data.Column.Column
    , startPosition : Position
    , currentPosition : Position
    }


type alias DraggingCard =
    { card : Card
    , startPosition : Position
    , currentPosition : Position
    }


type alias Model =
    { board : Maybe Board
    , columns : List Data.Column.Column
    , cards : Status (Dict String (List Card))
    , newColumn : ColumnModelForm
    , subscriptionEventType : Dict String EventType
    , draggingColumn : Maybe DraggingColumn
    , draggingCard : Maybe DraggingCard
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
    , draggingColumn = Nothing
    , draggingCard = Nothing
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
                , case model.draggingCard of
                    Just draggingCard ->
                        viewCardA (Style.Board.movingCard draggingCard.startPosition draggingCard.currentPosition) draggingCard.card

                    _ ->
                        span [] []
                ]

        _ ->
            text "loading ..."


viewColumns : Board -> Model -> Html Msg
viewColumns board model =
    div []
        (List.indexedMap (viewColumn model.draggingColumn (List.length model.columns) model) model.columns
            ++ [ viewNewColumn model ]
        )


viewColumn : Maybe DraggingColumn -> Int -> Model -> Int -> Data.Column.Column -> Html Msg
viewColumn maybeDraggingColumn maxLength model idx columnModel =
    let
        isDraggingFromLeft =
            \draggingItem item -> draggingItem.position < item.position

        isLastColumnView =
            (idx + 1) == maxLength

        currentPositionColumn =
            \width position -> position.x // width

        cursorIsPointingThisColumn =
            \width position ->
                let
                    currentPos =
                        currentPositionColumn width position
                in
                -- If a column is dragged further than the last column, keep the shadow style in the leftest column
                if isLastColumnView && currentPos >= maxLength then
                    True

                else
                    idx == currentPos
    in
    case maybeDraggingColumn of
        Nothing ->
            case model.draggingCard of
                Just draggingCard ->
                    viewColumnWrapper columnModel Style.empty (cursorIsPointingThisColumn 272 draggingCard.currentPosition) model

                Nothing ->
                    viewColumnWrapper columnModel Style.empty False model

        Just draggingColumn ->
            let
                movingStyle =
                    if draggingColumn.column == columnModel then
                        Style.Board.movingColumn draggingColumn.startPosition draggingColumn.currentPosition

                    else
                        Style.empty

                shadowDiv =
                    if cursorIsPointingThisColumn 272 draggingColumn.currentPosition then
                        [ div [ css [ Style.batch Style.Board.columnWrapper Style.Board.columnShadowWrapper ] ] [] ]

                    else
                        []

                divs =
                    shadowDiv ++ [ viewColumnWrapper columnModel movingStyle False model ]
            in
            -- if a column is dragged from left, put the shadow on the right of columns
            if isDraggingFromLeft draggingColumn.column columnModel then
                span [] (List.reverse divs)

            else
                span [] divs


viewColumnWrapper columnModel movingStyle cursorIsPointingThisColumn model =
    div [ css [ Style.batch Style.Board.columnWrapper movingStyle ] ]
        [ div [ css [ Style.Board.columnStyle ] ]
            [ div [ css [ Style.Board.columnHeaderStyle ] ]
                [ span [ css [ Style.Board.columnHeaderNameStyle ], onMouseDown (DraggingColumnStart columnModel) ] [ text columnModel.name ]
                ]
            , div [ css [ Style.Board.cards ] ] (maybeViewCards columnModel cursorIsPointingThisColumn model.cards model)
            , viewNewCard columnModel model
            ]
        ]


onMouseDown : (Position -> msg) -> Attribute msg
onMouseDown msg =
    on "mousedown" (Decode.map msg Mouse.position)


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown msg =
    on "keydown" (Decode.map msg keyCode)


maybeViewCards : Data.Column.Column -> Bool -> Status (Dict String (List Card)) -> Model -> List (Html Msg)
maybeViewCards column cursorIsPointingThisColumn cardsDictStatus model =
    case cardsDictStatus of
        Loaded cardsDict ->
            viewCards column cardsDict cursorIsPointingThisColumn model

        _ ->
            []


viewCards : Data.Column.Column -> Dict String (List Card) -> Bool -> Model -> List (Html Msg)
viewCards column cardsDict cursorIsPointingThisColumn model =
    case Dict.get column.id cardsDict of
        Just cards ->
            let
                cardsCount =
                    List.length cards
            in
            List.indexedMap (viewCard model.draggingCard cursorIsPointingThisColumn cardsCount) cards

        Nothing ->
            []


viewCard : Maybe DraggingCard -> Bool -> Int -> Int -> Card -> Html Msg
viewCard maybeDraggingCard cursorIsPointingThisColumn maxLength idx card =
    case ( maybeDraggingCard, cursorIsPointingThisColumn ) of
        ( Just draggingCard, True ) ->
            maybeViewCardShadow draggingCard maxLength idx card

        _ ->
            viewCardA Style.Board.card card


maybeViewCardShadow draggingCard maxLength idx card =
    let
        maxHeight =
            30

        isLastCardView =
            (idx + 1) == maxLength

        currentPositionCard =
            \height position -> (position.y - 86) // height

        cursorIsPointingHere =
            \height position ->
                let
                    currentPos =
                        currentPositionCard height position
                in
                (idx - 1) == currentPos

        isDraggingCardIsOutOfColumn =
            isLastCardView && currentPositionCard maxHeight draggingCard.currentPosition >= maxLength - 1

        isCursorIsPointingHere =
            cursorIsPointingHere maxHeight draggingCard.currentPosition

        shadowDiv =
            [ div [ css [ Style.batch Style.Board.cardDetails Style.Board.cardShadow ] ] [] ]
    in
    if draggingCard.card == card then
        text ""

    else if isDraggingCardIsOutOfColumn then
        span [] ([ viewCardA Style.Board.card card ] ++ shadowDiv)

    else if isCursorIsPointingHere then
        span [] (shadowDiv ++ [ viewCardA Style.Board.card card ])

    else
        span [] [ viewCardA Style.Board.card card ]


viewCardA cssList card =
    a
        [ css [ cssList ]
        , onMouseDown (DraggingCardStart card)
        ]
        [ div [ css [ Style.Board.cardDetails ] ]
            [ text card.title
            ]
        ]


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
                                , onInput SetNewCardTitle
                                , onKeyDown (KeyDownOnNewCard newColumn)
                                ]
                                []
                            , div []
                                [ button [ onClick (SubmitNewCard newColumn) ] [ text "Add Card" ]
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
        DraggingCardStart card pos ->
            ( { model | draggingCard = Just <| DraggingCard card pos pos }
            , Cmd.none
            , connection
            , Cmd.none
            )

        DraggingCardEnd droppedPosition ->
            ( { model | draggingCard = Nothing }
            , Cmd.none
            , connection
            , Cmd.none
            )

        DraggingCardAt pos ->
            ( { model | draggingCard = Maybe.map (\{ card, startPosition } -> DraggingCard card startPosition pos) model.draggingCard }
            , Cmd.none
            , connection
            , Cmd.none
            )

        DraggingColumnStart column pos ->
            ( { model | draggingColumn = Just <| DraggingColumn column pos pos }, Cmd.none, connection, Cmd.none )

        DraggingColumnAt pos ->
            ( { model | draggingColumn = Maybe.map (\{ column, startPosition } -> DraggingColumn column startPosition pos) model.draggingColumn }, Cmd.none, connection, Cmd.none )

        DraggingColumnEnd droppedPosition ->
            case ( model.board, model.draggingColumn ) of
                ( Just board, Just draggingColumn ) ->
                    let
                        boardId =
                            model.board |> Maybe.map .id |> Maybe.withDefault ""

                        ( cmd, maybeUpdatedColumn ) =
                            case calculateDropPosition droppedPosition draggingColumn model of
                                Just newPosition ->
                                    let
                                        column =
                                            draggingColumn.column

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
                            ( { model | draggingColumn = Nothing, columns = columns }, cmd, connection, Cmd.none )

                        Nothing ->
                            ( { model | draggingColumn = Nothing }, Cmd.none, connection, Cmd.none )

                _ ->
                    ( { model | draggingColumn = Nothing }, Cmd.none, connection, Cmd.none )

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
                                |> sortItemsByPosition
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
                                |> sortItemsByPosition
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

        SetNewCardTitle title ->
            ( { model | newCard = model.newCard |> Maybe.map (\f -> { f | title = title }) }, Cmd.none, connection, Cmd.none )

        KeyDownOnNewCard newCard pressedKey ->
            if pressedKey == 13 then
                ( { model | newCard = Nothing }, createNewCardCommand session newCard, connection, Cmd.none )

            else
                ( model, Cmd.none, connection, Cmd.none )

        SubmitNewCard newCard ->
            ( { model | newCard = Nothing }, createNewCardCommand session newCard, connection, Cmd.none )

        ReceiveNewCardMutationResponse (Ok { object, errors }) ->
            case ( model.cards, object ) of
                ( Loaded cards, Just newCard ) ->
                    ( { model | cards = Loaded <| insertCardInColumnDict newCard cards }, Cmd.none, connection, Cmd.none )

                ( _, _ ) ->
                    ( model, Cmd.none, connection, Cmd.none )

        _ ->
            let
                _ =
                    Debug.log "msg" msg
            in
            ( model, Cmd.none, connection, Cmd.none )


createNewCardCommand session newCard =
    session.user
        |> Maybe.map .token
        |> Request.Card.create { title = newCard.title, columnId = newCard.column.id }
        |> Task.attempt ReceiveNewCardMutationResponse


calculateDropPosition droppedPosition draggingColumn model =
    let
        columnIndex =
            droppedPosition.x // 272

        isDraggingFromLeft =
            draggingColumn.startPosition.x < droppedPosition.x

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
            if oneBefore.id == draggingColumn.column.id then
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
            if oneAfter.id == draggingColumn.column.id then
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
                { model | columns = sortItemsByPosition <| columnEvent.column :: model.columns }

            else
                model

        "updated" ->
            { model | columns = sortItemsByPosition <| updateColumnIfAny columnEvent.column model.columns }

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


sortItemsByPosition : List { a | position : Float } -> List { a | position : Float }
sortItemsByPosition items =
    List.sortBy .position items


dictGetWithDefault : List a -> comparable -> Dict comparable (List a) -> List a
dictGetWithDefault defaultValue targetKey dict =
    dict
        |> Dict.get targetKey
        |> Maybe.map (\list -> list)
        |> Maybe.withDefault defaultValue


insertCardInColumnDict : Card -> Dict String (List Card) -> Dict String (List Card)
insertCardInColumnDict card columnsDict =
    let
        currentCards =
            columnsDict
                |> dictGetWithDefault [] card.columnId
                |> sortItemsByPosition
    in
    Dict.insert card.columnId (sortItemsByPosition <| card :: currentCards) columnsDict


foldByColumnId : List Card -> Dict String (List Card)
foldByColumnId cards =
    List.foldr insertCardInColumnDict Dict.empty cards


subscriptions : Model -> Sub Msg
subscriptions model =
    case ( model.draggingColumn, model.draggingCard ) of
        ( Just _, _ ) ->
            Sub.batch [ Mouse.moves DraggingColumnAt, Mouse.ups DraggingColumnEnd ]

        ( _, Just _ ) ->
            Sub.batch [ Mouse.moves DraggingCardAt, Mouse.ups DraggingCardEnd ]

        _ ->
            Sub.batch []
