module Style.Login exposing (cssContent, cssInputLabel, cssLink, cssLoginFormContainer, cssPage, cssSubmitButton, cssTextInput, cssTextInputError)

import Css exposing (..)
import Css.Global as Global
import Css.Media as Media
import Html.Styled exposing (Attribute)
import Style


cssPage : Attribute msg
cssPage =
    [ Style.wideScreen [ padding2 (em 4) (em 1), fontSize (px 20) ]
    , Style.smallScreen [ padding2 (em 2) (em 1) ]
    , color (hex "4d4d4d")
    ]
        |> Css.batch
        |> Style.toCss


cssContent : Attribute msg
cssContent =
    [ maxWidth (px 430)
    , margin2 (px 0) auto
    , Global.children [ contentH1 ]
    ]
        |> Css.batch
        |> Style.toCss


contentH1 : Global.Snippet
contentH1 =
    Global.typeSelector "h1"
        [ height (pct 100)
        , color (hex "333")
        , fontSize (px 38)
        , lineHeight (px 48)
        , marginTop (px 0)
        , marginBottom (px 0)
        ]


cssLink : Attribute msg
cssLink =
    [ color (hex "298fca")
    , visited
        [ color (hex "298fca")
        ]
    ]
        |> Css.batch
        |> Style.toCss


cssLoginFormContainer : Attribute msg
cssLoginFormContainer =
    [ marginTop (em 1.2)
    ]
        |> Css.batch
        |> Style.toCss


cssInputLabel : Attribute msg
cssInputLabel =
    [ display block
    , margin3 (px 0) (px 0) (em 0.4)
    ]
        |> Css.batch
        |> Style.toCss


cssTextInput : Attribute msg
cssTextInput =
    [ backgroundColor (hex "edeff0")
    , borderRadius (px 4)
    , border3 (px 1) solid (hex "cdd2d4")
    , boxSizing borderBox
    , padding (em 0.5)
    , width (pct 100)
    , margin3 (px 0) (px 0) (em 1.2)
    , maxWidth (px 430)
    , property "font" "inherit"
    ]
        |> Css.batch
        |> Style.toCss


cssTextInputError : Attribute msg
cssTextInputError =
    [ backgroundColor (hex "fbedeb")
    , border3 (px 1) solid (hex "ec9488")
    ]
        |> Css.batch
        |> Style.toCss


cssSubmitButton : Attribute msg
cssSubmitButton =
    [ maxWidth (px 430)
    , width (pct 100)
    , borderRadius (px 3)
    , padding2 (em 0.6) (em 1.3)
    , fontWeight bold
    , cursor pointer
    ]
        |> Css.batch
        |> Style.toCss
