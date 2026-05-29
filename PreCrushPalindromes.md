# Powers of 2 of the form 3n+1 (n odd) — First 16 n values in binary

For 2^k = 3n + 1 with n odd, the condition holds exactly when k is even.
The n values are given by n_m = (4^m − 1) / 3 = 1 + 4 + 4² + … + 4^(m−1).

| m  | k  | n_m (decimal)   | n_m (binary)                      |
|----|----|-----------------|-----------------------------------|
|  1 |  2 |               1 | 1                                 |
|  2 |  4 |               5 | 101                               |
|  3 |  6 |              21 | 10101                             |
|  4 |  8 |              85 | 1010101                           |
|  5 | 10 |             341 | 101010101                         |
|  6 | 12 |           1,365 | 10101010101                       |
|  7 | 14 |           5,461 | 1010101010101                     |
|  8 | 16 |          21,845 | 101010101010101                   |
|  9 | 18 |          87,381 | 10101010101010101                 |
| 10 | 20 |         349,525 | 1010101010101010101               |
| 11 | 22 |       1,398,101 | 101010101010101010101             |
| 12 | 24 |       5,592,405 | 10101010101010101010101           |
| 13 | 26 |      22,369,621 | 1010101010101010101010101         |
| 14 | 28 |      89,478,485 | 101010101010101010101010101       |
| 15 | 30 |     357,913,941 | 10101010101010101010101010101     |
| 16 | 32 |   1,431,655,765 | 1010101010101010101010101010101   |

## Pattern

- n_m has exactly **2m − 1 bits**, alternating 1 and 0, starting and ending in 1.
- Recurrence: n_m = 4·n_{m−1} + 1 (left-shift by 2 bits, OR with 1 — appends "01" on the right each time).
- Every n_m is a **binary palindrome**, so LSB-first and MSB-first representations are identical.
- The corresponding 2^k values are 2^(2m), i.e. the even powers of 2.
