{-# LANGUAGE FlexibleContexts, RankNTypes, RecordWildCards, ScopedTypeVariables, TypeApplications #-}
module Analysis.ImportGraph
( ImportGraph
, importGraph
, importGraphAnalysis
) where

import           Analysis.Analysis
import           Analysis.File
import           Analysis.FlowInsensitive
import           Control.Applicative (Alternative(..))
import           Control.Algebra
import           Control.Carrier.Fail.WithLoc
import           Control.Carrier.Fresh.Strict
import           Control.Carrier.Reader
import           Control.Carrier.State.Strict
import           Control.Monad ((>=>))
import           Data.Foldable (fold, for_)
import           Data.Function (fix)
import           Data.List.NonEmpty (nonEmpty)
import qualified Data.Map as Map
import           Data.Proxy
import qualified Data.Set as Set
import           Data.Text (Text)
import           Prelude hiding (fail)
import           Source.Span
import qualified System.Path as Path

type ImportGraph = Map.Map Text (Set.Set Text)

data Value term name = Value
  { valueSemi  :: Semi term name
  , valueGraph :: ImportGraph
  }
  deriving (Eq, Ord, Show)

instance Semigroup (Value term name) where
  Value _ g1 <> Value _ g2 = Value Abstract (Map.unionWith (<>) g1 g2)

instance Monoid (Value term name) where
  mempty = Value Abstract mempty

data Semi term name
  = Closure Path.AbsRelFile Span name (term name)
  -- FIXME: Bound String values.
  | String Text
  | Abstract
  deriving (Eq, Ord, Show)


importGraph
  :: (Ord name, Ord (term name), Show name, Show (term name))
  => (forall sig m
     .  (Has (Reader Path.AbsRelFile) sig m, Has (Reader Span) sig m, MonadFail m)
     => Analysis term name name (Value term name) m
     -> (term name -> m (Value term name))
     -> (term name -> m (Value term name))
     )
  -> [File (term name)]
  -> ( Heap name (Value term name)
     , [File (Either (Path.AbsRelFile, Span, String) (Value term name))]
     )
importGraph eval
  = run
  . evalFresh 0
  . runHeap
  . traverse (runFile eval)

runFile
  :: forall term name m sig
  .  ( Effect sig
     , Has Fresh sig m
     , Has (State (Heap name (Value term name))) sig m
     , Ord  name
     , Ord  (term name)
     , Show name
     , Show (term name)
     )
  => (forall sig m
     .  (Has (Reader Path.AbsRelFile) sig m, Has (Reader Span) sig m, MonadFail m)
     => Analysis term name name (Value term name) m
     -> (term name -> m (Value term name))
     -> (term name -> m (Value term name))
     )
  -> File (term name)
  -> m (File (Either (Path.AbsRelFile, Span, String) (Value term name)))
runFile eval file = traverse run file
  where run = runReader (filePath file)
            . runReader (fileSpan file)
            . runFail
            . fmap fold
            . convergeTerm (Proxy @name) 0 (fix (cacheTerm . eval importGraphAnalysis))

-- FIXME: decompose into a product domain and two atomic domains
importGraphAnalysis :: ( Alternative m
                       , Has (Reader Path.AbsRelFile) sig m
                       , Has (Reader Span) sig m
                       , Has (State (Heap name (Value term name))) sig m
                       , MonadFail m
                       , Ord  name
                       , Ord  (term name)
                       , Show name
                       , Show (term name)
                       )
                    => Analysis term name name (Value term name) m
importGraphAnalysis = Analysis{..}
  where alloc = pure
        bind _ _ m = m
        lookupEnv = pure . Just
        deref addr = gets (Map.lookup addr >=> nonEmpty . Set.toList) >>= maybe (pure Nothing) (foldMapA (pure . Just))
        assign addr v = modify (Map.insertWith (<>) addr (Set.singleton v))
        abstract _ name body = do
          path <- ask
          span <- ask
          pure (Value (Closure path span name body) mempty)
        apply eval (Value (Closure path span name body) _) a = local (const path) . local (const span) $ do
          addr <- alloc name
          assign addr a
          bind name addr (eval body)
        apply _ f _ = fail $ "Cannot coerce " <> show f <> " to function"
        unit = pure mempty
        bool _ = pure mempty
        asBool _ = pure True <|> pure False
        string s = pure (Value (String s) mempty)
        asString (Value (String s) _) = pure s
        asString _ = pure mempty
        record fields = do
          for_ fields $ \ (k, v) -> do
            addr <- alloc k
            assign addr v
          pure (Value Abstract (foldMap (valueGraph . snd) fields))
        _ ... m = pure (Just m)
