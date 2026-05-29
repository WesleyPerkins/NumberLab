# No Multiples of 3 in the Image of the Collatz Function

## Setup

The Collatz function here is defined as T: Odd → Odd, where

    T(n) = (3n + 1) / 2^k

and k is the largest power of 2 dividing 3n + 1 (so that the result is odd).

## Claim

T(n) is never a multiple of 3.

## Proof

Consider 3n + 1 modulo 3:

    3n + 1 ≡ 0 + 1 = 1 (mod 3)

So 3 never divides 3n + 1. Dividing by 2^k cannot introduce a factor of 3, so 3 never divides T(n).

More explicitly, T(n) mod 3 depends on the parity of k:

- 2^k ≡ 1 (mod 3) when k is even, so T(n) ≡ 1 · 1 = 1 (mod 3)
- 2^k ≡ 2 (mod 3) when k is odd, so T(n) ≡ 1 · 2⁻¹ ≡ 2 (mod 3)

In both cases T(n) ≢ 0 (mod 3). ∎

## Consequence for the Collatz Graph

The image of T is a proper subset of the odd numbers: it contains only odd numbers
congruent to 1 or 2 (mod 3). Odd multiples of 3 — such as 3, 9, 15, 21, ... — can
appear as inputs (keys in the Collatz map) but never as outputs. In the graph, every
node whose value is an odd multiple of 3 will have an empty predecessor list.



## Is it fair to conclude that in iterations of the Collatz function, a multiple of three can never be part of a cycle?                                                   
  
⏺ Yes, that follows directly. For any number n to be part of a cycle, some iterate T^k(n) must equal
   n — meaning n must be in the image of T. But we proved multiples of 3 are never in the image of
  T. So a multiple of 3 can never be returned to once the iteration leaves it, and therefore cannot
  participate in any cycle.

## This is a stronger statement than it might first appear: it rules out any hypothetical non-trivialcycles passing through multiples of 3, independent of whether the Collatz conjecture is true.

## Are there any other classes of odd numbers that we can exclude from being in the image of the     Collatz function?                                                                                 
  
⏺ No — multiples of 3 are the only exclusion. Every odd number not divisible by 3 is in the image.
  Here's the constructive proof:

  Given a target m (odd, m ≢ 0 mod 3), we need an odd n with T(n) = m, i.e., 3n+1 = m·2^k for some k
   ≥ 1, giving n = (m·2^k − 1)/3.

  n is always an odd integer when k ≥ 1: since k ≥ 1, m·2^k is even, so m·2^k − 1 is odd, so 3n is
  odd, so n is odd. We just need 3 | (m·2^k − 1), i.e., m·2^k ≡ 1 (mod 3).

  - m ≡ 1 (mod 3): take k even (e.g. k=2), since 2^k ≡ 1 (mod 3) → m·2^k ≡ 1 ✓
  - m ≡ 2 (mod 3): take k odd (e.g. k=1), since 2^k ≡ 2 (mod 3) → m·2^k ≡ 4 ≡ 1 ✓

  Concretely:
  - m ≡ 1 (mod 3) → n = (4m − 1)/3, e.g. m=7: n=9, T(9)=28/4=7 ✓
  - m ≡ 2 (mod 3) → n = (2m − 1)/3, e.g. m=5: n=3, T(3)=10/2=5 ✓
  
##  So the image of T is exactly the odd numbers not divisible by 3. No other class is excluded.


## As a Collatz iteration proceeds, what happens with numbers congruent to one mod 3 vs congruent to two mod 3? Do they appear in random order, or do they alternate, or is there some other pattern? 
  
⏺ There's no alternation — and the reason is cleaner than you might expect.

  The mod-3 class of T(n) is independent of the mod-3 class of n.

  Since 3n+1 ≡ 1 (mod 3) regardless of whether n ≡ 1 or 2 (mod 3), the residue of T(n) = (3n+1)/2^k
  mod 3 depends entirely on the parity of k = v₂(3n+1):

  - k even → T(n) ≡ 1 (mod 3)
  - k odd → T(n) ≡ 2 (mod 3)

  So a ≡1 and a ≡2 term both behave identically with respect to the next step. Runs of the same
  class are perfectly possible; so is alternation. The sequence is governed entirely by the 2-adic
  valuations along the chain, which depends on the detailed binary structure of each term — not
  capturable by any fixed modulus.

  Heuristic distribution: for a "typical" even number, P(v₂ = k) = 2^{-k}, giving:

  - P(k odd) = 1/2 + 1/8 + 1/32 + ... = 2/3 → T(n) ≡ 2 (mod 3)
  - P(k even) = 1/4 + 1/16 + ... = 1/3 → T(n) ≡ 1 (mod 3)

  ## So heuristically, ≡2 (mod 3) should appear about twice as often as ≡1 (mod 3) in a long Collatz chain. But this is probabilistic, not deterministic, and short chains can easily look balanced.

## Consider a number o: Odd such that o.collatzed() == .one  . Is it true that, when written in binary, o must match the regular expression ^(10)*1$  ?                                           
  
⏺ Yes, exactly. Here's why.
  
  o.collatzed() == .one means T(o) = 1, i.e.:

  (3o + 1) / 2^k = 1  →  3o + 1 = 2^k  →  o = (2^k − 1) / 3
  For o to be an integer, 2^k ≡ 1 (mod 3), which requires k even. So the solutions are k = 2, 4, 6,
  8, …:

  ┌─────┬───────────────┬─────────┐
  │  k  │ o = (2^k−1)/3 │ binary  │
  ├─────┼───────────────┼─────────┤
  │ 2   │ 1             │ 1       │
  ├─────┼───────────────┼─────────┤
  │ 4   │ 5             │ 101     │
  ├─────┼───────────────┼─────────┤
  │ 6   │ 21            │ 10101   │
  ├─────┼───────────────┼─────────┤
  │ 8   │ 85            │ 1010101 │
  └─────┴───────────────┴─────────┘
  
  These are exactly the numbers matching ^(10)*1$ — alternating 1-0 pairs ending in 1. We can verify
   the pattern directly: a number matching ^(10)*1$ with n repetitions of "10" has value

  ∑_{i=0}^{n} 4^i = (4^{n+1} − 1)/3 = (2^{2(n+1)} − 1)/3
  and plugging back in: 3o + 1 = 2^{2(n+1)}, so T(o) = 1. ✓
  
  These binary representations are all palindromes, so the regex holds whether you read MSB→LSB or
  LSB→MSB (which matters given that BitChain stores LSB first).
