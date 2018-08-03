module Data.User exposing (User, Username, build)

import Data.AuthToken as AuthToken exposing (AuthToken)

type alias User =
    { id: String
    , email : String
    , token : AuthToken
    , username : Username
    }

type Username
    = Username String

build: String -> String -> String -> User
build id email token =
    User id email (AuthToken.build token) (Username email)
