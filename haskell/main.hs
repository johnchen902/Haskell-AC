{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE GADTs #-}

import Data.Char
import Data.Maybe
import qualified Data.Text as T
import qualified Data.Array as A

data TNode = TNode Bool (A.Array Char Trie)
  deriving (Show, Eq)
type Trie = Maybe TNode

singleTrie :: String -> Trie
singleTrie [] = Just . TNode True . A.array (minBound::Char,maxBound::Char) $ [ (x,Nothing) | x <- [minBound::Char .. maxBound::Char] ]
singleTrie (c:cs) = Just . TNode False . A.array (minBound::Char,maxBound::Char) $ [ (x,sel x) | x <- [minBound::Char .. maxBound::Char] ]
  where
  sel x
    | x == c = singleTrie cs
    | otherwise = Nothing

mergeTrie :: Trie -> Trie -> Trie
mergeTrie Nothing x = x
mergeTrie x Nothing = x
mergeTrie (Just (TNode isA as)) (Just (TNode isB bs)) =
  Just . TNode (isA || isB) . A.array (minBound::Char,maxBound::Char)
  $ [ (x,(mergeTrie (as A.! x) (bs A.! x))) | x <- [minBound::Char .. maxBound::Char] ]

constructTrie :: [String] -> Trie
constructTrie [] = Just . TNode False . A.array (minBound::Char,maxBound::Char) $ [ (x,Nothing) | x <- [minBound::Char .. maxBound::Char] ]
constructTrie (x:xs) = mergeTrie (constructTrie xs) (singleTrie x)

getnodeTrie :: String -> Trie -> Maybe Trie
getnodeTrie _ Nothing = Nothing
getnodeTrie [] t = Just t
getnodeTrie (c:cs) (Just (TNode _ ts)) = getnodeTrie cs $ ts A.! c

inTrie :: String -> Trie -> Bool
inTrie cs t = isHit
  where
  isHit
    | isNothing (getnodeTrie cs t) = False
    | otherwise =  (\(Just (TNode x _))->x) $ fromJust $ getnodeTrie cs t

jumpTrie :: String -> Char -> Trie -> String
jumpTrie [] c (Just (TNode _ ts))
  | ts A.! c == Nothing = []
  | otherwise = [c]
jumpTrie cs c t
  | ts A.! c /= Nothing = cs++[c]
  | otherwise = jumpTrie (failTrie cs t) c t
    where
    (Just (TNode _ ts)) = fromJust $ getnodeTrie cs t

failTrie :: String -> Trie -> String
failTrie [] _ = []
failTrie [x] _ = []
failTrie xs t = jumpTrie pre (last xs) t
  where
  pre = failTrie (init xs) t

hitfailTrie :: String -> Trie -> String
hitfailTrie [] _ = []
hitfailTrie [x] _ = []
hitfailTrie xs t
  | isHit = res
  | otherwise = failTrie res t
    where
    res = failTrie xs t
    (Just (TNode isHit _)) = fromJust $ getnodeTrie res t

data AC = AC {
  isroot :: Bool
, str :: String
, failAC :: AC
, hitfailAC :: AC
, hit :: Bool
, sub :: A.Array Char AC
} | ANull deriving (Show,Eq)

realbuildAC :: String -> Trie -> AC
realbuildAC cs root = AC (null cs) cs (realbuildAC (failTrie cs root) root) (realbuildAC (hitfailTrie cs root) root) isHit buildsub
  where
  (Just (TNode isHit ts)) = fromJust $ getnodeTrie cs root
  buildsub = A.array (minBound::Char,maxBound::Char) $ [ (x,sel x) | x <- [minBound::Char .. maxBound::Char] ]
  sel x
    | ts A.! x == Nothing = ANull
    | otherwise = realbuildAC (cs++[x]) root

buildAC :: [String] -> AC
buildAC ss = realbuildAC [] $ constructTrie ss

runAC :: AC -> Char -> AC
runAC a c
  | sub a A.! c == ANull = if isroot a then a else runAC (failAC a) c
  | otherwise = sub a A.! c

