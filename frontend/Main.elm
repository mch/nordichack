import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Http exposing (send, request, stringBody, expectString)
import Time

-- Speed is represented as an integer in increments of 0.2 to avoid
-- floating point fun.
speed_increment : Float
speed_increment = 0.2
min_speed_increment = 0
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
        IncreaseSpeed -> changeSpeed model (model.speed + 1)
        DecreaseSpeed -> changeSpeed model (model.speed - 1)
        SetSpeed speed -> changeSpeed model speed
        SetSpeedResponse result -> (updateSpeed model result, Cmd.none)


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
    if requestedSpeed >= min_speed_increment && requestedSpeed <= max_speed_increment then
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
                           , timeout = Just Time.second
                           , withCredentials = False
                           }
    in
        Http.send (\r -> SetSpeedResponse r) req


view : Model -> Html Msg
view model =
    div [] [ div [] [ text ("Current Speed: " ++ (toString ((toFloat model.speed) * speed_increment))) ]
           , div [] [ button
                          [ class "mdl-button mdl-js-button mdl-button--fab mdl-button--colored"
                          , onClick IncreaseSpeed ]
                          [ i [ class "material-icons" ] [ text "add circle outline" ] ]
                    , button
                          [ class "mdl-button mdl-js-button mdl-button--fab mdl-button--colored"
                          , onClick DecreaseSpeed ]
                          [ i [ class "material-icons" ] [ text "remove circle outline" ] ]
                    ]
           , div [] [ text "Speed Presets" ]
           , div [] [ button
                          [ class "mdl-button mdl-js-button mdl-button--raised mdl-button--accent"
                          , onClick (SetSpeed 10)]
                          [ text "2"]
                    , button
                          [ class "mdl-button mdl-js-button mdl-button--raised mdl-button--accent"
                          , onClick (SetSpeed 20)]
                          [ text "4"]
                    , button
                          [ class "mdl-button mdl-js-button mdl-button--raised mdl-button--accent"
                          , onClick (SetSpeed 30)]
                          [ text "6"]
                    , button
                          [ class "mdl-button mdl-js-button mdl-button--raised mdl-button--accent"
                          , onClick (SetSpeed 40)]
                          [ text "8"]
                    , button
                          [ class "mdl-button mdl-js-button mdl-button--raised mdl-button--accent"
                          , onClick (SetSpeed 50)]
                          [ text "10"]
                    , button
                          [ class "mdl-button mdl-js-button mdl-button--raised mdl-button--accent"
                          , onClick (SetSpeed 60)]
                          [ text "12"]
                    ]
           , div [] [ text model.error ]
           ]
