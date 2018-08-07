module Request.User exposing (login, AuthenticateUserResponse)

import Request.Helper as Helper


-- External

import GraphQL.Request.Builder exposing (..)
import GraphQL.Request.Builder.Variable as Var
import GraphQL.Request.Builder.Arg as Arg
import Task exposing (Task)
import GraphQL.Client.Http as GraphQLClient


type alias User =
    { id : String, email : String }


type alias AuthenticateUser =
    { user : User
    , token : String
    }


type alias AuthenticateUserResponse =
    Result GraphQLClient.Error AuthenticateUser


login : { r | email : String, password : String } -> Task GraphQLClient.Error AuthenticateUser
login { email, password } =
    authenticateMutationRoot
        |> mutationDocument
        |> request
            { input = { password = password, email = email }
            }
        |> Helper.sendMutationRequest Nothing


authenticateMutationRoot : ValueSpec NonNull ObjectType AuthenticateUser { b | input : { a | email : String, password : String } }
authenticateMutationRoot =
    let
        user =
            object User
                |> with (field "id" [] string)
                |> with (field "email" [] string)

        authUser =
            object AuthenticateUser
                |> with (field "user" [] user)
                |> with (field "token" [] string)
    in
        extract
            (field "authenticateUser"
                [ ( "input", Arg.variable authenticateUserInput ) ]
                authUser
            )


authenticateUserInput : Var.Variable { b | input : { a | email : String, password : String } }
authenticateUserInput =
    Var.required "input"
        .input
        (Var.object "AuthenticateUserInput"
            [ Var.field "email" .email Var.string
            , Var.field "password" .password Var.string
            ]
        )
