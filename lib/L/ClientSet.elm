module L.ClientSet exposing
    ( ClientId
    , ClientSet
    , empty, isEmpty
    , insert, remove
    , toList, fromList, member, singleton
    , map
    )

{-| Set operations for `L.ClientId`.

@docs ClientId

@docs ClientSet

@docs empty, isEmpty

@docs insert, remove

@docs toList, fromList, member, singleton

@docs map

-}

import L.Internal as L
import Set


{-| -}
type alias ClientSet =
    L.ClientSet


{-| -}
type alias ClientId =
    L.ClientId


{-| -}
empty : ClientSet
empty =
    Set.empty


{-| -}
isEmpty : ClientSet -> Bool
isEmpty =
    Set.isEmpty


{-| -}
insert : ClientId -> ClientSet -> ClientSet
insert id =
    Set.insert id.value


{-| -}
remove : ClientId -> ClientSet -> ClientSet
remove id =
    Set.remove id.value


{-| -}
toList : ClientSet -> List ClientId
toList =
    L.toListClientSet


{-| -}
fromList : List ClientId -> ClientSet
fromList clientIds =
    List.map .value clientIds |> Set.fromList


{-| -}
member : ClientId -> ClientSet -> Bool
member id =
    Set.member id.value


{-| -}
singleton : ClientId -> ClientSet
singleton id =
    Set.singleton id.value


{-| -}
map : (ClientId -> a) -> ClientSet -> List a
map =
    L.mapClientSet
