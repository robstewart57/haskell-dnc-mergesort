module Main where

import Control.DeepSeq
import Control.Exception
import Control.Parallel.Strategies
import Criterion.Measurement
import System.Random (randomRIO)

-- adapted from Section 5.3 of
--    "Seq no more: better strategies for parallel Haskell"
--    Symposium on Haskell, 2010. Simon Marlow, Patrick Maier,
--    Hans-Wolfgang Loidl, Mustaya Aswad, Phil Trinder.
--
-- https://www.macs.hw.ac.uk/~dsg/gph/papers/pdf/new-strategies.pdf

-- | divde and conquer algorithmic skeleton.
divideAndConquer ::
  -- | compute the result
  (problem -> solution) ->
  -- | input value
  problem ->
  -- | parallelism threshold reached?
  (problem -> Bool) ->
  -- | combine results
  ([solution] -> solution) ->
  -- | divide
  (problem -> [problem]) ->
  solution
divideAndConquer f arg threshold conquer divide = go arg
  where
    go splitData =
      case divide splitData of
        [] ->
          -- input data not being divided further
          f splitData
        -- input data to be split into two parts
        splits -> conquer results `using` strat
          where
            results = map go splits
            strat x = do
              mapM_ chosenStrategy results
              return x
            chosenStrategy
              | threshold splitData = rseq
              | otherwise = rpar

-- | sequential merge sort
mergeSort :: (Show a, Ord a) => [a] -> [a]
mergeSort [] = []
mergeSort [x] = [x]
mergeSort xs =
  merge (mergeSort firstHalf) (mergeSort secondHalf)
  where
    firstHalf = take ((length xs) `div` 2) xs
    secondHalf = drop ((length xs) `div` 2) xs

merge :: (Ord a) => [a] -> [a] -> [a]
merge xs [] = xs
merge [] ys = ys
merge (x : xs) (y : ys)
  | x < y = x : (merge xs (y : ys))
  | otherwise = y : (merge (x : xs) ys)

-- performs mergeSort sequentially when list is smaller than thresold,
-- otherwise splits the list into two to perform in parallel.
mergeSortParallelBounded :: (Show a, Ord a) => Int -> [a] -> [a]
mergeSortParallelBounded listSizeDivideThreshold input =
  divideAndConquer mergeSort input threshold combine divide
  where
    threshold _ = False -- always evaluate children in parallel
    combine [xs, ys] = merge xs ys
    divide xs
      | len < listSizeDivideThreshold = []
      | otherwise = [first, second]
      where
        len = length xs
        halfway = len `div` 2
        first = take halfway xs
        second = drop halfway xs

randomList :: Int -> IO [Int]
randomList n = sequence $ replicate n $ randomRIO (1, 1000 :: Int)

-- | time an IO action.
time_ :: IO a -> IO Double
time_ act = do
  start <- getTime
  _ <- act
  end <- getTime
  return $! end - start

main :: IO ()
main = do
  xs <- randomList 1000000
  secs <$> time_ (evaluate (force (mergeSortParallelBounded 100 xs))) >>= print
