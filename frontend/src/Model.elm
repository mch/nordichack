module Model exposing (DataModel, HeartData, initDataModel)

{-| This module contains a model that contains data available to the whole app.

TODO:
* Move lots of stuff from ControlPanel to here.

# Definition
@docs DataModel

-}


type alias DataModel =
    { heartdata : HeartData
    }


type alias HeartData =
    { heartrate : Maybe Int
    , rrInterval : Maybe Int
    , eventTime : Maybe Float
    }


initDataModel : DataModel
initDataModel =
    { heartdata =
        { heartrate = Maybe.Nothing
        , rrInterval = Maybe.Nothing
        , eventTime = Maybe.Nothing
        }
    }
