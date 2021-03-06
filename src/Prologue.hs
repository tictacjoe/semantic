{-# LANGUAGE UndecidableInstances #-}
module Prologue
  ( module X
  , eitherM
  , maybeM
  , maybeLast
  , fromMaybeLast
  ) where


import Data.Bifunctor.Join as X
import Data.Bits as X
import Data.ByteString as X (ByteString)
import Data.Coerce as X
import Data.Either as X (fromLeft, fromRight)
import Data.Int as X (Int16, Int32, Int64, Int8)
import Data.IntMap as X (IntMap)
import Data.IntSet as X (IntSet)
import Data.Ix as X (Ix (..))
import Data.List.NonEmpty as X (NonEmpty (..), nonEmpty, some1)
import Data.Map as X (Map)
import Data.Maybe as X
import Data.Semilattice.Lower as X (Lower (..))
import Data.Sequence as X (Seq)
import Data.Set as X (Set)
import Data.Sum as X ((:<), (:<:), Apply (..), Element, Elements, Sum, inject)
import Data.Text as X (Text)
import Data.Word as X (Word16, Word32, Word64, Word8)
import Debug.Trace as X (traceM, traceShowM)

import Control.Exception as X hiding (Handler (..), assert, evaluate, throw, throwIO, throwTo)

-- Typeclasses
import Control.Applicative as X
import Control.Arrow as X ((&&&), (***))
import Control.Effect.NonDet as X (foldMapA)
import Control.Monad as X hiding (fail, return)
import Control.Monad.Fail as X (MonadFail (..))
import Control.Monad.IO.Class as X (MonadIO (..))
import Data.Algebra as X
import Data.Bifoldable as X
import Data.Bifunctor as X (Bifunctor (..))
import Data.Bitraversable as X
import Data.Foldable as X hiding (product, sum)
import Data.Function as X (fix, on, (&))
import Data.Functor as X (($>))
import Data.Functor.Classes as X
import Data.Functor.Classes.Generic as X
import Data.Functor.Foldable as X (Base, Corecursive (..), Recursive (..))
import Data.Hashable as X (Hashable, hash, hashUsing, hashWithSalt)
import Data.Hashable.Lifted as X (Hashable1 (..), hashWithSalt1)
import Data.Monoid as X (First (..), Last (..), Monoid (..))
import Data.Monoid.Generic as X
import Data.Proxy as X (Proxy (..))
import Data.Semigroup as X (Semigroup (..))
import Data.Traversable as X
import Data.Typeable as X (Typeable)

-- Generics
import GHC.Generics as X (Generic, Generic1)
import GHC.Stack as X

maybeLast :: Foldable t => b -> (a -> b) -> t a -> b
maybeLast b f = maybe b f . getLast . foldMap (Last . Just)

fromMaybeLast :: Foldable t => a -> t a -> a
fromMaybeLast b = fromMaybe b . getLast . foldMap (Last . Just)

-- | Extract the 'Just' of a 'Maybe' in an 'Applicative' context or, given 'Nothing', run the provided action.
maybeM :: Applicative f => f a -> Maybe a -> f a
maybeM f = maybe f pure
{-# INLINE maybeM #-}

-- Promote a function to either-applicatives.
eitherM :: Applicative f => (a -> f b) -> Either a b -> f b
eitherM f = either f pure
{-# INLINE eitherM #-}
