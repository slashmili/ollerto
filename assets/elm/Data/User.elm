module Data.User exposing (User, Username)
import Data.AuthToken as AuthToken exposing (AuthToken)


type alias User =
    { email : String
    , token : AuthToken
    , username : Username
    }

type Username
    = Username String
