module Main exposing (..)

import Common exposing (..)
import ControlPanel
import WorkoutList
import Html exposing (program, Html, text, div)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)


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
    | ChangeScreen Screen


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
        ( cpm, cpc ) =
            ControlPanel.init

        ( wlm, wlc ) =
            WorkoutList.init
    in
        { controlPanel = cpm
        , workoutList = wlm
        , currentScreen = MainMenuScreen
        }
            ! [ Cmd.map ControlPanelMsg cpc, Cmd.map WorkoutListMsg wlc ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    -- I'm doing this wrong I'm sure; there must be a more composable
    -- and generic way of doing this.
    case msg of
        ControlPanelMsg m ->
            let
                ( cpm, cpc ) =
                    ControlPanel.update m model.controlPanel
            in
                ( { model | controlPanel = cpm }, Cmd.map ControlPanelMsg cpc )

        WorkoutListMsg m ->
            let
                ( wlm, wlc ) =
                    WorkoutList.update m model.workoutList
            in
                ( { model | workoutList = wlm }, Cmd.map WorkoutListMsg wlc )

        ChangeScreen s ->
            ( { model | currentScreen = s }, Cmd.none )


view : Model -> Html Msg
view model =
    let
        navbar =
            [ div
                [ class "back-button"
                , onClick (ChangeScreen MainMenuScreen) ]
                [ text "Back" ]
            , div
                [ class "screen-title" ]
                [ text "Screen Title" ]
            ]

        content =
            case model.currentScreen of
                ControlPanelScreen ->
                    Html.map ControlPanelMsg (ControlPanel.view model.controlPanel)

                WorkoutListScreen ->
                    Html.map WorkoutListMsg (WorkoutList.view model.workoutList)

                MainMenuScreen ->
                    viewMainMenu
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
        ]
