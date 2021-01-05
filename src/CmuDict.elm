module CmuDict exposing (generateResponse, parseDictionary)

import Dict exposing (Dict)
import Punctuation


generateResponse : Dict String String -> List String -> List String
generateResponse dict input =
    List.map
        (\word ->
            let
                newWord =
                    test dict Punctuation.all word
            in
            case Dict.get (String.toUpper newWord) dict of
                Just value ->
                    "{" ++ value ++ "}"

                Nothing ->
                    newWord
        )
        input


test : Dict String String -> List String -> String -> String
test dict allPunctuation word =
    case List.head allPunctuation of
        Just punctuation ->
            let
                newWord =
                    if String.contains punctuation word then
                        String.split punctuation word
                            |> generateResponse dict
                            |> String.join punctuation

                    else
                        word
            in
            test dict (Maybe.withDefault [] <| List.tail allPunctuation) newWord

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
