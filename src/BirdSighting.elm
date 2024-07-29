module BirdSighting exposing (..)

import Col
import Table
import Time


type alias Record =
    { species : String
    , location : String
    }


type alias Table =
    Table.Table Record


config : Table.Config Id Record
config =
    Table.define Id (\(Id i) -> i)
        |> Table.withIndex specSpecies.index


type Id
    = Id String


specSpecies : Table.Spec Record String
specSpecies =
    Table.toSpec "Species" .species identity


cons : Time.Posix -> Record -> Table -> ( { id : Id, value : Record, createdAt : Time.Posix }, Table )
cons =
    Table.cons config
