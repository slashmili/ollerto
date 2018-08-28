module Style.Board exposing
    ( boardCanvas
    , boardHeader
    , boardHeaderName
    , boardMainContent
    , boardWrapper
    , card
    , cardComposer
    , cardDetails
    , cardLinkComposer
    , cardTextareaComposer
    , cards
    , columnHeaderNameStyle
    , columnHeaderStyle
    , columnShadowWrapper
    , columnStyle
    , columnWrapper
    , columns
    , movingCard
    , movingColumn
    )

import Css exposing (..)


boardWrapper : Style
boardWrapper =
    Css.batch
        [ position absolute
        , left (px 0)
        , right (px 0)
        , top (px 0)
        , bottom (px 0)
        ]


boardMainContent : Style
boardMainContent =
    Css.batch
        [ height (pct 100)
        , displayFlex
        , flexDirection column
        , marginRight (px 0)
        ]


boardHeader : Style
boardHeader =
    Css.batch
        [ flex none
        , height auto
        , overflow hidden
        , position relative
        ]


boardHeaderName : Style
boardHeaderName =
    Css.batch
        [ cursor default
        , fontSize (px 18)
        , fontWeight (int 700)
        , lineHeight (px 32)
        , paddingLeft (px 4)
        , textDecoration none
        ]


boardCanvas : Style
boardCanvas =
    Css.batch
        [ flexGrow (num 1)
        , position relative
        ]


columns : Style
columns =
    Css.batch
        [ left (px 0)
        , right (px 0)
        , top (px 0)
        , bottom (px 0)
        , position absolute
        , overflowX auto
        , overflowY hidden
        , marginBottom (px 8)
        , paddingBottom (px 8)
        , whiteSpace noWrap
        , property "-webkit-user-select" "none"
        , property "-moz-user-select" "none"
        , property "-ms-user-select" "none"
        , property "user-select" "none"
        ]


columnWrapper : Style
columnWrapper =
    Css.batch
        [ width (px 272)
        , margin2 (px 0) (px 4)
        , height (pct 100)
        , display inlineBlock
        , boxSizing borderBox
        , verticalAlign top
        , whiteSpace noWrap
        , firstChild [ marginLeft (px 8) ]
        ]


columnShadowWrapper : Style
columnShadowWrapper =
    Css.batch
        [ backgroundColor (hex "c0c5ce")
        , maxHeight (px 200)
        , height (px 200)
        ]


movingColumn : { a | x : Int, y : Int } -> { b | x : Int, y : Int } -> Style
movingColumn startPosition currentPosition =
    Css.batch
        [ position absolute
        , zIndex (int 1000)
        , left (px (toFloat currentPosition.x - 50))
        , top (px (toFloat currentPosition.y - 50))
        , top (px (toFloat currentPosition.y - 50))
        , property "transform" "rotate(3deg)"
        , property "willChange" "transform"
        , cursor grabbing
        ]


columnStyle : Style
columnStyle =
    Css.batch
        [ backgroundColor (hex "e2e4e6")
        , borderRadius (px 3)
        , boxSizing borderBox
        , displayFlex
        , flexDirection column
        , maxHeight (pct 100)
        , position relative
        , whiteSpace normal
        ]


columnHeaderStyle : Style
columnHeaderStyle =
    Css.batch
        [ property "flex" "0 0 auto"
        , padding3 (px 10) (px 8) (px 8)
        , position relative
        , minHeight (px 20)
        , marginBottom (px 2)
        , cursor pointer
        ]


columnHeaderNameStyle : Style
columnHeaderNameStyle =
    Css.batch
        [ lineHeight (px 24)
        , margin3 (px 0) (px 0) (px 8)
        , fontWeight (int 700)
        ]


cards : Style
cards =
    Css.batch
        [ property "flex" "1 1 auto"
        , marginBottom (px 0)
        , overflowY auto
        , overflowX hidden
        , margin2 (px 0) (px 4)
        , padding2 (px 0) (px 4)
        , zIndex (int 1)
        , minHeight (px 0)
        ]


card : Style
card =
    Css.batch
        [ backgroundColor (hex "fff")
        , borderRadius (px 3)
        , boxShadow4 (px 0) (px 1) (px 0) (hex "ccc")
        , cursor pointer
        , display block
        , marginBottom (px 8)
        , maxWidth (px 300)
        , minHeight (px 20)
        , position relative
        , textDecoration none
        , zIndex (int 0)
        ]


cardDetails : Style
cardDetails =
    Css.batch
        [ overflow hidden
        , padding3 (px 6) (px 8) (px 2)
        , position relative
        , zIndex (int 10)
        ]


cardLinkComposer : Style
cardLinkComposer =
    Css.batch
        [ borderRadius4 (px 0) (px 0) (px 3) (px 3)
        , color (hex "8c8c8c")
        , property "fex" "0 0 auto"
        , padding2 (px 8) (px 10)
        , position relative
        , textDecoration none
        , property "-webkit-user-select" "none"
        , property "-moz-user-select" "none"
        , property "-ms-user-select" "none"
        , property "user-select" "none"
        , cursor pointer
        , hover
            [ backgroundColor (hex "cdd2d4")
            , color (hex "444")
            , textDecoration underline
            ]
        ]


cardComposer : Style
cardComposer =
    Css.batch
        [ property "padding-bottom" "8px"
        ]


cardTextareaComposer : Style
cardTextareaComposer =
    Css.batch
        [ property "background" "none"
        , property "border" "none"
        , property "box-shadow" "none"
        , property "height" "auto"
        , marginBottom (px 4)
        , maxHeight (px 162)
        , minHeight (px 54)
        , overflowY auto
        , padding (px 0)
        , width (pct 100)
        ]


movingCard : { a | x : Int, y : Int } -> { b | x : Int, y : Int } -> Style
movingCard startPosition currentPosition =
    Css.batch
        [ backgroundColor (hex "fff")
        , borderRadius (px 3)
        , boxShadow4 (px 0) (px 1) (px 0) (hex "ccc")
        , cursor pointer
        , marginBottom (px 8)
        , maxWidth (px 300)
        , minHeight (px 20)
        , textDecoration none
        , position absolute
        , zIndex (int 1000)
        , left (px (toFloat currentPosition.x))
        , top (px (toFloat currentPosition.y))
        , property "transform" "rotate(3deg)"
        , property "willChange" "transform"
        , cursor grabbing
        ]
