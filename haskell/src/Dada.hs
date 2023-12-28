module Dada where

import Control.Arrow
import qualified Data.HashMap.Strict.InsOrd as H
import qualified Dhall as D
import qualified Dhall.Core as D
import qualified Yaya.Fold as Y

-- | This is the key to a Dhall runtime – `Nu` is the one thing that can’t be
--   normalized away.
corecursive :: (Y.Corecursive t f) => D.Type (a -> f a) -> D.Type a -> D.Type t
corecursive ψ a =
  D.Type
    ( \case
        D.RecordLit fields ->
          Y.ana
            <$> (D.extract ψ =<< H.lookup "coalgebra" fields)
            <*> (D.extract a =<< H.lookup "seed" fields)
        _ -> Nothing
    )
    (D.Record (H.fromList [("coalgebra", D.expected ψ), ("seed", D.expected a)]))

instance
  (Y.Corecursive t f, D.Interpret (a -> f a), D.Interpret a) =>
  D.Interpret t
  where
  autoWith = uncurry corecursive . (autoWith &&& autoWith)
