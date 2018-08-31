port module App exposing (Cred, application, credHeader, decode, logout, onStoreChange, storageDecoder, storeCache, username, viewerChanges)

import Browser
import Browser.Navigation as Nav
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline exposing (optional, required)
import Url exposing (Url)
import Username exposing (Username)


type Cred
    = Cred Username String


username : Cred -> Username
username (Cred val _) =
    val


credHeader : Cred -> Http.Header
credHeader (Cred _ str) =
    Http.header "authorization" ("Bearer " ++ str)


decode : Decode.Decoder (Cred -> viewer) -> Decode.Value -> Result Decode.Error viewer
decode decoder value =
    Decode.decodeValue Decode.string value
        |> Result.andThen (\str -> Decode.decodeString (Decode.field "user" (decoderFromCred decoder)) str)


port onStoreChange : (Decode.Value -> msg) -> Sub msg


viewerChanges : (Maybe viewer -> msg) -> Decode.Decoder (Cred -> viewer) -> Sub msg
viewerChanges toMsg decoder =
    onStoreChange (\value -> toMsg (decodeFromChange decoder value))


decodeFromChange : Decode.Decoder (Cred -> viewer) -> Decode.Value -> Maybe viewer
decodeFromChange viewerDecoder val =
    Decode.decodeValue (storageDecoder viewerDecoder) val
        |> Result.toMaybe


logout : Cmd msg
logout =
    storeCache Nothing


decoderFromCred : Decode.Decoder (Cred -> a) -> Decode.Decoder a
decoderFromCred decoder =
    Decode.map2 (\fromCred cred -> fromCred cred)
        decoder
        credDecoder


credDecoder : Decode.Decoder Cred
credDecoder =
    Decode.succeed Cred
        |> required "username" Username.decoder
        |> required "token" Decode.string


port storeCache : Maybe Decode.Value -> Cmd msg


application :
    Decode.Decoder (Cred -> viewer)
    ->
        { init : Maybe viewer -> Url -> Nav.Key -> ( model, Cmd msg )
        , onUrlChange : Url -> msg
        , onUrlRequest : Browser.UrlRequest -> msg
        , subscriptions : model -> Sub msg
        , update : msg -> model -> ( model, Cmd msg )
        , view : model -> Browser.Document msg
        }
    -> Program Decode.Value model msg
application viewerDecoder config =
    let
        init flags url navKey =
            let
                maybeViewer =
                    Decode.decodeValue Decode.string flags
                        |> Result.andThen (Decode.decodeString (storageDecoder viewerDecoder))
                        |> Result.toMaybe
            in
            config.init maybeViewer url navKey
    in
    Browser.application
        { init = init
        , onUrlChange = config.onUrlChange
        , onUrlRequest = config.onUrlRequest
        , subscriptions = config.subscriptions
        , update = config.update
        , view = config.view
        }


storageDecoder : Decode.Decoder (Cred -> viewer) -> Decode.Decoder viewer
storageDecoder viewerDecoder =
    Decode.field "user" (decoderFromCred viewerDecoder)
