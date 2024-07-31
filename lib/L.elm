module L exposing (..)

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


frontend =
    L.Internal.frontend


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
