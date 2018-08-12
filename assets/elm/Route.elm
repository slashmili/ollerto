module Route exposing (Route(..), fromLocation, href, modifyUrl)

-- Data
-- External

import Data.Board as Board exposing (Board)
import Data.User as User exposing (Username)
import Html exposing (Attribute)
import Html.Attributes as Attr
import Navigation exposing (Location)
import UrlParser as Url exposing ((</>), Parser, oneOf, parseHash, s, string)


type Route
    = Home
    | Root
    | Login
    | Boards Username
    | Board Board.Hashid


route : Parser (Route -> a) a
route =
    oneOf
        [ Url.map Home (s "")
        , Url.map Login (s "login")
        , Url.map Boards (User.usernameParser </> s "boards")
        , Url.map Board (s "b" </> Board.hashidParser)
        ]


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

                Boards username ->
                    [ User.usernameToString username, "boards" ]

                Board hashid ->
                    [ "b", Board.hashidToString hashid ]
    in
    "#/" ++ String.join "/" pieces


href : Route -> Attribute msg
href route =
    Attr.href (routeToString route)


modifyUrl : Route -> Cmd msg
modifyUrl =
    routeToString >> Navigation.modifyUrl


fromLocation : Location -> Maybe Route
fromLocation location =
    if String.isEmpty location.hash then
        Just Root

    else
        parseHash route location
