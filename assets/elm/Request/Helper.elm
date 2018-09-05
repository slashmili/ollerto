module Request.Helper
    exposing
        ( ErrorResult
        , MutationResult
        , errorObject
        , queryDecoder
        , queryPayload
        , sendMutationRequest
        , sendQueryRequest
        , subscriptionDecoder
        , subscriptionPayload
        )

-- Data
-- External

import Data.AuthToken as AuthToken exposing (AuthToken)
import GraphQL.Client.Http as GraphQLClient
import GraphQL.Request.Builder exposing (..)
import Json.Decode
import Json.Encode
import Regex exposing (HowMany(..))
import Task exposing (Task)


apiUrl =
    "/api/v1/graphql"


type alias ErrorResult =
    { message : String, key : String }


type alias MutationResult object =
    { object : Maybe object, errors : List ErrorResult }


errorObject =
    object ErrorResult
        |> with (field "key" [] string)
        |> with (field "message" [] string)


sendQueryRequest : Maybe AuthToken -> Request Query a -> Task GraphQLClient.Error a
sendQueryRequest maybeToken request =
    case maybeToken of
        Just token ->
            let
                requestOptions =
                    { method = "POST"
                    , headers = [ AuthToken.toHeader token ]
                    , url = apiUrl
                    , timeout = Nothing
                    , withCredentials = False
                    }
            in
            GraphQLClient.customSendQuery requestOptions request

        Nothing ->
            GraphQLClient.sendQuery apiUrl request


sendMutationRequest : Maybe AuthToken -> Request Mutation a -> Task GraphQLClient.Error a
sendMutationRequest maybeToken request =
    case maybeToken of
        Just token ->
            let
                requestOptions =
                    { method = "POST"
                    , headers = [ AuthToken.toHeader token ]
                    , url = apiUrl
                    , timeout = Nothing
                    , withCredentials = False
                    }
            in
            GraphQLClient.customSendMutation requestOptions request

        Nothing ->
            GraphQLClient.sendMutation apiUrl request


subscriptionPayload : Request Query a -> Json.Encode.Value
subscriptionPayload request =
    let
        documentValue =
            request
                |> requestBody
                |> Regex.replace (AtMost 1) (Regex.regex "query") (\_ -> "subscription")
                |> Json.Encode.string

        extraParams =
            request
                |> jsonVariableValues
                |> Maybe.map (\obj -> [ ( "variables", obj ) ])
                |> Maybe.withDefault []
    in
    Json.Encode.object ([ ( "query", documentValue ) ] ++ extraParams)


subscriptionDecoder : Request Query a -> Json.Decode.Decoder a
subscriptionDecoder request =
    Json.Decode.field "data" (responseDataDecoder request)


queryPayload : Request Query a -> Json.Encode.Value
queryPayload request =
    let
        documentValue =
            request
                |> requestBody
                |> Json.Encode.string

        extraParams =
            request
                |> jsonVariableValues
                |> Maybe.map (\obj -> [ ( "variables", obj ) ])
                |> Maybe.withDefault []
    in
    Json.Encode.object ([ ( "query", documentValue ) ] ++ extraParams)


queryDecoder : Request Query a -> Json.Decode.Decoder a
queryDecoder request =
    Json.Decode.field "data" (responseDataDecoder request)
