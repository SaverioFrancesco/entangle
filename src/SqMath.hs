{-# LANGUAGE PatternGuards #-}

module SqMath (Expr) where

import           Data.Ratio

data Expr
    = Leaf Integer
    | Expr :+: Expr
    | Expr :*: Expr
    | Expr :/: Expr
    | Abs Expr
    | Sqrt Expr

infixl 6 :+:
infixl 7 :*:
infixl 7 :/:

-- eval :: Expr -> Either Integer Double
-- eval (Leaf i) = Left i
-- eval (i :+: j) = lift2 (+) (+) i j
-- eval (i :*: j) = lift2 (*) (*) i j
-- eval (i :/: j) = lift2 div (/) i j
-- eval (Abs i) = lift1 abs abs i
-- eval (Sqrt i) = (Right . sqrt . toDouble . eval) i
--
-- toDouble :: Either Integer Double -> Double
-- toDouble (Left a) = fromInteger a
-- toDouble (Right b) = b
--
-- lift1 :: (Integer -> Integer) -> (Double -> Double) -> Expr -> Either Integer Double
-- lift1 i d e = lift' (eval e) where
--     lift' (Left x) = Left $ i x
--     lift' x = Right $ d (toDouble x)
--
-- lift2 :: (Integer -> Integer -> Integer) -> (Double -> Double -> Double) -> Expr -> Expr -> Either Integer Double
-- lift2 i d e f = lift' (eval e) (eval f) where
--     lift' (Left x) (Left y) = Left $ i x y
--     lift' x y = Right $ d (toDouble x) (toDouble y)

instance Num Expr where
    a + b = simplify $ a :+: b
    a * b = simplify $ a :*: b
    abs a = simplify $ Abs a
    signum = undefined
    fromInteger = Leaf
    negate a = a * Leaf (-1)

instance Fractional Expr where
    fromRational r = Leaf (numerator r) / Leaf (numerator r)
    a / b = simplify $ a :/: b

instance Floating Expr where
    sqrt a = simplify $ Sqrt a
    pi = undefined
    exp = undefined
    log = undefined
    sin = undefined
    cos = undefined
    asin = undefined
    acos = undefined
    atan = undefined
    sinh = undefined
    cosh = undefined
    asinh = undefined
    acosh = undefined
    atanh = undefined


simplify :: Expr -> Expr
simplify (Leaf a :+: Leaf b)         = Leaf $ a + b
simplify (Leaf 0 :+: a)              = simplify a
simplify (a :+: Leaf 0)              = simplify a
simplify ((a :/: b) :+: c)           = (a + b * c) / b
simplify (a :+: (b :/: c))           = (a * c + b) / c

simplify (Leaf 0 :*: _)              = 0
simplify (_ :*: Leaf 0)              = 0
simplify (Leaf 1 :*: a)              = simplify a
simplify (a :*: Leaf 1)              = simplify a
simplify (Leaf a :*: Leaf b)         = Leaf $ a * b
simplify ((a :/: b) :*: c)           = (a * c) / b
simplify (a :*: (b :/: c))           = (a * b) / c
simplify (Sqrt a :*: Sqrt b)         = sqrt $ a * b
simplify ((a :*: b) :*: c)           = a * (b * c)
simplify (a :*: Leaf b)              = Leaf b * a
simplify (Leaf a :*: (Leaf b :*: c)) = Leaf (a * b) * c
simplify (a :*: (b@(Leaf _) :*: c))  = b * (a * c)

simplify (a :/: s@(Sqrt _))          = (a * s) / (s * s)
simplify ((a :/: b) :/: c)           = a / (b * c)
simplify (a :/: (b :/: c))           = (a * c) / b
simplify (Leaf a :/: Leaf b)         | a `mod` b == 0 = Leaf $ a `div` b
simplify ((Leaf a :*: b) :/: Leaf c) | a `mod` c == 0 = (Leaf $ a `div` c) * b

simplify (Sqrt (Leaf a))             | Just r <- perfectSqrt a = Leaf r
simplify (Sqrt (x :/: y))            = sqrt x / sqrt y

simplify (Abs (Leaf a))              = Leaf $ abs a

simplify e                           = e

perfectSqrt :: Integer -> Maybe Integer
perfectSqrt i | i < 0 = Nothing
perfectSqrt a | b * b == a = Just b where
    b = floor $ sqrt $ fromInteger a
perfectSqrt _ = Nothing


-- showF :: Expr -> String
-- showF = showF' 0
--
-- showF' :: Int -> Expr -> String
-- showF' i e = prefix i ++ showF'' e where
--     prefix 0 = ""
--     prefix i = concat (replicate i "   ")
--     showF'' (Leaf a)  = show a
--     showF'' (x :+: y) = "+\n"    ++ showF' (i+1) x ++ "\n" ++ showF' (i+1) y
--     showF'' (x :*: y) = "*\n"    ++ showF' (i+1) x ++ "\n" ++ showF' (i+1) y
--     showF'' (x :/: y) = "/\n"    ++ showF' (i+1) x ++ "\n" ++ showF' (i+1) y
--     showF'' (Abs a)   = "abs\n"  ++ showF' (i+1) a
--     showF'' (Sqrt a)  = "sqrt\n" ++ showF' (i+1) a

instance Show Expr where
    show (Leaf i)  = show i
    show (x :+: y) = "(" ++ show x ++ " + " ++ show y ++ ")"
    show (x :*: y) = "(" ++ show x ++ " * " ++ show y ++ ")"
    show (x :/: y) = "(" ++ show x ++ " / " ++ show y ++ ")"
    show (Abs a)   = "abs(" ++ show a ++ ")"
    show (Sqrt a)  = "sqrt(" ++ show a ++ ")"
