module L.SessionDict exposing (SessionDict, empty, filter, get, handleOnConnect, handleOnDisconnect, update)

import Dict
import L.Internal as L
import Lamdera


type alias SessionDict value =
    L.SessionDict value


empty : SessionDict value
empty =
    { sessions = Dict.empty
    , clients = Dict.empty
    }


handleOnConnect : value -> L.SessionId -> L.ClientId -> SessionDict value -> ( value, SessionDict value )
handleOnConnect default sessionId clientId dict =
    (\updatedDict ->
        ( Dict.get sessionId.value updatedDict.sessions
            |> Maybe.withDefault default
        , updatedDict
        )
    )
    <|
        { sessions =
            Dict.update sessionId.value
                (\maybeValue ->
                    Just <| Maybe.withDefault default maybeValue
                )
                dict.sessions
        , clients =
            Dict.insert clientId.value sessionId.value dict.clients
        }


handleOnDisconnect : L.ClientId -> SessionDict value -> SessionDict value
handleOnDisconnect clientId dict =
    { sessions = dict.sessions
    , clients = Dict.remove clientId.value dict.clients
    }


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
                    Dict.insert sessionId value sessions
                , clients = Dict.insert clientId.value sessionId clients
                }
            )
        |> Maybe.withDefault sessionDict


filter : (value -> Bool) -> SessionDict value -> SessionDict value
filter func { sessions, clients } =
    { sessions =
        Dict.filter (\_ value -> func value) sessions
    , clients = clients
    }
