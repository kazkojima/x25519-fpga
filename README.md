# An FPGA implementation of some x25519 operations

This is my trial of a verilog implementation of some operations on curve25519. See references below for each algorithm/implementation.

* add/sub/multiplication on GF(2^255-19). [4]
* Montgomery modular inverse. [2]
* Point addition on the twisted Edwards curve - curve25519. [3]

As an application of these operations, the scalar multiplication of the base point on curve25519 is implemented. It can be used to generate ed25519 keypairs.

The target FPGA is ECP5-85G and yosys/nextpnr-ecp5 open software developing system is assumed. All operations are tested successfully on the real chip with 50Mhz clock. Testbench result of the keypair generation is checked and successful, though it's tested on the chip only with 12Mhz clock ATM.

Unfortunately the routing for the ed25519 keypair circuit takes several days on my PC, ATM. Ugh.

#### I'm new to FPGA, so I could miss something basic. Any comments and patches/pull-requests are highly welcome!

## Not secure

There are almost no countermeasure implemented against well-known attacks. See the references for them.

## Performance

Testbench shows ~59700 cycles are needed to complete a scalar multiplication.

## Device utilisation

```
Info: 	       TRELLIS_SLICE: 21409/41820    51%
Info: 	          TRELLIS_IO:    11/  365     3%
Info: 	                DCCA:     1/   56     1%
Info: 	              DP16KD:    45/  208    21%
Info: 	          MULT18X18D:     0/  156     0%
```

## x25519.jl

jl/x25519.jl is a collection of Julia functions written to help I understand each algorithm and verify the results of its execution on the FPGA counterpart.

## References

[1] Bernstein, Daniel & Duif, Niels & Lange, Tanja & Schwabe, Peter & Yang,
  Bo-Yin. (2011). High-Speed High-Security Signatures.
  Journal of Cryptographic Engineering. 2. 124-142.
  10.1007/978-3-642-23951-9_9.

[2] Dormale, G.M. & Bulens, P. & Quisquater, Jean-Jacques. (2005).
  An improved Montgomery modular inversion targeted for efficient
  implementation on FPGA. 441 - 444. 10.1109/FPT.2004.1393320. 

[3]  Hisil, Hüseyin & Wong, Kenneth & Carter, Gary & Dawson, Ed. (2008).
  Twisted Edwards Curves Revisited. Lect. Notes Comput. Sci.. 5350. 326-343.
  10.1007/978-3-540-89255-7_20.

[4] Mehrabi, Ali & Doche, Christophe. (2019). Low-Cost, Low-Power FPGA
  Implementation of ED25519 and CURVE25519 Point Multiplication.
  Information. 10. 285. 10.3390/info10090285.

[5] Turan, Furkan & Verbauwhede, Ingrid. (2019). Compact and flexible FPGA
  implementation of ED25519 and X25519. ACM Transactions on Embedded
  Computing Systems. 18. 1-21. 10.1145/3312742.
