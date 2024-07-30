module L.SessionDict exposing (SessionDict, empty, filter, get, insert, remove, update)

import Dict
import L.Internal as L


type alias SessionDict value =
    L.SessionDict value


insert : L.SessionId -> value -> SessionDict value -> SessionDict value
insert id =
    Dict.insert id.value


update : L.SessionId -> (Maybe value -> Maybe value) -> SessionDict value -> SessionDict value
update id =
    Dict.update id.value


get : L.SessionId -> SessionDict value -> Maybe value
get id =
    Dict.get id.value


remove : L.SessionId -> SessionDict value -> SessionDict value
remove id =
    Dict.remove id.value


empty : SessionDict value
empty =
    Dict.empty


filter : (value -> Bool) -> L.SessionDict value -> L.SessionDict value
filter func =
    Dict.filter (\_ value -> func value)
