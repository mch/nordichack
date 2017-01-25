module WorkoutList exposing (init, view, update, Model, Msg)

-- I think this may end up containing only the view functions and specific
-- update functions, but the Msg type should probably be moved to Common
-- or Main.

import Common exposing (..)
import Html exposing (..)
import Time exposing (Time)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Http exposing (send, request, stringBody, expectString)


type alias Model =
    { workoutList : List Workout
    }


type Msg
    = Placeholder


init : ( Model, Cmd Msg )
init =
    ( { workoutList =
            [ { title = "Basic"
              , segments =
                    [ { startTime = 0, speed = 2 }
                    , { startTime = Time.second * 120, speed = 8 }
                    ]
              }
            ]
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div [ class "workout-list" ]
        [ text "Hello world" ]
