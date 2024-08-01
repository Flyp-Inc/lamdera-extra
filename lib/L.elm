module L exposing (ClientId, ClientSet, SessionDict, SessionId, backend, frontend, sendToBackend, sendToFrontend)

import L.Internal


type alias SessionId =
    L.Internal.SessionId


type alias ClientId =
    L.Internal.ClientId


sendToBackend =
    L.Internal.sendToBackend


sendToFrontend =
    L.Internal.sendToFrontend


frontend =
    L.Internal.frontend


backend =
    L.Internal.backend


type alias SessionDict value =
    L.Internal.SessionDict value


type alias ClientSet =
    L.Internal.ClientSet
