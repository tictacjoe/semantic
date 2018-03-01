{-# LANGUAGE RankNTypes #-}
module Data.Algebra
( FAlgebra
, RAlgebra
, OpenFAlgebra
, OpenRAlgebra
, Subterm(..)
, SubtermAlgebra
, foldSubterms
, fToR
, fToOpenR
, rToOpenR
, openFToOpenR
) where

import Data.Functor.Foldable (Base, Recursive(project))

-- | An F-algebra on some 'Recursive' type @t@.
--
--   An F-algebra is an evaluator for a functor (@f@) populated with the results (@a@s) of evaluating each child of the functor to a result (@a@), applied at each node starting from the leaves and working towards the root. @a@ is called the carrier type of the algebra because it carries the (results of the) functions used to compute the functor’s structure and enforce the laws of that algebra.
type FAlgebra f a = f a -> a

-- | An R-algebra on some 'Recursive' type @t@.
--
--   An R-algebra is an evaluator for a functor (@f@) populated with pairs of the children (@t@) and the results (@a@s) of evaluating each child of the functor to a result (@a@), applied at each node starting from the leaves and working towards the root.
--
--   See also 'FAlgebra'.
type RAlgebra f t a = f (t, a) -> a

-- | An open-recursive F-algebra on some 'Recursive' type @t@.
--
--   The recursion is “open” because instead of being applied from the leaves towards the root like a regular 'FAlgebra', the functor (@f@) is populated with the original values (@b@), and each is evaluated via the continuation (@(b -> a)@).
--
--   See also 'FAlgebra'.
type OpenFAlgebra f a = forall b . (b -> a) -> f b -> a

-- | An open-recursive R-algebra on some 'Recursive' type @t@.
--
--   See also 'RAlgebra' & 'OpenFAlgebra'.
type OpenRAlgebra f t a = forall b . (b -> (t, a)) -> f b -> a

-- | A subterm and its computed value, used in 'SubtermAlgebra'.
data Subterm t a = Subterm { subterm :: !t, subtermValue :: !a }

-- | Like an R-algebra, but using 'Subterm' to label the fields instead of an anonymous pair.
type SubtermAlgebra f t a = f (Subterm t a) -> a


-- | Fold a 'Recursive' structure using a 'SubtermAlgebra'. Like 'para', but with named fields for subterms and values.
foldSubterms :: Recursive t => SubtermAlgebra (Base t) t a -> t -> a
foldSubterms algebra = go where go = algebra . fmap (Subterm <*> go) . project


-- | Promote an 'FAlgebra' into an 'RAlgebra' (by dropping the original parameter).
fToR :: Functor (Base t) => FAlgebra (Base t) a -> RAlgebra (Base t) t a
fToR f = f . fmap snd

-- | Promote an 'FAlgebra' into an 'OpenRAlgebra' (by 'fmap'ing the action over the structure and dropping the original parameter).
fToOpenR :: Functor (Base t) => FAlgebra (Base t) a -> OpenRAlgebra (Base t) t a
fToOpenR alg f = alg . fmap (snd . f)

-- | Promote an 'RAlgebra' into an 'OpenRAlgebra' (by 'fmap'ing the action over the structure).
rToOpenR :: Functor f => RAlgebra f t a -> OpenRAlgebra f t a
rToOpenR alg f = alg . fmap f

-- | Promote an 'OpenFAlgebra' into an 'OpenRAlgebra' (by dropping the original parameter).
openFToOpenR :: OpenFAlgebra (Base t) a -> OpenRAlgebra (Base t) t a
openFToOpenR alg = alg . fmap snd