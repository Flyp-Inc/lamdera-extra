module L.ClientSet exposing (ClientId, ClientSet, empty, fromList, insert, isEmpty, map, member, remove, singleton, toList)

import L.Internal as L
import Set


type alias ClientSet =
    L.ClientSet


type alias ClientId =
    L.ClientId


empty : ClientSet
empty =
    Set.empty


isEmpty : ClientSet -> Bool
isEmpty =
    Set.isEmpty


insert : ClientId -> ClientSet -> ClientSet
insert id =
    Set.insert id.value


remove : ClientId -> ClientSet -> ClientSet
remove id =
    Set.remove id.value


toList : ClientSet -> List ClientId
toList =
    L.toListClientSet


fromList : List ClientId -> ClientSet
fromList =
    List.map .value >> Set.fromList


member : ClientId -> ClientSet -> Bool
member id =
    Set.member id.value


singleton : ClientId -> ClientSet
singleton id =
    Set.singleton id.value


map : (ClientId -> a) -> ClientSet -> List a
map =
    L.mapClientSet
