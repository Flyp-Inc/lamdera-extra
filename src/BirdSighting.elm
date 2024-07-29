module BirdSighting exposing (..)

import Col
import Table
import Time
import Types as App


type alias Record =
    { species : String
    , location : String
    }


type alias Table =
    Table.Table Record


config : Table.Config Id Record
config =
    Table.define Id (\(Id i) -> i)


type Id
    = Id String


specSpecies : Table.Spec Record String
specSpecies =
    Table.toIndex "Species" .species identity


cons : Time.Posix -> Record -> Table -> ( { id : Id, value : Record, createdAt : Time.Posix }, Table )
cons =
    Table.cons config
