import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Http exposing (send, request, stringBody, expectString)
import Time

-- Speed is represented as an integer in increments of 0.2 to avoid
-- floating point fun.
speed_increment : Float
speed_increment = 0.2
min_speed_increment = 2 * 5  -- 2 Km/h
max_speed_increment = 30 * 5 -- 30 Km/h, 5 increments of 0.2


main = Html.program { init = init
                    , view = view
                    , update = update
                    , subscriptions = subscriptions }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


type alias Model =
    { speed : Int
    , requestedSpeed : Int
    , error : String
    }


type Msg = IncreaseSpeed
         | DecreaseSpeed
         | SetSpeed Int
         | SetSpeedResponse (Result Http.Error String)


init : (Model, Cmd Msg)
init = ({ speed = 0, requestedSpeed = 0, error = "" }, Cmd.none)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        IncreaseSpeed -> increaseSpeed model
        DecreaseSpeed -> decreaseSpeed model
        SetSpeed speed -> changeSpeed model speed
        SetSpeedResponse result -> (updateSpeed model result, Cmd.none)


increaseSpeed : Model -> (Model, Cmd Msg)
increaseSpeed model =
    let
        requestedSpeed =
            if (model.speed < min_speed_increment) then
                min_speed_increment
            else
                model.speed + 1
    in
        ({ model | requestedSpeed = requestedSpeed }, postSpeedChange requestedSpeed)


decreaseSpeed : Model -> (Model, Cmd Msg)
decreaseSpeed model =
    let
        requestedSpeed =
            if (model.speed == min_speed_increment) then
                0
            else
                model.speed - 1
    in
        ({ model | requestedSpeed = requestedSpeed }, postSpeedChange requestedSpeed)


updateSpeed : Model -> Result Http.Error String -> Model
updateSpeed model result =
    case result of
        Ok response -> { model | speed = model.requestedSpeed, error = "" } -- Have to check response...
        Err error -> { model | requestedSpeed = model.speed, error = stringifyError error }


stringifyError error =
    case error of
        Http.BadUrl s -> "Bad URL: " ++ s
        Http.Timeout -> "Timeout"
        Http.NetworkError -> "Network Error"
        Http.BadStatus r -> "Bad status"
        Http.BadPayload s r -> "Bad payload"


changeSpeed : Model -> Int -> (Model, Cmd Msg)
changeSpeed model requestedSpeed =
    if requestedSpeed == 0
        || (requestedSpeed >= min_speed_increment
            && requestedSpeed <= max_speed_increment) then
        ({ model | requestedSpeed = requestedSpeed }, postSpeedChange requestedSpeed)
    else
        (model, Cmd.none)


postSpeedChange : Int -> Cmd Msg
postSpeedChange requestedSpeed =
    let
        req = Http.request { method = "POST"
                           , headers = []
                           , url = "/api/v1/desiredspeed"
                           , body = (stringBody "text/plain" (toString ((toFloat requestedSpeed) * speed_increment)))
                           , expect = expectString
                           , timeout = Just (Time.second * 2.5)
                           , withCredentials = False
                           }
    in
        Http.send (\r -> SetSpeedResponse r) req


view : Model -> Html Msg
view model =
    div [ class "cpanel" ]
        [ div [ class "cpanel-readout" ]
              [ div [ class "cpanel-readout-speed" ]
                    [ text ((toString ((toFloat model.speed) * speed_increment)) ++ " km/h" ) ] 
              , div [ class "cpanel-readout-time" ]
                  [ text "00:00" ] 
              , div [ class "cpanel-readout-distance" ]
                  [ text "0.00 km" ] ]
        , div [ class "cpanel-buttons" ]
            [ button
                  [ class "cpanel-button"
                  , onClick IncreaseSpeed ]
                  [ text "+" ]
            , button
                  [ class "cpanel-button"
                  , onClick DecreaseSpeed ]
                  [ text "-" ]
            ]
        , div [] [ button
                       [ class "cpanel-preset-button"
                       , onClick (SetSpeed 10)]
                       [ text "2"]
                 , button
                       [ class "cpanel-preset-button"
                       , onClick (SetSpeed 20)]
                       [ text "4"]
                 , button
                       [ class "cpanel-preset-button"
                       , onClick (SetSpeed 30)]
                       [ text "6"]
                 , button
                       [ class "cpanel-preset-button"
                       , onClick (SetSpeed 40)]
                       [ text "8"]
                 , button
                       [ class "cpanel-preset-button"
                       , onClick (SetSpeed 50)]
                       [ text "10"]
                 , button
                       [ class "cpanel-preset-button"
                       , onClick (SetSpeed 60)]
                       [ text "12"]
                 ]
        , div [] [ button
                       [ class "cpanel-start-button"
                       , onClick (SetSpeed 10) ]
                       [ text "Start" ]
                 , button
                       [ class "cpanel-stop-button"
                       , onClick (SetSpeed 0) ]
                       [ text "Stop" ]
                 ]
        , div [] [ text model.error ]
        ]
        
