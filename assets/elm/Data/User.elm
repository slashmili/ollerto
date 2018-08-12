module Data.User exposing (User, Username, build, fromValue, loadSession, storeSession, usernameParser, usernameToString)

-- External

import Data.AuthToken as AuthToken exposing (AuthToken)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (decode, required)
import Json.Encode as Encode exposing (Value)
import Ports
import UrlParser


type alias User =
    { id : String
    , email : String
    , token : AuthToken
    , username : Username
    }


type Username
    = Username String


build : String -> String -> String -> User
build id email token =
    User id email (AuthToken.build token) (Username id)


storeSession : User -> Cmd msg
storeSession user =
    encode user
        |> Encode.encode 0
        |> Just
        |> Ports.storeSession


loadSession : Decode.Value -> Maybe User
loadSession =
    Decode.decodeValue decoder >> Result.toMaybe


fromValue : Value -> Maybe User
fromValue json =
    json
        |> Decode.decodeValue Decode.string
        |> Result.toMaybe
        |> Maybe.andThen (Decode.decodeString decoder >> Result.toMaybe)


usernameParser : UrlParser.Parser (Username -> a) a
usernameParser =
    UrlParser.custom "USERNAME" (Ok << Username)


usernameToString : Username -> String
usernameToString (Username username) =
    username


encode : User -> Value
encode user =
    Encode.object
        [ ( "email", Encode.string user.email )
        , ( "id", Encode.string user.id )
        , ( "token", AuthToken.encode user.token )
        , ( "username", encodeUsername user.username )
        ]


decoder : Decoder User
decoder =
    decode User
        |> required "id" Decode.string
        |> required "email" Decode.string
        |> required "token" AuthToken.decoder
        |> required "username" usernameDecoder


encodeUsername : Username -> Value
encodeUsername (Username username) =
    Encode.string username


usernameDecoder : Decoder Username
usernameDecoder =
    Decode.map Username Decode.string
