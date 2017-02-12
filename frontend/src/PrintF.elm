module PrintF exposing (..)

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
                        position = floor next
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
