module Main exposing (..)

import Common exposing (..)

import Html exposing (program, Html, text, div, button)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Http exposing (send, request, stringBody, expectString)
import Time exposing (Time)

main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type Msg
    = ControlPanelMsg ControlPanelMsg
    | WorkoutListMsg WorkoutListMsg
    | ChangeScreen Screen


type alias Model =
    { controlPanel : ControlPanelModel
    , workoutList : WorkoutListModel
    , currentScreen : Screen
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    controlPanelSubscriptions model.controlPanel
        |> Sub.map ControlPanelMsg


init : ( Model, Cmd Msg )
init =
    let
        ( cpm, cpc ) =
            controlPanelInit

        ( wlm, wlc ) =
            workoutListInit
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
                    controlPanelUpdate m model.controlPanel
            in
                ( { model | controlPanel = cpm }, Cmd.map ControlPanelMsg cpc )

        WorkoutListMsg m ->
            let
                ( wlm, wlc ) =
                    workoutListUpdate m model.workoutList
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
                    Html.map ControlPanelMsg (controlPanelView model.controlPanel)

                WorkoutListScreen ->
                    Html.map WorkoutListMsg (workoutListView model.workoutList)

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

-- Control Panel...

speed_increment : Float
speed_increment =
-- Speed is represented as an integer in increments of 0.2 to avoid
-- floating point fun.
    0.2


min_speed_increment =
    -- 2 Km/h
    2 * 5


max_speed_increment =
    -- 30 Km/h, 5 increments of 0.2
    30 * 5


controlPanelSubscriptions : ControlPanelModel -> Sub ControlPanelMsg
controlPanelSubscriptions model =
    -- If I used animation timing, I'd be able to display milliseconds
    -- and the distance would be a little more accurate, but at what
    -- cost to power consumption?
    Time.every (Time.second * 0.1) Tick


type alias ControlPanelModel =
    { speed : Int
    , requestedSpeed : Int
    , startTime : Float
    , currentTime : Float
    , distance : Float
    , error : String
    }


type ControlPanelMsg
    = IncreaseSpeed
    | DecreaseSpeed
    | SetSpeed Int
    | SetSpeedResponse (Result Http.Error String)
    | Tick Time.Time


controlPanelInit : ( ControlPanelModel, Cmd ControlPanelMsg )
controlPanelInit =
    ( { speed = 0
      , requestedSpeed = 0
      , startTime = 0.0
      , currentTime = 0.0
      , distance = 0.0
      , error = ""
      }
    , Cmd.none
    )


controlPanelUpdate : ControlPanelMsg -> ControlPanelModel -> ( ControlPanelModel, Cmd ControlPanelMsg )
controlPanelUpdate msg model =
    case msg of
        IncreaseSpeed ->
            increaseSpeed model

        DecreaseSpeed ->
            decreaseSpeed model

        SetSpeed speed ->
            changeSpeed model speed

        SetSpeedResponse result ->
            ( updateSpeed model result, Cmd.none )

        Tick t ->
            ( updateTimeAndDistance model t, Cmd.none )


updateTimeAndDistance : ControlPanelModel -> Time.Time -> ControlPanelModel
updateTimeAndDistance model t =
    -- This is a rough approximation because the time and speed are both inaccurate.
    -- Speed would have to come from the treadmill, as it takes several seconds for
    -- large changes in speed to occur.
    let
        timeStep =
            if model.startTime > 0 then
                Time.inHours (t - model.currentTime)
            else
                0.0

        startTime =
            if model.startTime == 0 then
                t
            else
                model.startTime
    in
        if model.speed > 0 then
            { model
                | currentTime = t
                , startTime = startTime
                , distance = model.distance + (toFloat model.speed) * speed_increment * timeStep
            }
        else
            model


increaseSpeed : ControlPanelModel -> ( ControlPanelModel, Cmd ControlPanelMsg )
increaseSpeed model =
    let
        requestedSpeed =
            if (model.speed < min_speed_increment) then
                min_speed_increment
            else
                model.speed + 1
    in
        ( { model | requestedSpeed = requestedSpeed }, postSpeedChange requestedSpeed )


decreaseSpeed : ControlPanelModel -> ( ControlPanelModel, Cmd ControlPanelMsg )
decreaseSpeed model =
    let
        requestedSpeed =
            if (model.speed == min_speed_increment) then
                0
            else
                model.speed - 1
    in
        ( { model | requestedSpeed = requestedSpeed }, postSpeedChange requestedSpeed )


updateSpeed : ControlPanelModel -> Result Http.Error String -> ControlPanelModel
updateSpeed model result =
    let
        starting =
            model.speed == 0 && model.requestedSpeed /= 0

        stoping =
            model.speed /= 0 && model.requestedSpeed == 0

        updateModel =
            if starting then
                -- Have to check response...
                { model
                    | speed = model.requestedSpeed
                    , startTime = 0.0
                    , currentTime = 0.0
                    , distance = 0.0
                    , error = ""
                }
            else
                { model
                    | speed = model.requestedSpeed
                    , error = ""
                }
    in
        case result of
            Ok response ->
                updateModel

            Err error ->
                { model | requestedSpeed = model.speed, error = stringifyError error }


stringifyError error =
    case error of
        Http.BadUrl s ->
            "Bad URL: " ++ s

        Http.Timeout ->
            "Timeout"

        Http.NetworkError ->
            "Network Error"

        Http.BadStatus r ->
            "Bad status"

        Http.BadPayload s r ->
            "Bad payload"


changeSpeed : ControlPanelModel -> Int -> ( ControlPanelModel, Cmd ControlPanelMsg )
changeSpeed model requestedSpeed =
    if
        requestedSpeed
            == 0
            || (requestedSpeed
                    >= min_speed_increment
                    && requestedSpeed
                    <= max_speed_increment
               )
    then
        ( { model | requestedSpeed = requestedSpeed }, postSpeedChange requestedSpeed )
    else
        ( model, Cmd.none )


postSpeedChange : Int -> Cmd ControlPanelMsg
postSpeedChange requestedSpeed =
    let
        req =
            Http.request
                { method = "POST"
                , headers = []
                , url = "/api/v1/desiredspeed"
                , body = (stringBody "text/plain" (toString ((toFloat requestedSpeed) * speed_increment)))
                , expect = expectString
                , timeout = Just (Time.second * 2.5)
                , withCredentials = False
                }
    in
        Http.send (\r -> SetSpeedResponse r) req


controlPanelView : ControlPanelModel -> Html ControlPanelMsg
controlPanelView model =
    div
        [ class "cpanel" ]
        [ div
            [ class "cpanel-readout" ]
            [ div
                [ class "cpanel-readout-speed" ]
                [ text ((formatSpeed ((toFloat model.speed) * speed_increment)) ++ " km/h") ]
            , div
                [ class "cpanel-readout-time" ]
                [ text (formatTime (model.currentTime - model.startTime)) ]
            , div
                [ class "cpanel-readout-distance" ]
                [ text (formatDistance model.distance) ]
            ]
        , div
            [ class "cpanel-buttons" ]
            [ button
                [ class "cpanel-button"
                , onClick IncreaseSpeed
                ]
                [ text "+" ]
            , button
                [ class "cpanel-button"
                , onClick DecreaseSpeed
                ]
                [ text "-" ]
            ]
        , div
            []
            [ button
                [ class "cpanel-preset-button"
                , onClick (SetSpeed 10)
                ]
                [ text "2" ]
            , button
                [ class "cpanel-preset-button"
                , onClick (SetSpeed 20)
                ]
                [ text "4" ]
            , button
                [ class "cpanel-preset-button"
                , onClick (SetSpeed 30)
                ]
                [ text "6" ]
            , button
                [ class "cpanel-preset-button"
                , onClick (SetSpeed 40)
                ]
                [ text "8" ]
            , button
                [ class "cpanel-preset-button"
                , onClick (SetSpeed 50)
                ]
                [ text "10" ]
            , button
                [ class "cpanel-preset-button"
                , onClick (SetSpeed 60)
                ]
                [ text "12" ]
            ]
        , div
            []
            [ button
                [ class "cpanel-start-button"
                , onClick (SetSpeed 10)
                ]
                [ text "Start" ]
            , button
                [ class "cpanel-stop-button"
                , onClick (SetSpeed 0)
                ]
                [ text "Stop" ]
            ]
        , div [] [ text model.error ]
        ]

formatInt : Int -> String
formatInt n =
    -- This needs to be genericized to allow for any number of leading zeros,
    -- and other things.
    if n < 10 then
        "0" ++ (toString n)
    else
        toString n


formatTime : Time.Time -> String
formatTime ms =
    let
        hours =
            floor (Time.inHours ms)

        minutes =
            floor (Time.inMinutes (ms - (toFloat hours) * Time.hour))

        seconds =
            floor (Time.inSeconds (ms - (toFloat hours) * Time.hour - (toFloat minutes) * Time.minute))

        times =
            if hours > 0 then
                [ hours, minutes, seconds ]
            else
                [ minutes, seconds ]
    in
        List.map formatInt times
            |> String.join ":"


formatDistance : Float -> String
formatDistance d =
    let
        meters_thousands =
            floor (d)

        meters_hundreds =
            floor ((d * 10 - (toFloat meters_thousands)))

        meters_tens =
            floor ((d * 100 - (toFloat meters_hundreds)))

        meters_ones =
            floor ((d * 1000 - (toFloat meters_tens)))
    in
        (toString meters_thousands)
            ++ "."
            ++ (toString meters_hundreds)
            ++ (toString meters_tens)
            ++ (toString meters_ones)
            ++ " km"


formatSpeed : Float -> String
formatSpeed speed =
    let
        -- My vocabulary is failing me
        firstPart =
            floor speed

        secondPart =
            floor ((speed - (toFloat firstPart)) * 10)
    in
        (toString firstPart) ++ "." ++ (toString secondPart)

-- Workout List...

type alias WorkoutListModel =
    { workoutList : List Workout
    }


type WorkoutListMsg
    = Placeholder


workoutListInit : ( WorkoutListModel, Cmd WorkoutListMsg )
workoutListInit =
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


workoutListUpdate : WorkoutListMsg -> WorkoutListModel -> ( WorkoutListModel, Cmd WorkoutListMsg )
workoutListUpdate msg model =
    ( model, Cmd.none )


workoutListView : WorkoutListModel -> Html WorkoutListMsg
workoutListView model =
    div [ class "workout-list" ]
        [ text "Hello world" ]
