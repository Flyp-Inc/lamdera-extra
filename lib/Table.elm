module Table exposing
    ( Table
    , init, cons, update, delete
    , getById
    )

{-| Represents a "table" semantic, where a "table" is a a dictionary of values that have a unique identity, and a "created at" timestamp.

In a traditional relational database management system, the database engine provides a unique identity and can generate timestamps;
the `Table` type takes responsibility for mediating those operations.


# Type

@docs Table


# Commands

@docs init, cons, update, delete


# Queries

@docs getById

-}

import Dict
import L
import Random
import Task
import Time
import UUID


{-| Opaque type representing a "table".
-}
type Table a
    = Table (Dict.Dict String { value : a, createdAt : Time.Posix }) Random.Seed (Dict.Dict String { value : a, deletedAt : Time.Posix })


{-| Create a new `Table`.

Each table contains a `Random.Seed` that is stepped every time you insert a new record, to generate that record's unique identifier.
How you choose to create that `Random.Seed` value is up to you; in a tranditional relational database, it is not uncommon for identities
to be unique at the _table_ level; so if you don't need your record identities to be _globally_ unique, it would be OK to simply use `Random.initialSeed 0`
as the identity for every instance of `Table` in your application.

-}
init : Random.Seed -> Table a
init seed =
    Table Dict.empty
        seed
        Dict.empty


{-| Insert a record into a `Table`.

It is assumed that you will use this function in your own code to create a `cons` function for each type `a` that is going to be stored in a `Table a`,
by partially applying the `(String -> id)` function. For instance, in a module `User`, here is what that would look like:

    ```
    module User exposing (Id, Record, cons)

    import Table
    import Time

    type Id
        = Id String


    type alias Table =
        Table.Table Record

    type alias Record =
        { emailAddress : String
        }


    cons : Time.Posix -> Record -> Table -> ( { id : Id, value : Record, createdAt : Time.Posix }, Table )
    cons =
        Table.cons Id
    ```

The nice thing about using `lamdera-extra` is that since there is always a `Time.Posix` value representing the current timestamp available
in the `update` function in `Backend`, this doesn't have to be wrapped in a `Task` or a `Cmd`.

-}
cons : (String -> id) -> Time.Posix -> a -> Table a -> ( { id : id, value : a, createdAt : Time.Posix }, Table a )
cons toId timestamp value (Table dict seed deleted) =
    let
        ( uuid, newSeed ) =
            Random.step UUID.generator seed

        internalId : String
        internalId =
            UUID.toString uuid
    in
    ( { id = toId internalId
      , value = value
      , createdAt = timestamp
      }
    , Table
        (Dict.insert internalId
            { value = value
            , createdAt = timestamp
            }
            dict
        )
        newSeed
        deleted
    )


{-| Update a record in a `Table`.

It is assumed that you will use this function in your own code to create an `update` function for each type `a` that is going to be stored in a `Table a`,
by partially applying the `String` value. For instance, in a module `User`, here is what that would look like:

    ```
    module User exposing (Id, Record, cons)

    import Table
    import Time

    type Id
        = Id String


    type alias Table =
        Table.Table Record


    type alias Record =
        { emailAddress : String
        }


    update : Id -> Time.Posix -> Record -> Table -> Table
    update (Id id) =
        Table.update id
    ```

The `Table a` type doesn't track "updated at", since it's assumed that if you care about that, you will wrap each column whose "updated at" time is meaningful in a `Col a`.

`update` doesn't return a tuple of the updated record and the updated table; `cons` only returns a tuple because `cons` is responsible for creating the `id` value.

-}
update : String -> Time.Posix -> a -> Table a -> Table a
update id timestamp value (Table dict seed deleted) =
    Table (Dict.insert id { value = value, createdAt = timestamp } dict) seed deleted


{-| Delete a record from a `Table`.
-}
delete : (id -> String) -> Time.Posix -> id -> Table a -> Table a
delete toId timestamp id ((Table dict seed deleted) as table) =
    let
        id_ : String
        id_ =
            toId id
    in
    case Dict.get id_ dict of
        Just { value } ->
            Table
                (Dict.remove id_ dict)
                seed
                (Dict.insert id_ { value = value, deletedAt = timestamp } deleted)

        Nothing ->
            table


{-| Get a value by its `id`.
-}
getById : (id -> String) -> id -> Table a -> Maybe { value : a, createdAt : Time.Posix }
getById toId id (Table dict _ _) =
    Dict.get (toId id) dict
