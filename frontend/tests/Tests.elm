module Tests exposing (..)

import Test exposing (..)


import WorkoutTests exposing (..)

all : Test
all =
    describe
        "NordicHack"
        [ WorkoutTests.all
        ]
