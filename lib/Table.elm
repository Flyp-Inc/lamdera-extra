module Table exposing (..)

import Dict
import L
import Random
import Task
import Time
import UUID


{-| Represents a "table" semantic, where a "table" is a a dictionary of values that have a unique identity, and a "created at" timestamp.

In a traditional relational database management system, the database engine provides a unique identity and can generate timestamps;
the `Table` type takes responsibility for mediating those operations.

-}
type Table a
    = Table (Dict.Dict String { value : a, createdAt : Time.Posix }) Random.Seed


{-| Create a new `Table`.

Each table contains a `Random.Seed` that is stepped every time you insert a new record, to generate that record's unique identifier.
How you choose to create that `Random.Seed` value is up to you; in a tranditional relational database, it is not uncommon for identities
to be unique at the _table_ level; so if you don't need your record identities to be _globally_ unique, it would be OK to simply use `Random.initialSeed 0`
as the identity for every instance of `Table` in your application.

-}
init : Random.Seed -> Table a
init =
    Table Dict.empty


{-| Insert a record into a `Table`.

It is assumed that you will use this function in your own code to create a `cons` function for each type `a` that is going to be stored in a `Table a`,
by partially applying the `(String -> id)` function. For instance, in a module `User`, here is what that would look like:

    ```
    module User exposing (Id, Record, cons)

    import Table
    import Time

    type Id
        = Id String


    type alias Record =
        { emailAddress : String
        }


    cons : Time.Posix -> Record -> Table Record -> ( { id : Id, value : Record, createdAt : Time.Posix }, Table Record )
    cons =
        Table.cons Id
    ```

The nice thing about using `lamdera-extra` is that since there is always a `Time.Posix` value representing the current timestamp available
in the `update` function in `Backend`, this doesn't have to be wrapped in a `Task` or a `Cmd`.

-}
cons : (String -> id) -> Time.Posix -> a -> Table a -> ( { id : id, value : a, createdAt : Time.Posix }, Table a )
cons toId timestamp value (Table dict seed) =
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
    )
