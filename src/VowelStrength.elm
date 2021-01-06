module VowelStrength exposing (VowelStrength(..), convert)


type VowelStrength
    = NoChange
    | Terse
    | Medium
    | ExtraLewd


convert : VowelStrength -> String -> String
convert vowelStrength value =
    case vowelStrength of
        NoChange ->
            value

        Medium ->
            String.replace "0" "1" value
                |> String.replace "2" "1"

        Terse ->
            String.replace "1" "0" value
                |> String.replace "2" "0"

        ExtraLewd ->
            String.replace "0" "2" value
                |> String.replace "1" "2"
