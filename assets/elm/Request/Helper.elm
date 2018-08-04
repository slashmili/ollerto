module Request.Helper exposing (sendQueryRequest, sendMutationRequest)

import Task exposing (Task)
import GraphQL.Client.Http as GraphQLClient
import GraphQL.Request.Builder exposing (..)


apiUrl =
    "/api/v1/graphql"


sendQueryRequest : Request Query a -> Task GraphQLClient.Error a
sendQueryRequest request =
    GraphQLClient.sendQuery apiUrl request


sendMutationRequest : Request Mutation a -> Task GraphQLClient.Error a
sendMutationRequest request =
    GraphQLClient.sendMutation apiUrl request
