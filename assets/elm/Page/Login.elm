module Page.Login exposing (Form, Model, Msg, Problem(..), init, toSession, view)

import App exposing (Cred)
import Browser.Navigation as Nav
import Html.Styled as HtmlStyled exposing (..)
import Html.Styled.Attributes exposing (..)
import Route exposing (Route)
import Session exposing (Session)
import Viewer exposing (Viewer)


type alias Model =
    { session : Session
    , problems : List Problem
    , form : Form
    }


type Problem
    = InvalidEntry ValidatedField String
    | ServerError String


type alias Form =
    { email : String
    , password : String
    }


init : Session -> ( Model, Cmd msg )
init session =
    ( { session = session
      , problems = []
      , form =
            { email = ""
            , password = ""
            }
      }
    , Cmd.none
    )


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Login"
    , content = div [] [ text "login now" ]
    }



-- UPDATE


type Msg
    = SubmittedForm


type ValidatedField
    = Email
    | Password



-- EXPORT


toSession : Model -> Session
toSession model =
    model.session
