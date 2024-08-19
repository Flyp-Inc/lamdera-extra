module L.SessionDict_ exposing (..)

import Dict
import L.Internal as L
import Lamdera


type alias SessionDict value =
    L.SessionDict_ value


empty : SessionDict value
empty =
    { sessions = Dict.empty
    , clients = Dict.empty
    }


onConnect : value -> Sub (SessionDict value -> SessionDict value)
onConnect default =
    Lamdera.onConnect
        (\sessionId clientId ->
            \{ sessions, clients } ->
                { sessions =
                    Dict.update sessionId
                        (\maybeValue ->
                            Just <| Maybe.withDefault default maybeValue
                        )
                        sessions
                , clients =
                    Dict.insert clientId sessionId clients
                }
        )


onDisconnect : Sub (SessionDict value -> SessionDict value)
onDisconnect =
    Lamdera.onDisconnect
        (\_ clientId ->
            \{ sessions, clients } ->
                { sessions = sessions
                , clients = Dict.remove clientId clients
                }
        )


get : L.ClientId -> SessionDict value -> Maybe value
get clientId { sessions, clients } =
    Dict.get clientId.value clients
        |> Maybe.andThen
            (\sessionId ->
                Dict.get sessionId sessions
            )


update : L.ClientId -> value -> SessionDict value -> SessionDict value
update clientId value ({ sessions, clients } as sessionDict) =
    Dict.get clientId.value clients
        |> Maybe.map
            (\sessionId ->
                { sessions =
                    Dict.update sessionId
                        (\maybeValue ->
                            Just <| Maybe.withDefault value maybeValue
                        )
                        sessions
                , clients = clients
                }
            )
        |> Maybe.withDefault sessionDict


filter : (value -> Bool) -> SessionDict value -> SessionDict value
filter func { sessions, clients } =
    { sessions =
        Dict.filter (\_ value -> func value) sessions
    , clients = clients
    }
