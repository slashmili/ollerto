module Style.Board exposing (..)

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