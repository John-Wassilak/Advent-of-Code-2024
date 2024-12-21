{-# LANGUAGE OverloadedStrings #-}

import qualified Network.HTTP.Client     as H
import qualified Network.HTTP.Client.TLS as T
import qualified Data.ByteString.Lazy as BSL
import qualified Data.ByteString.UTF8 as BSU
import qualified Data.ByteString.Lazy.UTF8 as BLU
import qualified System.Environment as E
import qualified Data.List.Split as S

{-
  Hmm, not sure I like haskell as much as I used to...
  I'm probably just out of practice and I don't know
  all the right levers to pull

  lots of deps to install, os dependent

  usage: runhaskell 12-07.hs
-}

getInput :: IO (H.Response BSL.ByteString)
getInput = do
  httpman <- H.newManager T.tlsManagerSettings
  cookie <- E.getEnv "AOC_COOKIE"
  request <- H.parseRequest "https://adventofcode.com/2024/day/7/input"
  let req = request {
        H.requestHeaders = [("Cookie", BSU.fromString cookie)]
        }
  H.httpLbs req httpman


data Equation = Equation { answer :: Integer
                         , members :: [Integer]
                         } deriving (Show)


-- there's probably some haskell magic to make this
-- prettier
parseInput :: String -> [Equation]
parseInput input = map (\(x:xs) -> Equation x xs) $
                   map (map read) $
                   filter (\l -> length l > 1) $
                   map (S.splitOn " ") $
                   S.splitOn "\n" $
                   filter (\c -> c /= ':') input


-- I guess our map function below gives the members
-- in the opposite order than I expected, hence y+x
p2Concat :: Integer -> Integer -> Integer
p2Concat x y = read $ (show y) ++ (show x)


-- this feels like something that can be folded
genPossibleOutcomes :: [Integer] -> [Integer] -> Bool -> [Integer]
genPossibleOutcomes acc [] _ = acc
genPossibleOutcomes [] (m:ms) isP2 = genPossibleOutcomes [m] ms isP2
genPossibleOutcomes acc (m:ms) isP2 = let new_acc = if isP2 then
                                            map (* m) acc ++
                                            map (+ m) acc ++
                                            map (p2Concat m) acc
                                            else
                                            map (* m) acc ++
                                            map (+ m) acc
                                 in genPossibleOutcomes new_acc ms isP2


isEqPossible :: Equation -> Bool -> Bool
isEqPossible (Equation a ms) isPart2 =
  let possibles = genPossibleOutcomes [] ms isPart2
  in elem a possibles


main :: IO ()
main = do
  input <- getInput
  let string = BLU.toString $ H.responseBody input
  let parsed = parseInput string
  let p1 = sum [x | e@(Equation x xs) <- parsed, isEqPossible e False]
  let p2 = sum [x | e@(Equation x xs) <- parsed, isEqPossible e True]
  putStrLn $ "part 1: " ++ show p1
  putStrLn $ "part 2: " ++ show p2
