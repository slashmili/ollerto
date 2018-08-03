module Data.User exposing (User, Username, build, storeSession)

import Data.AuthToken as AuthToken exposing (AuthToken)
import Json.Encode as Encode exposing (Value)
import Ports


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

storeSession : User -> Cmd msg
storeSession user =
    encode user
        |> Encode.encode 0
        |> Just
        |> Ports.storeSession


encode : User -> Value
encode user =
    Encode.object
        [ ("email", Encode.string user.email)
        , ("id", Encode.string user.id)
        , ("token", AuthToken.encode user.token)
        , ("username", encodeUsername user.username)
        ]

encodeUsername : Username -> Value
encodeUsername (Username username) =
    Encode.string username
