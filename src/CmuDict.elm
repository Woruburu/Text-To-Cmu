module CmuDict exposing (generateResponse, parseDictionary)

import Dict exposing (Dict)
import Punctuation
import VowelStrength exposing (VowelStrength)


generateResponse : Dict String String -> VowelStrength -> Bool -> List String -> List String
generateResponse dict vowelStrength convertBrackets input =
    List.map
        (\word ->
            case Dict.get (String.toUpper word) dict of
                Just value ->
                    returnValue vowelStrength value

                Nothing ->
                    let
                        removePunctuation =
                            splitPunctuation dict Punctuation.all vowelStrength convertBrackets word
                    in
                    case Dict.get (String.toUpper removePunctuation) dict of
                        Just value ->
                            returnValue vowelStrength value

                        Nothing ->
                            if convertBrackets then
                                "[" ++ removePunctuation ++ "]"

                            else
                                removePunctuation
        )
        input


returnValue : VowelStrength -> String -> String
returnValue vowelStrength value =
    let
        convert =
            VowelStrength.convert vowelStrength value
    in
    "{" ++ convert ++ "}"


splitPunctuation : Dict String String -> List String -> VowelStrength -> Bool -> String -> String
splitPunctuation dict allPunctuation vowelStrength convertBrackets word =
    case List.head allPunctuation of
        Just punctuation ->
            let
                newWord =
                    if String.contains punctuation word then
                        String.split punctuation word
                            |> generateResponse dict vowelStrength convertBrackets
                            |> String.join punctuation

                    else
                        word
            in
            splitPunctuation dict (Maybe.withDefault [] <| List.tail allPunctuation) vowelStrength convertBrackets newWord

        Nothing ->
            word


parseDictionary : String -> Dict String String
parseDictionary text =
    let
        lines =
            String.lines text

        validLines =
            List.filter (\line -> not <| String.startsWith ";;;" line) lines
    in
    List.filterMap lineToTuple validLines
        |> Dict.fromList


lineToTuple : String -> Maybe ( String, String )
lineToTuple line =
    let
        spaceSplit =
            String.split "  " line

        maybeKey =
            List.head spaceSplit

        maybeValue =
            case List.tail spaceSplit of
                Just tail ->
                    List.head tail

                Nothing ->
                    Nothing
    in
    case maybeKey of
        Just key ->
            case maybeValue of
                Just value ->
                    Just ( String.toUpper key, String.toUpper value )

                Nothing ->
                    Nothing

        Nothing ->
            Nothing
