module Main exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Browser
import CmuDict
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (class, placeholder, style)
import Html.Events exposing (onInput)
import Http
import Process
import String exposing (startsWith)
import Task exposing (Task)
import Url.Builder as UBuilder



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
    }


type DictionaryState
    = Loading
    | Failure
    | Success (Dict String String)


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model Loading "" ""
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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

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
                    let
                        lines =
                            String.lines input

                        response =
                            List.map
                                (\line ->
                                    String.words line
                                        |> CmuDict.generateResponse dict
                                        |> String.join " "
                                )
                                lines
                    in
                    ( { model | input = input, value = String.join "\n" response }, Cmd.none )

                _ ->
                    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ h1 [] [ text "Text to CMU Translator" ]
        , div [] <|
            case model.dictionary of
                Loading ->
                    [ text "Loading Dictionary..." ]

                Failure ->
                    [ text "Could not load dictinoary" ]

                Success dictionary ->
                    [ div []
                        [ label []
                            [ textarea [ style "resize" "vertical", onInput OnTextInput, placeholder "Enter text to convert to CMU here" ] []
                            ]
                        ]
                    , div []
                        [ pre [] [ text model.value ]
                        ]
                    ]
        ]
