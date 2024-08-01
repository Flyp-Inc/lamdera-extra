module L exposing
    ( SessionId, ClientId
    , FrontendApplication, frontend
    , BackendApplication, backend
    , sendToBackend, sendToFrontend, onConnect, onDisconnect, broadcast, sendToClients
    , SessionDict, ClientSet
    )

{-| You don't `import Lamdera` anymore; you just `import L`.

@docs SessionId, ClientId

@docs FrontendApplication, frontend

@docs BackendApplication, backend

@docs sendToBackend, sendToFrontend, onConnect, onDisconnect, broadcast, sendToClients

@docs SessionDict, ClientSet

-}

import Browser
import Browser.Navigation
import L.Internal
import Time
import Url


{-| Typesafe drop-in replacement for `Lamdera.SessionId`
-}
type alias SessionId =
    L.Internal.SessionId


{-| Typesafe drop-in replacement for `Lamdera.ClientId`
-}
type alias ClientId =
    L.Internal.ClientId


{-| `L.`-namespaced implementation of `Lamdera.sendToBackend`
-}
sendToBackend =
    L.Internal.sendToBackend


{-| `L.`-namespaced implementation of `Lamdera.sendToFrontend` that uses a `L.ClientId` instead of a `Lamdera.ClientId`
-}
sendToFrontend =
    L.Internal.sendToFrontend


{-| `L.`-namespaced implementation of `Lamdera.onConnect` that uses `L.SessionId` and `L.ClientId`
-}
onConnect : (SessionId -> ClientId -> toBackend) -> Sub toBackend
onConnect =
    L.Internal.onConnect


{-| `L.`-namespaced implementation of `Lamdera.onDisconnect` that uses `L.SessionId` and `L.ClientId`
-}
onDisconnect : (SessionId -> ClientId -> toBackend) -> Sub toBackend
onDisconnect =
    L.Internal.onDisconnect


{-| `L.`-namespaced implementation of `Lamdera.broadcast`
-}
broadcast =
    L.Internal.broadcast


{-| Like `Lamdera.broadcast`, but only for a certain subset of connected clients; useful if you want to - for instance - push authentication state
to all connected clients for a given session
-}
sendToClients clientIds toFrontend =
    Cmd.batch <|
        L.Internal.mapClientSet
            (\clientId ->
                sendToFrontend clientId toFrontend
            )
            clientIds


{-| Type signature for a frontend application
-}
type alias FrontendApplication toFrontend model msg =
    L.Internal.FrontendApplication toFrontend model msg


{-| Wrapper for `Lamdera.frontend` that automatically implements getting a timestamp for each `Msg` that is processed
-}
frontend :
    { init : Url.Url -> Browser.Navigation.Key -> ( model, Cmd msg )
    , view : model -> Browser.Document msg
    , update : Time.Posix -> msg -> model -> ( model, Cmd msg )
    , updateFromBackend : toFrontend -> model -> ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    , onUrlRequest : Browser.UrlRequest -> msg
    , onUrlChange : Url.Url -> msg
    }
    -> FrontendApplication toFrontend model msg
frontend =
    L.Internal.frontend


{-| Type signature for a backend application
-}
type alias BackendApplication toBackend bodel bsg =
    L.Internal.BackendApplication toBackend bodel bsg


{-| Wrapper for `Lamdera.Backend` that automatically implements getting a timestamp for each `Bsg` that is processed
-}
backend :
    { init : ( bodel, Cmd bsg )
    , update : Time.Posix -> bsg -> bodel -> ( bodel, Cmd bsg )
    , updateFromFrontend : SessionId -> ClientId -> toBackend -> bodel -> ( bodel, Cmd bsg )
    , subscriptions : bodel -> Sub bsg
    }
    -> BackendApplication toBackend bodel bsg
backend =
    L.Internal.backend


{-| A dictionary whose key is a `L.SessionId`
-}
type alias SessionDict value =
    L.Internal.SessionDict value


{-| A set of values with type `L.ClientId`
-}
type alias ClientSet =
    L.Internal.ClientSet
