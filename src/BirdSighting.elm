module BirdSighting exposing (..)

import Col
import Table
import Time
import Types as App


type alias Record =
    { species : String
    , location : Col.Col String
    }


type alias Table =
    Table.Table Record


type Id
    = Id String


cons : Time.Posix -> Record -> Table -> ( { id : Id, value : Record, createdAt : Time.Posix }, Table )
cons =
    Table.cons Id
