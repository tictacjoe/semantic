{-# LANGUAGE KindSignatures, LambdaCase, TypeOperators, UndecidableInstances #-}

module Control.Effect.REPL
  ( REPL (..)
  , REPLC (..)
  , prompt
  , output
  , runREPL
  ) where

import Prologue

import Control.Effect
import Control.Effect.Carrier
import Control.Effect.Sum
import System.Console.Haskeline
import qualified Data.Text as T

data REPL (m :: * -> *) k
  = Prompt Text (Maybe Text -> k)
  | Output Text k
  deriving (Functor)

instance HFunctor REPL where
  hmap _ = coerce

instance Effect REPL where
  handle state handler (Prompt p k) = Prompt p (handler . (<$ state) . k)
  handle state handler (Output s k) = Output s (handler (k <$ state))

prompt :: (Member REPL sig, Carrier sig m) => Text -> m (Maybe Text)
prompt p = send (Prompt p ret)

output :: (Member REPL sig, Carrier sig m) => Text -> m ()
output s = send (Output s (ret ()))

runREPL :: (MonadIO m, Carrier sig m) => Prefs -> Settings IO -> REPLC m a -> m a
runREPL prefs settings = flip runREPLC (prefs, settings) . interpret

newtype REPLC m a = REPLC { runREPLC :: (Prefs, Settings IO) -> m a }

instance (Carrier sig m, MonadIO m) => Carrier (REPL :+: sig) (REPLC m) where
  eff (L (Prompt p k)) = REPLC (liftIO (uncurry runInputTWithPrefs args (fmap (fmap T.pack) (getInputLine (cyan <> T.unpack p <> plain)))) >>= k)
  eff (L (Output s k)) = REPLC (liftIO (uncurry runInputTWithPrefs args (outputStrLn (T.unpack s))) *> k)
  eff (R other)        = REPLC (eff (handleCoercible other))


cyan :: String
cyan = "\ESC[1;36m\STX"

plain :: String
plain = "\ESC[0m\STX"
