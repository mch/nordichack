import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)

-- Speed is represented as an integer in increments of 0.2 to avoid
-- floating point fun.
speed_increment : Float
speed_increment = 0.2
min_speed_increment = 0
max_speed_increment = 30 * 5 -- 30 Km/h, 5 increments of 0.2


main = Html.beginnerProgram { model = model, view = view, update = update }

type alias Model = Int

model : Model
model = 0


type Msg = IncreaseSpeed
         | DecreaseSpeed
         | SetSpeed Int


update : Msg -> Model -> Model
update msg model =
    case msg of
        IncreaseSpeed -> changeSpeed model (model + 1)
        DecreaseSpeed -> changeSpeed model (model - 1)
        SetSpeed speed -> changeSpeed model speed


changeSpeed : Int -> Int -> Int
changeSpeed originalSpeed requestedSpeed =
    if requestedSpeed >= min_speed_increment && requestedSpeed <= max_speed_increment then
        requestedSpeed
    else
        originalSpeed


view : Model -> Html Msg
view model =
    div [] [ div [] [ text ("Current Speed: " ++ (toString ((toFloat model) * speed_increment))) ]
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
           ]
