module Data.AuthToken exposing (AuthToken, build, encode, decoder)


import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)


type AuthToken
    = AuthToken String


build : String -> AuthToken
build token =
    AuthToken token

encode : AuthToken -> Value
encode (AuthToken token) =
    Encode.string token


decoder : Decoder AuthToken
decoder =
    Decode.string
        |> Decode.map AuthToken
