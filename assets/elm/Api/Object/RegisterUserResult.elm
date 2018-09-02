-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql
module Api.Object.RegisterUserResult exposing (..)

import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Field as Field exposing (Field)
import Graphql.Internal.Builder.Object as Object
import Graphql.SelectionSet exposing (SelectionSet)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Api.Object
import Api.Interface
import Api.Union
import Api.Scalar
import Api.InputObject
import Json.Decode as Decode
import Graphql.Internal.Encode as Encode exposing (Value)



{-| Select fields to build up a SelectionSet for this object.
-}
selection : (a -> constructor) -> SelectionSet (a -> constructor) Api.Object.RegisterUserResult
selection constructor =
    Object.selection constructor
errors : SelectionSet decodesTo Api.Object.InputError -> Field (Maybe (List (Maybe decodesTo))) Api.Object.RegisterUserResult
errors object_ =
      Object.selectionField "errors" [] (object_) (identity >> Decode.nullable >> Decode.list >> Decode.nullable)


user : SelectionSet decodesTo Api.Object.User -> Field (Maybe decodesTo) Api.Object.RegisterUserResult
user object_ =
      Object.selectionField "user" [] (object_) (identity >> Decode.nullable)
