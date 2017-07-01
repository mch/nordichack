module Main exposing (..)

import Ant exposing (Model, init, view, update)
import Common exposing (..)
import ControlPanel exposing (..)
import Model exposing (DataModel, initDataModel)
import Workout exposing (..)
import Html exposing (program, Html, text, div, button)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Http exposing (send, request, stringBody, expectString)
import Time exposing (Time)


main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type Msg
    = ControlPanelMsg ControlPanelMsg
    | ChangeScreen Screen
    | StartWorkout (Maybe Workout)
    | EditWorkout WorkoutId
    | AntMsg Ant.Action


type alias Model =
    { controlPanel : ControlPanelModel
    , workoutList : WorkoutListModel
    , antModel : Ant.Model
    , currentScreen : Screen
    , dataModel : DataModel
    }


type alias Flags =
    { hostname : String
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        cpanelSubs =
            controlPanelSubscriptions model.controlPanel |> Sub.map ControlPanelMsg

        antSubs =
            Ant.subscriptions model.antModel |> Sub.map AntMsg
    in
        Sub.batch
            [ cpanelSubs
            , antSubs
              -- if model.currentScreen == AntScreen then antSubs else Sub.none
            ]


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( cpm, cpc ) =
            controlPanelInit

        ( wlm, wlc ) =
            workoutListInit

        ( antModel, antCmd ) =
            Ant.init flags.hostname
    in
        { controlPanel = cpm
        , workoutList = wlm
        , currentScreen = MainMenuScreen
        , antModel = antModel
        , dataModel = initDataModel
        }
            ! [ Cmd.map ControlPanelMsg cpc, wlc, Cmd.map AntMsg antCmd ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    -- I'm doing this wrong I'm sure; there must be a more composable
    -- and generic way of doing this.
    case msg of
        ControlPanelMsg m ->
            let
                ( cpm, cpc ) =
                    controlPanelUpdate m model.controlPanel
            in
                ( { model | controlPanel = cpm }, Cmd.map ControlPanelMsg cpc )

        ChangeScreen s ->
            ( { model | currentScreen = s }, Cmd.none )

        StartWorkout workout ->
            -- A lot of this code should be in the control panel update fn,
            -- since we are primarially messing with it's state.
            let
                cpModel =
                    model.controlPanel

                ( freshCpModel, _ ) =
                    controlPanelInit
            in
                if model.controlPanel.speed == 0 && model.controlPanel.requestedSpeed == 0 then
                    ( { model
                        | currentScreen = ControlPanelScreen
                        , controlPanel = { freshCpModel | workout = workout, nextSegment = Just 1 }
                      }
                    , Cmd.none
                    )
                else
                    ( { model
                        | currentScreen = ControlPanelScreen
                        , controlPanel = { cpModel | error = "Workout already in progress." }
                      }
                    , Cmd.none
                    )

        EditWorkout workoutId ->
            ( model, Cmd.none )

        AntMsg msg ->
            let
                ( newModel, newCmd, heartdata ) =
                    Ant.update msg model.antModel

                nextRRInterval = Maybe.map2 (,) heartdata.eventTime heartdata.rrInterval
                    |> Maybe.map List.singleton
                    |> Maybe.withDefault []

                dataModel =
                    model.dataModel

                newDataModel =
                    { dataModel
                        | heartdata = heartdata
                        , rrIntervalTimeSeries = List.append dataModel.rrIntervalTimeSeries nextRRInterval
                    }
            in
                ( { model | antModel = newModel, dataModel = newDataModel }
                , Cmd.map AntMsg newCmd
                )


view : Model -> Html Msg
view model =
    let
        backButton =
            div
                [ class "back-button"
                , onClick (ChangeScreen MainMenuScreen)
                ]
                [ text "Back" ]

        screenTitle =
            div
                [ class "screen-title" ]
                [ text "NordicHack" ]

        navbar =
            if model.currentScreen == MainMenuScreen then
                [ screenTitle ]
            else
                [ backButton, screenTitle ]

        content =
            case model.currentScreen of
                ControlPanelScreen ->
                    Html.map ControlPanelMsg (controlPanelView model.controlPanel model.dataModel)

                WorkoutListScreen ->
                    viewWorkoutListItem model.workoutList

                MainMenuScreen ->
                    viewMainMenu

                AntScreen ->
                    Html.map AntMsg (Ant.view model.antModel)
    in
        div [ class "main" ] (List.append navbar [ content ])


viewMainMenu : Html Msg
viewMainMenu =
    div [ class "mainmenu" ]
        [ div [ class "menu-item", onClick (ChangeScreen ControlPanelScreen) ] [ text "Control Panel" ]
        , div [ class "menu-item", onClick (ChangeScreen WorkoutListScreen) ] [ text "Workouts" ]
        , div [ class "menu-item" ] [ text "Run History" ]
        , div [ class "menu-item" ] [ text "Training Schedule" ]
        , div [ class "menu-item" ] [ text "Settings" ]
        , div [ class "menu-item" ] [ text "Users" ]
        , div [ class "menu-item", onClick (ChangeScreen AntScreen) ] [ text "ANT+ Devices" ]
        ]



-- Workout List...


type alias WorkoutListModel =
    { workoutList : List Workout
    }


workoutListInit : ( WorkoutListModel, Cmd Msg )
workoutListInit =
    ( { workoutList =
            [ { title = "Basic"
              , description = Nothing
              , workoutId = 0
              , segments =
                    [ { startTime = 0, speed = 4 }
                    , { startTime = Time.minute * 2, speed = 8 }
                    , { startTime = Time.minute * 28, speed = 4 }
                    , { startTime = Time.minute * 30, speed = 0 }
                    ]
              }
            , { title = "C5K Week 1"
              , workoutId = 1
              , description = Just "Brisk five-minute warmup walk. Then alternate 60 seconds of jogging and 90 seconds of walking for a total of 20 minutes."
              , segments =
                    [ { startTime = 0, speed = 4 }
                    , { startTime = Time.minute * 5, speed = 8 }
                    , { startTime = Time.minute * 5 + Time.second * 60, speed = 2 }
                    , { startTime = Time.minute * 7, speed = 0 }
                    ]
              }
            , { title = "Very Short"
              , workoutId = 2
              , description = Just "Test"
              , segments =
                    [ { startTime = 0, speed = 4 }
                    , { startTime = Time.second * 5, speed = 8 }
                    , { startTime = Time.second * 10, speed = 0 }
                    ]
              }
              -- NOTE: These workouts are for targeting a 10k time of 00:50
              -- Target race pace is 5 min/km
              -- Easy running pace is 7 km/km
              -- TODO parameterize these runs so that the paces come from the
              -- user profile
            , { title = "Week 1 - Day 2 - Easy Run"
              , workoutId = 3
              , description = Just "Build your endurance for the race"
              , segments =
                    [ { startTime = 0, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 40, speed = 0 }
                    ]
              }
            , { title = "Week 1 - Day 4 - Fartlek Run"
              , workoutId = 4
              , description = Just "Primary fitness building workout"
              , segments =
                    [ { startTime = 0, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 10, speed = paceToSpeed 5.0 }
                    , { startTime = Time.minute * 11, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 12, speed = paceToSpeed 5.0 }
                    , { startTime = Time.minute * 13, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 14, speed = paceToSpeed 5.0 }
                    , { startTime = Time.minute * 15, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 16, speed = paceToSpeed 5.0 }
                    , { startTime = Time.minute * 17, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 18, speed = paceToSpeed 5.0 }
                    , { startTime = Time.minute * 19, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 20, speed = paceToSpeed 5.0 }
                    , { startTime = Time.minute * 21, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 22, speed = paceToSpeed 5.0 }
                    , { startTime = Time.minute * 23, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 24, speed = paceToSpeed 5.0 }
                    , { startTime = Time.minute * 25, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 26, speed = paceToSpeed 5.0 }
                    , { startTime = Time.minute * 27, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 28, speed = paceToSpeed 5.0 }
                    , { startTime = Time.minute * 29, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 45, speed = 0.0 }
                    ]
              }
            , { title = "Week 1 - Day 7 - Long Run"
              , workoutId = 5
              , description = Just "Build your endurance for the race"
              , segments =
                    [ { startTime = 0, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 60, speed = 0 }
                    ]
              }
            , { title = "Week 2 - Day 2 - Easy Run"
              , workoutId = 6
              , description = Just "Build a well of strength"
              , segments =
                    [ { startTime = 0, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 40, speed = 0 }
                    ]
              }
            , { title = "Week 2 - Day 4 - Fartlek Run"
              , workoutId = 7
              , description = Just "Another pace change workout to build mental toughness"
              , segments =
                    [ { startTime = 0, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 15, speed = paceToSpeed 5.0 }
                    , { startTime = Time.minute * 17, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 18, speed = paceToSpeed 5.0 }
                    , { startTime = Time.minute * 20, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 21, speed = paceToSpeed 5.0 }
                    , { startTime = Time.minute * 23, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 24, speed = paceToSpeed 5.0 }
                    , { startTime = Time.minute * 26, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 27, speed = paceToSpeed 5.0 }
                    , { startTime = Time.minute * 29, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 30, speed = paceToSpeed 5.0 }
                    , { startTime = Time.minute * 32, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 50, speed = 0.0 }
                    ]
              }
            , { title = "Week 2 - Day 7 - Long Run"
              , workoutId = 8
              , description = Just "Build your endurance for the race"
              , segments =
                    [ { startTime = 0, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 75, speed = 0 }
                    ]
              }
            , { title = "Week 2 - Day 2 - Easy Run"
              , workoutId = 9
              , description = Just "Build your endurance for the race"
              , segments =
                    [ { startTime = 0, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 60, speed = 0 }
                    ]
              }
            , { title = "Week 2 - Day 4 - Tempo Run"
              , workoutId = 10
              , description = Just "Improve lactate threshold"
              , segments =
                    [ { startTime = 0, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 10, speed = paceToSpeed 6.5 }
                    , { startTime = Time.minute * 40, speed = 7.0 }
                    , { startTime = Time.minute * 55, speed = 7.0 }
                    ]
              }
            , { title = "Week 2 - Day 7 - Progression Run"
              , workoutId = 11
              , description = Just "Control effort early to finish strong"
              , segments =
                    [ { startTime = 0, speed = paceToSpeed 7.0 }
                    , { startTime = Time.minute * 60, speed = paceToSpeed 5.5 }
                    , { startTime = Time.minute * 70, speed = 0.0 }
                    ]
              }
            ]
      }
    , Cmd.none
    )


{-| Coverts pace in min/km to speed in km/hr
-}
paceToSpeed : Float -> Float
paceToSpeed pace =
    1.0 / pace * 60.0


workoutListUpdate : Msg -> WorkoutListModel -> ( WorkoutListModel, Cmd Msg )
workoutListUpdate msg model =
    ( model, Cmd.none )


viewWorkoutListItem : WorkoutListModel -> Html Msg
viewWorkoutListItem model =
    div [ class "workout-list" ]
        (List.map viewWorkout model.workoutList)


viewWorkout : Workout -> Html Msg
viewWorkout workout =
    div
        [ class "workout-list-item"
        , onClick (StartWorkout (Just workout))
        ]
        [ text workout.title
        , button
            [ class "workout-list-item-edit", onClick (EditWorkout workout.workoutId) ]
            [ text "Edit" ]
        ]
