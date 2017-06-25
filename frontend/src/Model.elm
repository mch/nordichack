module Model exposing (DataModel, HeartData, initDataModel)

{-| This module contains a model that contains data available to the whole app.

TODO:
* Move lots of stuff from ControlPanel to here.

# Definition
@docs DataModel

-}


type alias DataModel =
    { heartdata : HeartData
    , rrIntervalTimeSeries : List ( Int, Int )
    }


type alias HeartData =
    { heartrate : Maybe Int
    , rrInterval : Maybe Int
    , eventTime : Maybe Int
    }


initDataModel : DataModel
initDataModel =
    { heartdata =
        { heartrate = Maybe.Nothing
        , rrInterval = Maybe.Nothing
        , eventTime = Maybe.Nothing
        }
    , rrIntervalTimeSeries = []
    }
