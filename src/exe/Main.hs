{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE RankNTypes            #-}

module Main where

import           Data.Aeson.Types
import           Data.List
import           Data.Matrix                  (Matrix)
import           Data.Monoid
import           Data.Text.Lazy               (pack, unpack)
import           Data.Text.Lazy.Encoding      (decodeUtf8)
import           Data.Typeable
import           Language.Haskell.Interpreter hiding (get)
import           Network.Wai.Middleware.Cors
import           Quipper
import           Web.Scotty

import           Complex
import           Examples
import           Expr
import           QMatrix
import           Qpmc
import           QTuple
import           SymbolicMatrix
import           Transitions

-- |fullOut takes a function returning a value in the 'Circ' monad,
-- and outputs the result of transforming it to QPMC code
--fullOut :: QTuple a => (a -> Circ b) -> IO ()
fullOut :: (QTuple a, Show b, QCMatrix m Expr, ToQpmc (m (Complex Expr))) => m x -> (b -> [Transition m Expr]) -> (a -> Circ b) -> IO ()
fullOut _ final c = do
    putStr "---\n"
    let tree = circToTree c
    print tree
    putStr "---\n"
    let transitions = circMatrices final c
    putStrLn $ toQpmc transitions
    putStr "---\n"

nonrecursive :: a -> [Transition m Expr]
nonrecursive = const []

recursive :: RecAction -> [Transition m v]
recursive Exit = []
recursive Loop = [Transition Nothing $ StateName 0 []]

symbolic :: SymbolicMatrix a
symbolic = error "proxy"

numeric :: Matrix a
numeric = error "proxy"

-- main :: IO ()
-- main = fullOut
--   symbolic
--   --numeric

--   --nonrecursive grover_naive
--   --nonrecursive test_matrix_3
--   --nonrecursive test_matrix_3
--   --nonrecursive strange
--   --nonrecursive mycirc
--   --nonrecursive test_if
--   --recursive recCirc'
--   --recursive branchCirc
--   --recursive interfCirc
--   recursive groverRec

data Response = Response {
  qpmc  :: String,
  nodes :: String,
  tree  :: String
}

instance ToJSON Response where
  toJSON (Response qpmc nodes tree) = object ["qpmc" .= qpmc, "nodes" .= nodes, "tree" .= tree]

  toEncoding (Response qpmc nodes tree) = pairs ("qpmc" .= qpmc <> "nodes" .= nodes <> "tree" .= tree)

errorString :: InterpreterError -> String
errorString (WontCompile es) = intercalate "\n" (header : map unbox es)
  where
    header = "ERROR: Won't compile:"
    unbox (GhcError e) = e
errorString e = show e

useHint :: Typeable a => String -> a -> IO (Either String a)
useHint input e =
  let
    interpreter = interpret input e
    result = runInterpreter $ do
      setImports ["Prelude", "Quipper"]
      interpreter
  in
    either (Left . errorString) Right <$> result

root :: ActionM ()
root = (do
  code <- (Data.Text.Lazy.unpack . decodeUtf8) <$> body
  maybeCirc <- liftAndCatchIO $ useHint code (as :: Qubit -> Circ Qubit)
  let tree = either id (show . circToTree) maybeCirc
  --fullOut symbolic (recursive || nonrecursive) circ
  json $ Response "qpmc" code tree ) `rescue` text

corsResourcePolicy :: CorsResourcePolicy
corsResourcePolicy = CorsResourcePolicy
    { corsOrigins = Nothing
    , corsMethods = ["GET", "POST", "OPTIONS"]
    , corsRequestHeaders = ["content-type"]
    , corsExposedHeaders = Nothing
    , corsMaxAge = Nothing
    , corsVaryOrigin = False
    , corsRequireOrigin = False
    , corsIgnoreFailures = False
    }

main :: IO ()
main = scotty 3113 handler

dev h = scottyApp handler >>= h

handler :: ScottyM ()
handler = do
  middleware $ cors (const $ Just corsResourcePolicy)
  get "/" $ text "Welcome to entangle!"
  post "/" root
