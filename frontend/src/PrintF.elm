module PrintF exposing (..)

{-| Implements printf style conversion of things to Strings.

Initially this will only do just enough to format times and distances,
but eventually I'd like it to be a separate project that implements all
of the printf spec. Due to type safety, this will not be a string template
that is parsed and replaced with arbitary values. Instead, individual functions
that format different types, and data structures representing how those values
should be represented as a string.

http://www.cplusplus.com/reference/cstdio/printf/

# Conversion of a float to string
@docs formatFloat

-}

{- http://stackoverflow.com/a/253874/32515 -}
approximatelyEqual a b epsilon =
    let
        t = if (abs a) < (abs b) then
                (abs b)
            else
                (abs a) * epsilon
    in
        (abs (a - b)) <= t


essentiallyEqual a b epsilon =
    let
        t = if (abs a) > (abs b) then
                (abs b)
            else
                (abs a) * epsilon
    in
        (abs (a - b)) <= t

{- &shrug; -}
epsilon = 2.2204460492503130808472633361816E-16


{- Convert a float to a string with a specified number of digits after the
decimal point. -}
formatFloat f precision =
    let
        integer_part =
            floor (f)

        fractional_part = f - (toFloat integer_part)

        fractionalToString fractional precision =
            let
                positionToString (remainder, output) =
                    let
                        next = remainder * 10
                        position = truncate next
                    in
                        (next - (toFloat position), output ++ (toString position))

                helper (remainder, output) positions =
                    if positions <= 0 then
                        (remainder, output)
                    else
                        helper (positionToString (remainder, output)) (positions - 1)

                (_, fractionalString) = helper (fractional, "") precision
            in
                fractionalString

    in
        if precision > 0 then
            toString integer_part
            ++ "."
            ++ (fractionalToString fractional_part precision)
        else
            toString integer_part
