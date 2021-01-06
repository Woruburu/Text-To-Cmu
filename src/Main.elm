module Main exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Browser
import CmuDict
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (attribute, class, id, placeholder, selected, style, type_, value)
import Html.Events exposing (onCheck, onClick, onInput)
import Http
import Process
import String exposing (startsWith)
import Task exposing (Task)
import Url.Builder as UBuilder
import VowelStrength exposing (VowelStrength(..))



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { dictionary : DictionaryState
    , input : String
    , value : String
    , vowelStrength : VowelStrength
    , copyClicked : Bool
    , convertBrackets : Bool
    }


type DictionaryState
    = Loading
    | Failure
    | Success (Dict String String)


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model Loading "" "" NoChange False False
    , getDictionary <| UBuilder.absolute [ "dictionary.txt" ] []
    )


getDictionary : String -> Cmd Msg
getDictionary url =
    Http.get
        { url = url
        , expect = Http.expectString GotText
        }



-- UPDATE


type Msg
    = NoOp
    | GotText (Result Http.Error String)
    | OnTextInput String
    | VowelStrengthChange String
    | CopyClick
    | CopyTimeout ()
    | AddBracketsChange Bool


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        CopyClick ->
            ( { model | copyClicked = True }, Task.perform CopyTimeout (Process.sleep 1000) )

        CopyTimeout _ ->
            ( { model | copyClicked = False }, Cmd.none )

        AddBracketsChange value ->
            let
                newModel =
                    { model | convertBrackets = value }
            in
            case model.dictionary of
                Success dict ->
                    ( { newModel | value = getResponse dict newModel.vowelStrength newModel.convertBrackets newModel.input }, Cmd.none )

                _ ->
                    ( newModel, Cmd.none )

        GotText result ->
            case result of
                Ok fullText ->
                    let
                        parsedDictionary =
                            CmuDict.parseDictionary fullText
                    in
                    ( { model | dictionary = Success parsedDictionary }, Cmd.none )

                Err _ ->
                    ( { model | dictionary = Failure }, Cmd.none )

        OnTextInput input ->
            case model.dictionary of
                Success dict ->
                    ( { model | input = input, value = getResponse dict model.vowelStrength model.convertBrackets input }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        VowelStrengthChange value ->
            let
                newModel =
                    case String.toLower value of
                        "no-change" ->
                            { model | vowelStrength = NoChange }

                        "terse" ->
                            { model | vowelStrength = Terse }

                        "normal" ->
                            { model | vowelStrength = Medium }

                        "extra-lewd" ->
                            { model | vowelStrength = ExtraLewd }

                        _ ->
                            model
            in
            case model.dictionary of
                Success dict ->
                    ( { newModel | value = getResponse dict newModel.vowelStrength newModel.convertBrackets newModel.input }, Cmd.none )

                _ ->
                    ( newModel, Cmd.none )


getResponse : Dict String String -> VowelStrength -> Bool -> String -> String
getResponse dict vowelStrength convertBrackets input =
    let
        split =
            String.split "|" input

        lines =
            List.head split
                |> Maybe.withDefault ""
                |> String.lines

        -- String.lines input
        response =
            List.map
                (\line ->
                    String.words line
                        |> CmuDict.generateResponse dict vowelStrength convertBrackets
                        |> String.join " "
                )
                lines
                |> String.join "\n"
    in
    case List.tail split of
        Just tail ->
            [ response ]
                ++ tail
                |> String.join "|"

        Nothing ->
            response



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ class "container" ]
        [ h1 [] [ text "Text to CMU Translator" ]
        , div [] <|
            case model.dictionary of
                Loading ->
                    [ text "Loading Dictionary..." ]

                Failure ->
                    [ text "Could not load dictinoary" ]

                Success dictionary ->
                    [ fieldset []
                        [ div
                            [ class "form-group" ]
                            [ label []
                                [ textarea [ style "resize" "vertical", onInput OnTextInput, placeholder "Enter text to convert to CMU here" ] []
                                ]
                            ]
                        , div
                            [ class "form-group" ]
                            [ label []
                                [ text "Vowel Transform"
                                , br [] []
                                , select [ onInput VowelStrengthChange ]
                                    [ option
                                        [ value "no-change"
                                        , selected
                                            (if model.vowelStrength == NoChange then
                                                True

                                             else
                                                False
                                            )
                                        ]
                                        [ text "Do not change" ]
                                    , option
                                        [ value "terse"
                                        , selected
                                            (if model.vowelStrength == Terse then
                                                True

                                             else
                                                False
                                            )
                                        ]
                                        [ text "Terse" ]
                                    , option
                                        [ value "normal"
                                        , selected
                                            (if model.vowelStrength == Medium then
                                                True

                                             else
                                                False
                                            )
                                        ]
                                        [ text "Normal" ]
                                    , option
                                        [ value "extra-lewd"
                                        , selected
                                            (if model.vowelStrength == ExtraLewd then
                                                True

                                             else
                                                False
                                            )
                                        ]
                                        [ text "Extra Lewd" ]
                                    ]
                                ]
                            ]
                        , div
                            [ class "form-group" ]
                            [ label []
                                [ input [ type_ "checkbox", onCheck AddBracketsChange ] []
                                , text " Add [] to untranslatable words?"
                                ]
                            ]
                        ]
                    , br [] []
                    , div []
                        [ div [] [ text "Output" ]
                        , pre [ id "result" ] [ text model.value ]
                        , div
                            [ style "display" "flex" ]
                            [ button
                                [ id "copy-button", style "margin-left" "auto", class "btn btn-default", attribute "data-clipboard-target" "#result", onClick CopyClick ]
                                [ text <|
                                    if model.copyClicked then
                                        "Copied"

                                    else
                                        "Copy"
                                ]
                            ]
                        ]
                    ]
        ]
