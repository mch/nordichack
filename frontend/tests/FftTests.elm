module FftTests exposing (..)

import Test exposing (..)
import Expect
import Fuzz exposing (list, int, tuple, string)
import String
--import Fft exposing (..)

----------
minTimePoint : (List (Float, Float)) -> Int
minTimePoint data =
    0

maxTimePoint : (List (Float, Float)) -> Int
maxTimePoint data =
    0

dataPointBefore : (List (Float, Float)) -> Int -> (Float, Float)
dataPointBefore data timePoint =
    (0.0, 0.0)

dataPointAfter : (List (Float, Float)) -> Int -> (Float, Float)
dataPointAfter data timePoint =
    (0.0, 0.0)

interpolateRrInterval : Int -> (Float, Float) -> (Float, Float) -> Float
interpolateRrInterval timePoint before after =
    0.0
    
----------

all : Test
all =
    describe
        "Fourier Transform Test Suite"
        [ sampleRrData
        , forwardDft
        ]


fixture =
    let
        rawData =
            [ ( 3622.5920000000006, 687 )
            , ( 3623.2840000000006, 692 )
            , ( 3623.9650000000006, 681 )
            , ( 3624.6500000000005, 685 )
            , ( 3625.3680000000004, 718 )
            , ( 3626.1110000000003, 743 )
            , ( 3626.8750000000005, 764 )
            , ( 3627.6320000000005, 757 )
            , ( 3628.3570000000004, 725 )
            , ( 3629.0540000000005, 697 )
            , ( 3629.7470000000008, 693 )
            , ( 3630.4380000000006, 691 )
            , ( 3631.1210000000005, 683 )
            , ( 3631.7870000000007, 666 )
            , ( 3632.471000000001, 684 )
            , ( 3633.140000000001, 669 )
            , ( 3633.8110000000006, 671 )
            , ( 3634.5020000000004, 691 )
            , ( 3635.2200000000003, 718 )
            , ( 3635.958, 738 )
            , ( 3636.684, 726 )
            , ( 3637.385, 701 )
            , ( 3638.0840000000003, 699 )
            , ( 3638.7850000000003, 701 )
            , ( 3639.481, 696 )
            , ( 3640.161, 680 )
            , ( 3640.828, 667 )
            , ( 3641.515, 687 )
            , ( 3642.214, 699 )
            , ( 3642.93, 716 )
            , ( 3643.643, 713 )
            , ( 3644.332, 689 )
            , ( 3645.033, 701 )
            , ( 3645.735, 702 )
            , ( 3646.462, 727 )
            , ( 3647.203, 741 )
            , ( 3647.95, 747 )
            , ( 3648.676, 726 )
            , ( 3649.411, 735 )
            , ( 3650.15, 739 )
            , ( 3650.8940000000002, 744 )
            , ( 3651.6310000000003, 737 )
            , ( 3652.3810000000003, 750 )
            , ( 3653.1420000000003, 761 )
            ]
    in
        { rawData = rawData
        }


sampleRrData : Test
sampleRrData =
    describe "Sampling raw RR data to specific time points"
        [ test "Find min time in raw data" <|
            \_ ->
                minTimePoint fixture.rawData
                    |> Expect.equal 3623
        , test "Find max time in raw data" <|
            \_ ->
                maxTimePoint fixture.rawData
                    |> Expect.equal 3653
        , test "Find raw data point before time point" <|
            \_ ->
                dataPointBefore fixture.rawData 3623
                    |> Expect.equal ( 3622.5920000000006, 687 )
        , test "Find raw data point before time point" <|
            \_ ->
                dataPointAfter fixture.rawData 3623
                    |> Expect.equal ( 3623.2840000000006, 692 )
        , test "Interpolate at time point" <|
            \_ ->
                let
                    timePoint = 3623
                    before = ( 3622.5920000000006, 687 )
                    after = ( 3623.2840000000006, 692 )
                in
                    interpolateRrInterval timePoint before after
                        |> Expect.equal 689.5 -- not quite right, this is just an average.
        ]


forwardDft : Test
forwardDft =
    describe "Compute forward DFT"
        [ test "???" <|
            \_ ->
                True
                    |> Expect.equal False
        ]
