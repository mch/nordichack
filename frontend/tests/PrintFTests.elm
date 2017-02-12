module PrintFTests exposing (all)

import Test exposing (..)
import Expect
import PrintF exposing (..)

all : Test
all =
    describe "Conversion of numbers to strings"
    [ floatPrecisionTests
    ]

floatPrecisionTests : Test
floatPrecisionTests =
    describe "Conversion for floats to strings with specified precision"
    [ test "Positive with 1 decimal of precision" <| \_ -> Expect.equal "10.0" <| formatFloat 10.01 1
    -- , test "Positive with 2 decimals of precision" <| \_ -> Expect.equal "10.01" <| formatFloat 10.01 2
    , test "toString Positive with 2 decimals of precision" <| \_ -> Expect.equal "10.01" <| toString 10.01
    , test "Positive with 2 decimals of precision" <| \_ -> Expect.equal "10.06" <| formatFloat 10.06 2
    -- , test "Negative with 2 decimals of precision" <| \_ -> Expect.equal "-10.01" <| formatFloat -10.01 2
    , test "Zero precision shows no decimal point" <| \_ -> Expect.equal "10" <| formatFloat 10.01 0
    , test "Negative precision shows no decimal point" <| \_ -> Expect.equal "10" <| formatFloat 10.01 -1
    -- , test "Last digit rounded up" <| \_ -> Expect.equal "10.5" <| formatFloat 10.49 1
    ]
