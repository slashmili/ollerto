module Request.Helper exposing (sendQueryRequest, sendMutationRequest)

-- Data

import Data.AuthToken as AuthToken exposing (AuthToken)


-- External

import Task exposing (Task)
import GraphQL.Client.Http as GraphQLClient
import GraphQL.Request.Builder exposing (..)


apiUrl =
    "/api/v1/graphql"


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


sendMutationRequest : Request Mutation a -> Task GraphQLClient.Error a
sendMutationRequest request =
    GraphQLClient.sendMutation apiUrl request
