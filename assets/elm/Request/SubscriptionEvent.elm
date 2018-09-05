module Request.SubscriptionEvent exposing (..)

import Json.Decode as Decode


type alias AbsintheSubscription =
    { subscriptionId : String
    }


type alias Event a =
    { result : a }


subscriptionId : Decode.Value -> Maybe String
subscriptionId value =
    let
        decoder =
            Decode.map AbsintheSubscription
                (Decode.field "subscriptionId" Decode.string)
    in
    case Decode.decodeValue decoder value of
        Ok absintheSubscription ->
            Just absintheSubscription.subscriptionId

        _ ->
            Nothing


decodeEvent : Decode.Decoder a -> Decode.Value -> Result String a
decodeEvent eventDecoder value =
    let
        decoder =
            Decode.map Event
                (Decode.field "result" eventDecoder)
    in
    Decode.decodeValue decoder value
        |> Result.map (\e -> e.result)
