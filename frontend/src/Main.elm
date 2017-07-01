module Main exposing (..)

import Ant exposing (Model, init, view, update)
import Common exposing (..)
import ControlPanel exposing (..)
import Model exposing (DataModel, initDataModel)
import Workout exposing (..)
import WorkoutData exposing (..)

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
            (workoutListInit, Cmd.none)

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

                nextRRInterval =
                    Maybe.map2 (,) heartdata.eventTime heartdata.rrInterval
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
                    Html.map AntMsg (Ant.view model.dataModel)
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
