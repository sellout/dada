  λ(f : Type → Type)
→   { iter =
        ./iter f
    , iterA =
        ./iterA f
    , retract =
        ./retract f
    , wrap =
        ./wrap f
    , liftF =
        ./liftF f
    , foldFree =
        ./foldFree f
    }
  ∧ ./monad f ⫽ ./transformer
