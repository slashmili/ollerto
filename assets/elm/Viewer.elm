module Viewer exposing (Viewer(..), create, decoder, store)

import App exposing (Cred)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (custom, required)
import Json.Encode as Encode exposing (Value)


type Viewer
    = Viewer Cred


create : Cred -> Viewer
create cred =
    Viewer cred


decoder : Decoder (Cred -> Viewer)
decoder =
    Decode.succeed Viewer


store : Viewer -> Cmd msg
store (Viewer credVal) =
    App.storeCred credVal
