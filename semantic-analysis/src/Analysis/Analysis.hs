{-# LANGUAGE DeriveFunctor, ExistentialQuantification, RankNTypes, StandaloneDeriving #-}
module Analysis.Analysis
( Analysis(..)
) where

import Data.Text (Text)

-- | A record of functions necessary to perform analysis.
--
-- This is intended to be replaced with a selection of algebraic effects providing these interfaces and carriers providing reusable implementations.
data Analysis term name address value m = Analysis
  { alloc     :: name -> m address
  , bind      :: forall a . name -> address -> m a -> m a
  , lookupEnv :: name -> m (Maybe address)
  , deref     :: address -> m (Maybe value)
  , assign    :: address -> value -> m ()
  , abstract  :: (term name -> m value) -> name -> term name -> m value
  , apply     :: (term name -> m value) -> value -> value -> m value
  , unit      :: m value
  , bool      :: Bool -> m value
  , asBool    :: value -> m Bool
  , string    :: Text -> m value
  , asString  :: value -> m Text
  , record    :: [(name, value)] -> m value
  , (...)     :: address -> name -> m (Maybe address)
  }

data Env name addr m k
  = Alloc name (addr -> m k)
  | forall a . Bind name addr (m a) (a -> m k)
  | Lookup name (Maybe addr -> m k)

deriving instance Functor m => Functor (Env name addr m)

data Heap addr value m k
  = Deref addr (Maybe value -> m k)
  | Assign addr value (m k)
  deriving (Functor)

data Domain term name value m k
  -- Functions construction & elimination
  = Abstract name (term name)                 (value term name -> m k)
  | Apply (value term name) (value term name) (value term name -> m k)
  -- Unit construction (no elimination)
  | Unit (value term name -> m k)
  -- Boolean construction & elimination
  | Bool   Bool              (value term name -> m k)
  | AsBool (value term name) (Bool            -> m k)
  -- String construction & elimination
  | String   Text              (value term name -> m k)
  | AsString (value term name) (Text            -> m k)
  deriving (Functor)