module Data.Connection exposing (Connection, absintheChannelName, updateConnection)

import Phoenix.Message as PhxMsg
import Phoenix.Socket as Socket


type alias Connection msg =
    { socket : Socket.Socket msg
    , mapMessage : PhxMsg.Msg msg -> msg
    }


updateConnection : Socket.Socket msg -> Connection msg -> Connection msg
updateConnection socket connection =
    { connection | socket = socket }


absintheChannelName : String
absintheChannelName =
    "__absinthe__:control"
