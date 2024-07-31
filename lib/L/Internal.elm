module L.Internal exposing
    ( BackendProgram
    , ClientId
    , ClientSet
    , FrontendProgram
    , SessionDict
    , SessionId
    , backend
    , broadcast
    , frontend
    , mapClientSet
    , newClientId
    , newSessionId
    , onConnect
    , onDisconnect
    , sendToBackend
    , sendToFrontend
    , toListClientSet
    )

import Browser
import Browser.Navigation
import Dict
import Html
import Lamdera
import Set
import Task
import Time
import Url


type alias SessionId =
    { value : Lamdera.SessionId
    , tag : ()
    }


newSessionId : Lamdera.SessionId -> SessionId
newSessionId value =
    { value = value
    , tag = ()
    }


type alias ClientId =
    { value : Lamdera.ClientId
    , tag : {}
    }


newClientId : Lamdera.ClientId -> ClientId
newClientId value =
    { value = value
    , tag = {}
    }


onConnect : (SessionId -> ClientId -> toBackend) -> Sub toBackend
onConnect toBackend =
    Lamdera.onConnect
        (\sessionId clientId ->
            toBackend (newSessionId sessionId) (newClientId clientId)
        )


onDisconnect : (SessionId -> ClientId -> toBackend) -> Sub toBackend
onDisconnect toBackend =
    Lamdera.onDisconnect
        (\sessionId clientId ->
            toBackend (newSessionId sessionId) (newClientId clientId)
        )


sendToBackend =
    Lamdera.sendToBackend


sendToFrontend clientId =
    Lamdera.sendToFrontend clientId.value


broadcast =
    Lamdera.broadcast


type alias FrontendProgram frontendModel toFrontend msg =
    { init :
        Lamdera.Url
        -> Browser.Navigation.Key
        -> ( frontendModel, Cmd ( msg, Maybe Time.Posix ) )
    , onUrlChange : Url.Url -> ( msg, Maybe Time.Posix )
    , onUrlRequest : Browser.UrlRequest -> ( msg, Maybe Time.Posix )
    , subscriptions : frontendModel -> Sub ( msg, Maybe Time.Posix )
    , update :
        ( msg, Maybe Time.Posix )
        -> frontendModel
        -> ( frontendModel, Cmd ( msg, Maybe Time.Posix ) )
    , updateFromBackend :
        toFrontend
        -> frontendModel
        -> ( frontendModel, Cmd ( msg, Maybe Time.Posix ) )
    , view : frontendModel -> Browser.Document ( msg, Maybe Time.Posix )
    }


frontend :
    { init : Lamdera.Url -> Browser.Navigation.Key -> ( frontendModel, Cmd msg )
    , view : frontendModel -> Browser.Document msg
    , update : Time.Posix -> msg -> frontendModel -> ( frontendModel, Cmd msg )
    , updateFromBackend : toFrontend -> frontendModel -> ( frontendModel, Cmd msg )
    , subscriptions : frontendModel -> Sub msg
    , onUrlRequest : Browser.UrlRequest -> msg
    , onUrlChange : Url.Url -> msg
    }
    -> FrontendProgram frontendModel toFrontend msg
frontend params =
    Lamdera.frontend
        { init =
            \url key -> mapUpdate <| params.init url key
        , view =
            \model ->
                params.view model
                    |> (\{ title, body } ->
                            { title = title
                            , body =
                                List.map
                                    (Html.map mapMsg)
                                    body
                            }
                       )
        , update =
            \( msg, maybeTimestamp ) model ->
                case maybeTimestamp of
                    Nothing ->
                        ( model
                        , Task.perform (\timestamp -> Just timestamp |> Tuple.pair msg) Time.now
                        )

                    Just timestamp ->
                        params.update timestamp msg model
                            |> mapUpdate
        , updateFromBackend =
            \toFrontend model ->
                params.updateFromBackend toFrontend model
                    |> mapUpdate
        , subscriptions =
            \model ->
                params.subscriptions model
                    |> mapSub
        , onUrlRequest =
            \value -> params.onUrlRequest value |> mapMsg
        , onUrlChange =
            \value -> params.onUrlChange value |> mapMsg
        }


type alias BackendProgram backendModel toBackend bsg =
    { init : ( backendModel, Cmd ( bsg, Maybe Time.Posix ) )
    , subscriptions : backendModel -> Sub ( bsg, Maybe Time.Posix )
    , update :
        ( bsg, Maybe Time.Posix )
        -> backendModel
        -> ( backendModel, Cmd ( bsg, Maybe Time.Posix ) )
    , updateFromFrontend :
        Lamdera.SessionId
        -> Lamdera.ClientId
        -> toBackend
        -> backendModel
        -> ( backendModel, Cmd ( bsg, Maybe Time.Posix ) )
    }


backend :
    { init : ( backendModel, Cmd bsg )
    , update : Time.Posix -> bsg -> backendModel -> ( backendModel, Cmd bsg )
    , updateFromFrontend : SessionId -> ClientId -> toBackend -> backendModel -> ( backendModel, Cmd bsg )
    , subscriptions : backendModel -> Sub bsg
    }
    -> BackendProgram backendModel toBackend bsg
backend params =
    Lamdera.backend
        { init = mapUpdate params.init
        , update =
            \( msg, maybeTimestamp ) model ->
                case maybeTimestamp of
                    Nothing ->
                        ( model
                        , Task.perform (\timestamp -> Just timestamp |> Tuple.pair msg) Time.now
                        )

                    Just timestamp ->
                        params.update timestamp msg model
                            |> mapUpdate
        , updateFromFrontend =
            \sessionId clientId toBackend model ->
                params.updateFromFrontend (newSessionId sessionId) (newClientId clientId) toBackend model
                    |> mapUpdate
        , subscriptions =
            \model ->
                params.subscriptions model
                    |> mapSub
        }


type alias SessionDict value =
    Dict.Dict Lamdera.SessionId value


type alias ClientSet =
    Set.Set Lamdera.ClientId


toListClientSet : ClientSet -> List ClientId
toListClientSet clientSet =
    Set.toList clientSet
        |> List.map newClientId


mapClientSet : (ClientId -> a) -> ClientSet -> List a
mapClientSet f value =
    toListClientSet value
        |> List.map f



-- internals : message mapping


mapMsg : msg -> ( msg, Maybe Time.Posix )
mapMsg msg_ =
    Tuple.pair msg_ Nothing


mapSub : Sub msg -> Sub ( msg, Maybe Time.Posix )
mapSub =
    Sub.map mapMsg


mapCmd : Cmd msg -> Cmd ( msg, Maybe Time.Posix )
mapCmd =
    Cmd.map mapMsg


mapUpdate : ( model, Cmd msg ) -> ( model, Cmd ( msg, Maybe Time.Posix ) )
mapUpdate =
    Tuple.mapSecond mapCmd
