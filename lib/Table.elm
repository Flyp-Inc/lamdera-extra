module Table exposing
    ( Table, init
    , Config, define
    , Index, toIndex, withIndex
    , cons, update, delete
    , getById
    )

{-| Represents a "table" semantic, where a "table" is a a dictionary of values that have a unique identity, and a "created at" timestamp.

In a traditional relational database management system, the database engine provides a unique identity and can generate timestamps;
the `Table` type takes responsibility for mediating those operations.


# Type

@docs Table, init


# Configuration

@docs Config, define

@docs Index, toIndex, withIndex


# Commands

@docs cons, update, delete


# Queries

@docs getById

-}

import Dict
import L
import Murmur3
import Random
import Task
import Time
import UUID


{-| Opaque type representing a "table".
-}
type Table a
    = Table
        { dict : Dict.Dict String { value : a, createdAt : Time.Posix }
        , seed : Random.Seed
        , deleted : Dict.Dict String { value : a, deletedAt : Time.Posix }
        , index : Dict.Dict Int (List String)
        }


{-| Create a new `Table`.

Each table contains a `Random.Seed` that is stepped every time you insert a new record, to generate that record's unique identifier.
How you choose to create that `Random.Seed` value is up to you; in a tranditional relational database, it is not uncommon for identities
to be unique at the _table_ level; so if you don't need your record identities to be _globally_ unique, it would be OK to simply use `Random.initialSeed 0`
as the identity for every instance of `Table` in your application.

-}
init : Random.Seed -> Table a
init seed =
    Table
        { dict = Dict.empty
        , seed = seed
        , deleted = Dict.empty
        , index = Dict.empty
        }


{-| Represent configuration details for a table.

Internally, configuration is:

    - A mapping between a `String` and the ID type for your table
    - A representation of any indexes

-}
type Config id a
    = Config (String -> id) (List (Index a))


{-| Define a table's configuration.

The minimum-required configuration for a table is "a mapping between a `String` and an ID type". ID values are represented interally as a `String`, so
the path-of-least-resistance here is to just use the `identity` function; but for a tiny bit more effort, you can have an `Id` type that is unique to your table -
and that makes your code quite a bit easier to read, and it gives the compiler more information so that it can keep you from accidentally using the `String`-value of
a row's ID for the wrong thing!

Here's what this could look like:

    ```
    module User exposing (..)

    import Table

    type alias Record =
        { emailAddress : String }

    type Id
        = Id String

    config : Table.Config Id Record
    config =
        Table.define Id
    ```

-}
define : (String -> id) -> Config id a
define toId =
    Config toId []


{-| Represent an index for a table.

Internally, an index is:

    - A unique identifier (i.e., the index name)
    - A map between a property on an `a` and an `Int`

When you _query_ a table, you query it by its indexes. This doesn't mean that you need to create an index for every column! The columns
that you should create indexes for are the columns that will help you identify a record, or identify a group of records by some column that
is a member of a smaller set compared to other columns.

Consider the following:

    ```
    module User exposing (..)

    import Table

    type alias Record =
        { emailAddress : String
        , catchphrase : String
        , role : Role
        }

    type Role
        = Admin
        | Member
    ```

If we need to run queries against `User.Record` to find all users that are `Admin` users, it would make sense to create an index on the `.role`
column, because the `Role` type is a member of a set that only has two values - `Admin` or `Member`. It wouldn't make much sense to create an index
on the `.catchphrase` column - since that column is likely going to be unique for each user, anyway - so if we really needed to do a query against
the `.catchphrase` column, we would have to consider every record separately, no matter what.

-}
type Index a
    = Index (a -> Int)


{-| Create an `Index a` by providing a unique name for the column being indexed, and a string representation of that column's value.

For example:

    ```
    module User exposing (..)

    import Table


    type alias Record =
        { emailAddress : String
        , catchphrase : String
        , role : Role
        }


    type Role
        = Admin
        | Member


    idxRole : Table.Index Record
    idxRole =
        Table.toIndex "Role"
            (\role ->
                case role of
                    Admin ->
                        "Admin"

                    Member ->
                        "Member"
            )
    ```

This is handled as a separate operation from `withIndex`, since you will need to have an `Index a` value to use as a parameter for your query.

-}
toIndex : String -> (a -> String) -> Index a
toIndex name accessor =
    let
        hashSeed : Int
        hashSeed =
            Murmur3.hashString 0 name
    in
    Index (\value -> Murmur3.hashString hashSeed (accessor value))


{-| Add an `Index a` to a `Table a`.

    ```
    module User exposing (..)

    import Table

    type alias Record =
        { emailAddress : String
        , role : Role
        }


    type Id
        = Id String

    type Role
        = Admin
        | Member


    idxRole : Table.Index Record
    idxRole =
        Table.toIndex "Role"
            (\role ->
                case role of
                    Admin ->
                        "Admin"

                    Member ->
                        "Member"
            )

    config : Table.Config Id Record
    config =
        Table.define Id
            |> Table.withIndex idxRole
    ```

-}
withIndex : Index a -> Config id a -> Config id a
withIndex idx (Config toId indexes) =
    Config toId <| idx :: indexes


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
cons toId timestamp value (Table table) =
    let
        ( uuid, newSeed ) =
            Random.step UUID.generator table.seed

        internalId : String
        internalId =
            UUID.toString uuid
    in
    ( { id = toId internalId
      , value = value
      , createdAt = timestamp
      }
    , Table
        { table
            | dict =
                Dict.insert internalId
                    { value = value
                    , createdAt = timestamp
                    }
                    table.dict
            , seed = newSeed
            , index = Debug.todo ""
        }
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
update id timestamp value (Table table) =
    Table
        { table
            | dict = Dict.insert id { value = value, createdAt = timestamp } table.dict
            , index = Debug.todo ""
        }


{-| Delete a record from a `Table`.
-}
delete : (id -> String) -> Time.Posix -> id -> Table a -> Table a
delete toId timestamp id ((Table table) as table_) =
    let
        id_ : String
        id_ =
            toId id
    in
    case Dict.get id_ table.dict of
        Just { value } ->
            Table
                { table
                    | dict = Dict.remove id_ table.dict
                    , index = Debug.todo ""
                    , deleted = Dict.insert id_ { value = value, deletedAt = timestamp } table.deleted
                }

        Nothing ->
            table_


{-| Get a value by its `id`.
-}
getById : (id -> String) -> id -> Table a -> Maybe { value : a, createdAt : Time.Posix }
getById toId id (Table table) =
    Dict.get (toId id) table.dict
