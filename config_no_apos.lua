#! /usr/bin/env lua


alphabet = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
  'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'}
lengths = { 3, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 8, 8, 8, 9, 9, 10 }

local neutral = {
  a = 1,
  b = 1,
  c = 1,
  e = 1,
  f = 1,
  g = 1,
  h = 1,
  i = 1,
  j = 1,
  k = 1,
  l = 1,
  m = 1,
  n = 1,
  o = 1,
  p = 1,
  q = 1,
  r = 1,
  s = 1,
  t = 1,
  u = 1,
  v = 1,
  w = 1,
  x = 1,
  y = 1,
  z = 1
}
local vowel = neutral
local ponderation_vowel = 1.5
local ponderation_consonant = 0.1
local consonant = {
  a = ponderation_vowel,
  b = ponderation_consonant,
  c = ponderation_consonant,
  e = ponderation_vowel,
  f = ponderation_consonant,
  g = ponderation_consonant,
  h = ponderation_consonant,
  i = ponderation_vowel,
  j = ponderation_consonant,
  k = ponderation_consonant,
  l = ponderation_consonant,
  m = ponderation_consonant,
  n = ponderation_consonant,
  o = ponderation_vowel,
  p = ponderation_consonant,
  q = ponderation_consonant,
  r = ponderation_consonant,
  s = ponderation_consonant,
  t = ponderation_consonant,
  u = ponderation_vowel,
  v = ponderation_consonant,
  w = ponderation_consonant,
  x = ponderation_consonant,
  y = ponderation_vowel,
  z = ponderation_consonant
}

transitions = {
  [''] = neutral,
  a = vowel,
  b = consonant,
  c = consonant,
  e = vowel,
  f = consonant,
  g = consonant,
  h = consonant,
  i = vowel,
  j = consonant,
  k = consonant,
  l = consonant,
  m = consonant,
  n = consonant,
  o = vowel,
  p = consonant,
  q = consonant,
  r = consonant,
  s = consonant,
  t = consonant,
  u = vowel,
  v = consonant,
  w = consonant,
  x = consonant,
  y = vowel,
  z = consonant
}


