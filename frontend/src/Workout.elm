module Workout exposing (Workout, WorkoutSegment, WorkoutId, fromIntervalDuration, getSpeed, getIndex)

import Time exposing (Time)

{-| This module describes a workout that can be executed on a treadmill.

TODO:
* Allow for repeating sequences, e.g. repeat walk 60 seconds, jog 90 seconds, N times.
* Durations may be better than start times as an internal representation.

# Definition
@docs Workout

# Contructing a workout
@docs fromIntervalDuration

# Querying a workout
@docs getSpeed

-}

--type Workout
--    = Workout WorkoutInternal

type alias Workout =
    -- This might be quite under specified, because it requires the
    -- presence of a sentinal segment with a speed of 0 to know
    -- when the workout is complete, so it's possible to have invalid
    -- workouts. Although, a workout where the user has to explicitly stop
    -- might not be invalid...
    { title : String
    , description : Maybe String
    , workoutId : WorkoutId
    , segments : List WorkoutSegment
    }


type alias WorkoutSegment =
    -- The start and end segments are "special" in that the start on always
    -- has startTime = 0 and the end one always has speed = 0. Should there
    -- be a specific type that makes this more explicit?

    -- Should startTime be replaced by duration? Finding the current segment
    -- would be a reduction to sum up durations...
    { startTime : Time
    , speed : Float
    }


type alias WorkoutId =
    Int


{-| Create a workout from a list of (Time, speed) tuples -}
fromIntervalDuration : String -> Maybe String -> Int -> List (Time, Float) -> Workout
fromIntervalDuration title description id data =
    { title = title
    , description = description
    , workoutId = id
    , segments = List.map (\(t, s) -> { startTime = t, speed = s }) data
    }


{-| Returns a tuple containing the index of the segment currently being
run, the current segment, and the next segment.
 -}
getCurrentSegments : Time -> Workout -> Maybe (Int, WorkoutSegment, WorkoutSegment)
getCurrentSegments t w =
    let
        endSegment =
            List.drop (List.length w.segments - 1) w.segments
            |> List.head
            |> Maybe.withDefault {startTime = 0, speed = 0}

        -- For an segment list [s0, s1, ..., sn], create an offset list [s1, s2, ..., sn, sn]
        offsetList =
            List.append (List.drop 1 w.segments) (List.drop (List.length w.segments - 1) w.segments)

        -- Create tuples [(s0, s1), (s1, s2), ..., (sn, sn)]
        zipped =
            List.map2 (,) w.segments offsetList

        -- Index them
        indexList =
            List.indexedMap (\i (a, b) -> (i, a, b)) zipped
    in
        if t >= endSegment.startTime then
            Just (List.length w.segments - 1, endSegment, endSegment)
        else
            List.filter (\(i, a, b) -> t >= a.startTime && t < b.startTime) indexList
            |> List.head


{-| Returns the speed the treadmill should be set to for a given time point. -}
getSpeed : Time -> Workout -> Float
getSpeed t w =
    let
        currentSegments = getCurrentSegments t w
    in
        case currentSegments of
            Nothing -> 0.0

            Just (i, a, b) -> a.speed


{-| Retuns the index of the current segment (note: doubt this is the right way to do this) -}
getIndex : Time -> Workout -> Maybe Int
getIndex t w =
    let
        currentSegments = getCurrentSegments t w
    in
        case currentSegments of
            Nothing -> Nothing

            Just (i, a, b) -> Just i
