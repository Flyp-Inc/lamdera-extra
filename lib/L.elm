module L exposing
    ( BackendProgram
    , ClientId
    , ClientSet
    , FrontendProgram
    , SessionDict
    , SessionId
    , backend
    , broadcast
    , frontend
    , onConnect
    , onDisconnect
    , sendToBackend
    , sendToClients
    , sendToFrontend
    , sessionIdFromCore
    )

import Browser
import Browser.Navigation
import L.Internal
import Time
import Url


type alias SessionId =
    L.Internal.SessionId


type alias ClientId =
    L.Internal.ClientId


onConnect : (SessionId -> ClientId -> toBackend) -> Sub toBackend
onConnect =
    L.Internal.onConnect


onDisconnect : (SessionId -> ClientId -> toBackend) -> Sub toBackend
onDisconnect =
    L.Internal.onDisconnect


sendToBackend =
    L.Internal.sendToBackend


sendToFrontend =
    L.Internal.sendToFrontend


broadcast =
    L.Internal.broadcast


type alias FrontendProgram frontendModel toFrontend msg =
    L.Internal.FrontendProgram frontendModel toFrontend msg


frontend :
    { init : Url.Url -> Browser.Navigation.Key -> ( frontendModel, Cmd msg )
    , view : frontendModel -> Browser.Document msg
    , update : Time.Posix -> msg -> frontendModel -> ( frontendModel, Cmd msg )
    , updateFromBackend : toFrontend -> frontendModel -> ( frontendModel, Cmd msg )
    , subscriptions : frontendModel -> Sub msg
    , onUrlRequest : Browser.UrlRequest -> msg
    , onUrlChange : Url.Url -> msg
    }
    -> FrontendProgram frontendModel toFrontend msg
frontend =
    L.Internal.frontend


type alias BackendProgram backendModel toBackend backendMsg =
    L.Internal.BackendProgram backendModel toBackend backendMsg


backend :
    { init : ( backendModel, Cmd backendMsg )
    , update : Time.Posix -> backendMsg -> backendModel -> ( backendModel, Cmd backendMsg )
    , updateFromFrontend : SessionId -> ClientId -> toBackend -> backendModel -> ( backendModel, Cmd backendMsg )
    , subscriptions : backendModel -> Sub backendMsg
    }
    -> BackendProgram backendModel toBackend backendMsg
backend =
    L.Internal.backend


type alias SessionDict value =
    L.Internal.SessionDict value


type alias ClientSet =
    L.Internal.ClientSet


sessionIdFromCore : String -> SessionId
sessionIdFromCore =
    L.Internal.newSessionId


sendToClients clientIds toFrontend =
    Cmd.batch <|
        L.Internal.mapClientSet
            (\clientId ->
                sendToFrontend clientId toFrontend
            )
            clientIds
