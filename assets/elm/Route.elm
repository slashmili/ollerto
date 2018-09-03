module Route exposing (Route(..), fromUrl, href, replaceUrl)

import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import Html.Styled
import Html.Styled.Attributes as StyledAttr
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, oneOf, s, string)
import Username exposing (Username)



-- ROUTING


type Route
    = Home
    | Root
    | Login
    | Logout
    | Boards Username


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Home Parser.top
        , Parser.map Login (s "login")
        , Parser.map Logout (s "logout")
        , Parser.map Boards (Username.urlParser </> s "boards")
        ]



-- PUBLIC HELPERS


href : Route -> Html.Styled.Attribute msg
href targetRoute =
    StyledAttr.href (routeToString targetRoute)


replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl key route =
    Nav.replaceUrl key (routeToString route)


fromUrl : Url -> Maybe Route
fromUrl url =
    url
        |> Parser.parse parser



-- INTERNAL


routeToString : Route -> String
routeToString page =
    let
        pieces =
            case page of
                Home ->
                    []

                Root ->
                    []

                Login ->
                    [ "login" ]

                Logout ->
                    [ "logout" ]

                Boards username ->
                    [ "boards", Username.toString username ]
    in
    "/" ++ String.join "/" pieces
