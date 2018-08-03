module Data.AuthToken exposing (AuthToken, build)


type AuthToken
    = AuthToken String


build : String -> AuthToken
build token =
    AuthToken token
