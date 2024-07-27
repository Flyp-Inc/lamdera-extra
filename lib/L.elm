module L exposing (BackendProgram, ClientId, ClientSet, FrontendProgram, SessionDict, SessionId, backend, broadcast, frontend, onConnect, onDisconnect, sendToBackend, sendToClients, sendToFrontend, sessionIdFromCore)

import Browser
import Browser.Navigation
import L.Internal
import Time
import Url


type alias IO =
    { timestamp : Time.Posix
    , seed : Random.Seed
    }


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


type alias FrontendProgram model toFrontend frontendMsg =
    L.Internal.FrontendProgram model toFrontend frontendMsg


frontend :
    { init : Url.Url -> Browser.Navigation.Key -> ( model, Cmd frontendMsg )
    , view : model -> Browser.Document frontendMsg
    , update : frontendMsg -> model -> ( model, Cmd frontendMsg )
    , updateFromBackend : toFrontend -> model -> ( model, Cmd frontendMsg )
    , subscriptions : model -> Sub frontendMsg
    , onUrlRequest : Browser.UrlRequest -> frontendMsg
    , onUrlChange : Url.Url -> frontendMsg
    }
    -> FrontendProgram model toFrontend frontendMsg
frontend =
    L.Internal.frontend


type alias BackendProgram backendModel toBackend backendMsg =
    L.Internal.BackendProgram backendModel toBackend backendMsg


backend :
    { init : ( backendModel, Cmd backendMsg )
    , update : backendMsg -> backendModel -> ( backendModel, Cmd backendMsg )
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
