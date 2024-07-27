module Backend exposing (..)

import Html
import Lamdera
import Task
import Time
import Types exposing (..)


type alias Model =
    BackendModel


backend params =
    let
        mapCmd : ( model, Cmd msg ) -> ( model, Cmd ( msg, Maybe Time.Posix ) )
        mapCmd ( model, cmdMsg ) =
            ( model
            , Cmd.map (\msg_ -> Tuple.pair msg_ Nothing) cmdMsg
            )
    in
    Lamdera.backend
        { init = mapCmd params.init
        , update =
            \( msg, maybeTimestamp ) model ->
                case maybeTimestamp of
                    Nothing ->
                        ( model
                        , Task.perform (Just >> Tuple.pair msg) Time.now
                        )

                    Just timestamp ->
                        params.update timestamp msg model
                            |> mapCmd
        , updateFromFrontend =
            \sessionId clientId toBackend model ->
                params.updateFromFrontend sessionId clientId toBackend model
                    |> mapCmd
        , subscriptions =
            \model ->
                params.subscriptions model
                    |> Sub.map (\msg_ -> Tuple.pair msg_ Nothing)
        }


app =
    backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = always Sub.none
        }


init : ( Model, Cmd BackendMessage )
init =
    ( { message = "Hello!" }
    , Cmd.none
    )


update : Time.Posix -> BackendMessage -> Model -> ( Model, Cmd BackendMessage )
update timestamp msg model =
    case msg of
        NoOpBackendMsg ->
            ( model, Cmd.none )


updateFromFrontend : Lamdera.SessionId -> Lamdera.ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMessage )
updateFromFrontend sessionId clientId msg model =
    case msg of
        NoOpToBackend ->
            ( model, Cmd.none )
