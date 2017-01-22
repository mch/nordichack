module Main exposing (..)

import ControlPanel
import WorkoutList

import Html exposing (program, Html)

main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type Msg
    = ControlPanelMsg ControlPanel.Msg
    | WorkoutListMsg WorkoutList.Msg


type Screen
    = ControlPanelScreen
    | WorkoutListScreen

type alias Model =
    { controlPanel : ControlPanel.Model
    , workoutList : WorkoutList.Model
    , currentScreen : Screen
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    ControlPanel.subscriptions model.controlPanel
    |> Sub.map ControlPanelMsg


init : ( Model, Cmd Msg )
init =
    let
       (cpm, cpc) = ControlPanel.init
       (wlm, wlc) = WorkoutList.init
    in
        { controlPanel = cpm
        , workoutList = wlm
        , currentScreen = ControlPanelScreen
        }
        ! [ Cmd.map ControlPanelMsg cpc, Cmd.map WorkoutListMsg wlc ]


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    -- I'm doing this wrong I'm sure; there must be a more composable
    -- and generic way of doing this.
    case msg of
        ControlPanelMsg m ->
            let
                (cpm, cpc) = ControlPanel.update m model.controlPanel
            in
                ({ model | controlPanel = cpm }, Cmd.map ControlPanelMsg cpc)
        WorkoutListMsg m ->
            let
                (wlm, wlc) = WorkoutList.update m model.workoutList
            in
                ({ model | workoutList = wlm }, Cmd.map WorkoutListMsg wlc)


view : Model -> Html Msg
view model =
    case model.currentScreen of
        ControlPanelScreen -> Html.map ControlPanelMsg (ControlPanel.view model.controlPanel)

        WorkoutListScreen -> Html.map WorkoutListMsg (WorkoutList.view model.workoutList)
