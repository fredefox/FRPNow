
{-# LANGUAGE ConstraintKinds, FlexibleContexts, InstanceSigs,  NoMonomorphismRestriction, TypeOperators, MultiParamTypeClasses,FlexibleInstances #-}

module Swap where
import Control.Monad
import Control.Applicative

newtype (f :. g) x = Close { open :: f (g x) }

assoc :: Functor f => ((f :. g) :. h) x -> (f :. (g :. h)) x
assoc = Close . fmap Close . open . open

coassoc :: Functor f => (f :. (g :. h)) x -> ((f :. g) :. h) x
coassoc = Close . Close . fmap open . open

instance (Functor a, Functor b) => Functor (a :. b) where 
  fmap f = Close . fmap (fmap f) . open

class Swap f g where
  -- laws (from Composing Monads, Jones and Duponcheel)
  -- swap . fmap (fmap f) = fmap (fmap f) . swap
  -- swap . return        = fmap unit
  -- swap . fmap return   = return
  -- prod . fmap dorp     = dorp . prod 
  --             where prod = fmap join . swap
  --                   dorp = join . fmap swap
  --             
  swap :: g (f a) -> f (g a)

-- actually only requirement on g is pointed functor and f functor
liftLeft :: (Monad f, Monad g) => f x -> (f :. g) x 
liftLeft = Close . liftM return 

-- actually only requirement on f is pointed functor 
liftRight :: Monad f => g x -> (f :. g) x 
liftRight  = Close . return 

{-
instance (Functor a, Functor c, Swap a c, Swap b c) => 
         Swap (a :. b) c  where
  swap =   fmap Close . swap . fmap swap . open 

instance (Functor a, Functor b, Swap a b, Swap a c) => 
      Swap a (b :. c)  where
  swap =  Close . fmap swap . swap . fmap open 
-}
instance (Swap f g, Monad f, Monad g) => Monad (f :. g) where
  -- see (Composing Monads, Jones and Duponcheel) for proof
  return  = Close . return . return
  m >>= f = joinComp (fmap2m f m)
{- ?? 
instance (Swap g f, MonadFix f, MonadFix g) => MonadFix (f :. g) where
  -- f :: (x -> (f :. g) x ) 
  -- swap
  -- open . f :: (x -> f (g x))
  -- swap . open . f :: x -> g (f x)
  -- (g (f x) -> f (g x))
  -- (x -> f x) -> f x
  -- (x -> g x) -> g x
  -- (x -> (f :. g) x) -> (f :. g) x
  mfix f = mfix (
-}
-- anoyance that Monad is not a subclass of functor
fmap2m f = Close . liftM (liftM f) . open

joinComp :: (Swap b e, Monad e, Monad b) => (b :. e) ((b :. e) x) -> (b :. e) x
joinComp = Close . joinFlip . open . fmap2m open

joinFlip :: (Swap b e, Monad e, Monad b) => b (e (b (e x))) -> b (e x)
joinFlip =  liftM join . join . liftM swap 
-- this works as follows, we have 
-- b . e . b . e      flip middle two
-- b . b . e . e      join left and right
-- b . e 


instance (Applicative b, Applicative e) => Applicative (b :. e) where
   pure = Close . pure . pure
   x <*> y = Close $ (<*>) <$> open x <*> open y  
