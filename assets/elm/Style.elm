module Style exposing (onlyIf, quiet, smallScreen, toCss, wideScreen)

import Css exposing (..)
import Css.Media as Media
import Html.Attributes
import Html.Styled exposing (Attribute)
import Html.Styled.Attributes exposing (css)


quiet : Style
quiet =
    color (hex "999")


wideWidth =
    900


smallWidth =
    650


toCss : Style -> Attribute msg
toCss style =
    css [ style ]


wideScreen : List Style -> Style
wideScreen styles =
    styles
        |> screenMedia wideWidth


smallScreen : List Style -> Style
smallScreen styles =
    styles
        |> screenMedia smallWidth


screenMedia : Float -> List Style -> Style
screenMedia minWidth styles =
    Media.withMedia
        [ Media.only Media.screen [ Media.minWidth (px minWidth) ] ]
        styles


onlyIf : Bool -> Attribute msg -> Attribute msg
onlyIf condition style =
    if condition then
        style

    else
        Html.Styled.Attributes.attribute "onlyIf" "false"
