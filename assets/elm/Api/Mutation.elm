-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql
module Api.Mutation exposing (..)

import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Field as Field exposing (Field)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode as Decode exposing (Decoder)
import Api.Object
import Api.Interface
import Api.Union
import Api.Scalar
import Api.InputObject
import Graphql.Internal.Builder.Object as Object
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Json.Decode as Decode exposing (Decoder)
import Graphql.Internal.Encode as Encode exposing (Value)



{-| Select fields to build up a top-level mutation. The request can be sent with
functions from `Graphql.Http`.
-}
selection : (a -> constructor) -> SelectionSet (a -> constructor) RootMutation
selection constructor =
    Object.selection constructor
type alias AuthenticateUserRequiredArguments = { input : Api.InputObject.AuthenticateUserInput }

authenticateUser : AuthenticateUserRequiredArguments -> SelectionSet decodesTo Api.Object.AuthenticateUserResult -> Field (Maybe decodesTo) RootMutation
authenticateUser requiredArgs object_ =
      Object.selectionField "authenticateUser" [ Argument.required "input" requiredArgs.input (Api.InputObject.encodeAuthenticateUserInput) ] (object_) (identity >> Decode.nullable)


type alias CreateBoardRequiredArguments = { input : Api.InputObject.CreateBoardInput }

{-| Creates board for authorized user
-}
createBoard : CreateBoardRequiredArguments -> SelectionSet decodesTo Api.Object.CreateBoardResult -> Field (Maybe decodesTo) RootMutation
createBoard requiredArgs object_ =
      Object.selectionField "createBoard" [ Argument.required "input" requiredArgs.input (Api.InputObject.encodeCreateBoardInput) ] (object_) (identity >> Decode.nullable)


type alias CreateCardRequiredArguments = { input : Api.InputObject.CreateCardInput }

{-| Creates card for authorized user
-}
createCard : CreateCardRequiredArguments -> SelectionSet decodesTo Api.Object.CreateCardResult -> Field (Maybe decodesTo) RootMutation
createCard requiredArgs object_ =
      Object.selectionField "createCard" [ Argument.required "input" requiredArgs.input (Api.InputObject.encodeCreateCardInput) ] (object_) (identity >> Decode.nullable)


type alias CreateColumnRequiredArguments = { input : Api.InputObject.CreateColumnInput }

{-| Creates column for authorized user
-}
createColumn : CreateColumnRequiredArguments -> SelectionSet decodesTo Api.Object.CreateColumnResult -> Field (Maybe decodesTo) RootMutation
createColumn requiredArgs object_ =
      Object.selectionField "createColumn" [ Argument.required "input" requiredArgs.input (Api.InputObject.encodeCreateColumnInput) ] (object_) (identity >> Decode.nullable)


type alias RegisterUserRequiredArguments = { input : Api.InputObject.RegisterUserInput }

registerUser : RegisterUserRequiredArguments -> SelectionSet decodesTo Api.Object.RegisterUserResult -> Field (Maybe decodesTo) RootMutation
registerUser requiredArgs object_ =
      Object.selectionField "registerUser" [ Argument.required "input" requiredArgs.input (Api.InputObject.encodeRegisterUserInput) ] (object_) (identity >> Decode.nullable)


type alias UpdateColumnPositionRequiredArguments = { input : Api.InputObject.UpdateColumnPositionInput }

{-| Updates column's position for authorized user
-}
updateColumnPosition : UpdateColumnPositionRequiredArguments -> SelectionSet decodesTo Api.Object.UpdateColumnResult -> Field (Maybe decodesTo) RootMutation
updateColumnPosition requiredArgs object_ =
      Object.selectionField "updateColumnPosition" [ Argument.required "input" requiredArgs.input (Api.InputObject.encodeUpdateColumnPositionInput) ] (object_) (identity >> Decode.nullable)
