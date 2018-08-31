module Viewer exposing (Viewer(..), decoder)

import App exposing (Cred)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (custom, required)
import Json.Encode as Encode exposing (Value)


type Viewer
    = Viewer Cred


decoder : Decoder (Cred -> Viewer)
decoder =
    Decode.succeed Viewer
