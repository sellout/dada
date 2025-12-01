{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE Trustworthy #-}
{-# LANGUAGE TypeApplications #-}

module Dada
  ( corecursive,
    corecursiveAutoWith,
  )
where

import safe "base" Control.Applicative ((<*>))
import safe "base" Control.Arrow ((&&&))
import safe "base" Control.Category ((.))
import safe "base" Data.Function (($))
import safe "base" Data.Functor ((<$>))
import safe "base" Data.Maybe (maybe)
import safe "base" Data.Proxy (Proxy (Proxy))
import safe "base" Data.Semigroup ((<>))
import safe "base" Data.Traversable (sequenceA)
import safe "base" Data.Tuple (uncurry)
import safe "base" Data.Void (Void)
import qualified "dhall" Dhall as D
import qualified "dhall" Dhall.Core as D
import qualified "dhall" Dhall.Map as D.Map
import qualified "dhall" Dhall.Src as D
import safe "either" Data.Either.Validation (Validation)
import safe qualified "yaya" Yaya.Fold as Y

lookupField ::
  D.Decoder a ->
  D.Text ->
  D.Map.Map D.Text (D.RecordField D.Src Void) ->
  Validation (D.ExtractErrors D.Src Void) a
lookupField decoder fieldName =
  maybe
    (D.extractError $ "`Nu` value is missing `" <> fieldName <> "` field.")
    (D.extract decoder . D.recordFieldValue)
    . D.Map.lookup fieldName

-- | This is the key to a Dhall runtime – `Nu` is the one thing that can’t be
--   normalized away.
--
--   This consumes `Nu`, but can convert it to any `Y.Corecursive` type (with
--   the same functor).
corecursive ::
  (Y.Corecursive (->) t f) => D.Decoder (a -> f a) -> D.Decoder a -> D.Decoder t
corecursive ψ a =
  D.Decoder
    ( \case
        D.RecordLit fields ->
          Y.ana
            <$> lookupField ψ "coalgebra" fields
            <*> lookupField a "seed" fields
        _ -> D.extractError "Could not decode a non-record value as `Nu`"
    )
    ( D.Record
        . D.Map.fromList
        <$> sequenceA
          [ ("coalgebra",) . D.makeRecordField <$> D.expected ψ,
            ("seed",) . D.makeRecordField <$> D.expected a
          ]
    )

-- | An implementation of `autoWith` for any `Y.Corecursive` type.
--
--  __TODO__: Add `D.FromDhall` instances for various types included with Yaya.
corecursiveAutoWith ::
  forall t f a.
  (Y.Corecursive (->) t f, D.FromDhall a, D.ToDhall a, D.FromDhall (f a)) =>
  Proxy a ->
  D.InputNormalizer ->
  D.Decoder t
corecursiveAutoWith Proxy = uncurry corecursive . (D.autoWith &&& D.autoWith @a)
