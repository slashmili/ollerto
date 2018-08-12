module Request.Helper exposing (ErrorResult, MutationResult, errorObject, sendMutationRequest, sendQueryRequest)

-- Data
-- External

import Data.AuthToken as AuthToken exposing (AuthToken)
import GraphQL.Client.Http as GraphQLClient
import GraphQL.Request.Builder exposing (..)
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
