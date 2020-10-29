# x25519.jl gives some modular arithmetics modulo 2^255-19 and the point
# addition and scalar multiplication on curve25519. The computation is
# implemented with the intention of implementing it on top of an FPGA.

# Carry saved adder.
function csa(a,b,c,carry_in=0)
    s = (a ⊻ b) ⊻ c
    c = (((a & b) | (a & c) | (b & c)) << 1) | carry_in
    return (s, c)
end

# Modular addition of two numbers in 0:2^255-20 modulo p=2^255-19.
function addmod_25519(a, b)
#    return (a + b) % (BigInt(2)^255-19)
    zs, zc = csa(a, b, ~(BigInt(2)^255-19) & (BigInt(2)^255-1), 1)
    sel = ((zs+zc) >> 255) != 0 ? 1 : 0
    return (sel == 1) ? (zs+zc) & (BigInt(2)^255-1) : a+b
end

# Modular subtraction of two numbers in 0:2^255-20 modulo p=2^255-19.
function submod_25519(a, b)
#    t = (a - b) % (BigInt(2)^255 - 19)
#    return (t < 0) ? t + (BigInt(2)^255 - 19) : t
     zs, zc = csa(a, ~b & (BigInt(2)^255-1), 0)
     ws, wc = csa(a, ~b & (BigInt(2)^255-1), (BigInt(2)^255-19))
     sel = ((zs+zc+1) >> 255) != 0 ? 1 : 0
     return (sel == 1) ? (zs+zc+1) & (BigInt(2)^255-1) : (ws+wc+1) & (BigInt(2)^255-1)
end

# Modular multiplication of two numbers in 0:2^255-20 modulo p=2^255-19.
# with radix-8 interleave.
function multmod_25519(x, y)
#    return (x*y) % (BigInt(2)^255 - 19)
    p = BigInt(2)^255 - 19
    lut1 = [(0,0), (y,0), (y<<1, 0), (y<<1, y),
            (y<<2, 0), (y<<2, y), (y<<2, y<<1),
            csa(y<<2,y<<1,y)]
    lut2 = [i*8*19 for i=0:23]
    s = c = n = BigInt(0)
    for i in 85:-1:1
        ms, mc = lut1[(x >> (3*i-3)) + 1]
        x = x % BigInt(2)^(3*i-3)
        s1 = 8*(s % BigInt(2)^255)
        c1 = 8*(c % BigInt(2)^255)
        s2 = (s1 ⊻ ms) ⊻ c1
        c2 = ((s1 & ms) | (s1 & c1) | (ms & c1)) << 1
        s3 = (s2 ⊻ mc) ⊻ c2
        c3 = ((s2 & mc) | (s2 & c2) | (mc & c2)) << 1
        s = (s3 ⊻ n) ⊻ c3
        c = ((s3 & n) | (s3 & c3) | (n & c3)) << 1
        n = lut2[(s >> 255) + (c >> 255) + 1]
    end
    # TODO better reduction
    # s c = (s[254:0]+19*(s>>255), c[254:0]+19*(c>>255))
    s, c = csa((s % BigInt(2)^255), (c % BigInt(2)^255), n>>3)
    n = lut2[(s >> 255) + (c >> 255) + 1]
    #println("1st reduce $(s>>253) $(c>>253)")
    s, c = csa((s % BigInt(2)^255), (c % BigInt(2)^255), n>>3)
    z = s + c
    #println("2nd reduce $(s>>253) $(c>>253) $(z>>253)")
    if (z > BigInt(2)^255 - 19)
        z -= BigInt(2)^255 - 19
    end
    return z
end

# Point addition of two points on twisted Edwards curve 25519 where
# points are represented with (x, y, t, z) cordinates. If affine variable
# is true, then the result is affinized i.e. z=1.
function point_add(x1,y1,t1,z1,x2,y2,t2,z2; affine=false)
    r1 = submod_25519(y1, x1)
    r2 = submod_25519(y2, x2)

    r3 = addmod_25519(y1, x1)
    r4 = addmod_25519(y2, x2)

    r5 = multmod_25519(r1, r2)
    r6 = multmod_25519(r3, r4)

    r7 = multmod_25519(t1, t2)
    r8 = multmod_25519(z1, z2)

    k = 16295367250680780974490674513165176452449235426866156013048779062215315747161

    r7 = multmod_25519(k, r7)
    r8 = addmod_25519(r8, r8)

    r1 = submod_25519(r6, r5)
    r2 = submod_25519(r8, r7)

    r3 = addmod_25519(r8, r7)
    r4 = addmod_25519(r6, r5)

    x3 = multmod_25519(r1, r2)
    y3 = multmod_25519(r3, r4)

    t3 = multmod_25519(r1, r4)
    z3 = multmod_25519(r2, r3)

    if (affine == true)
        zinv = invmod_25519_M(z3)
        x3 = multmod_25519(x3, zinv)
        y3 = multmod_25519(y3, zinv)
        t3 = multmod_25519(x3, y3)
        z3 = BigInt(1)
    end

    return (x3, y3, t3, z3)
end

# Load precomputed radix-16 lookup table of the scalar multiplications of
# the base point on curve25519.
# The nth line of each files is the x,y,t-coordinates of (i*16^j)B expressed in
# 64 hexadecimal digits where i = n %16, j = n ÷ 16 and B is the base point.
function load_precomp_points()
    fx=open("../x25519/x_precomp_32k.dat", "r")
    fy=open("../x25519/y_precomp_32k.dat", "r")
    ft=open("../x25519/t_precomp_32k.dat", "r")
    xlines=readlines(fx)
    ylines=readlines(fy)
    tlines=readlines(ft)
    global x_precomp_data=map(x -> parse(BigInt,x,base=16), xlines)
    global y_precomp_data=map(x -> parse(BigInt,x,base=16), ylines)
    global t_precomp_data=map(x -> parse(BigInt,x,base=16), tlines)
    close(fx)
    close(fy)
    close(ft)
end

# Scalar multiplication of the base point on curve25519 with the 16-radix
# precomputed lookup table of scalar multiplications.
# Call load_precomp_points() before calling this function.
function scalarmultB(k)
    kl = [(k >> (4*i)) % 16 for i in 0:63]

    # k0 B from lut
    px = x_precomp_data[1+kl[1]]
    py = y_precomp_data[1+kl[1]]
    pt = t_precomp_data[1+kl[1]]
    pz = BigInt(1)
    for i in 2:64
        # k_n 16^n B from lut
        qx = x_precomp_data[1+(i-1)*16+kl[i]]
        qy = y_precomp_data[1+(i-1)*16+kl[i]]
        qt = t_precomp_data[1+(i-1)*16+kl[i]]
	qz = BigInt(1)
        # p = p + q
        #println("$(i): px $(px) py $(py) qx $(qx) qy $(qy)")
	px, py, pt, pz = point_add(px, py, pt, pz, qx, qy, qt, qz,
                                   affine=(i == 64))
    end
    return px, py, pz
end

function modpow2_n(x, n)
    for _ in 1:n
      x = multmod_25519(x,x)
    end
    return x
end

# Modular inverse module 2^255-19 by the Fermat's little theorem
function invmod_25519(a)
      a2   = multmod_25519(a,a)
      a4   = multmod_25519(a2,a2)
      a8   = multmod_25519(a4,a4)
      a9   = multmod_25519(a8,a)
      a11  = multmod_25519(a9,a2)
      a22  = multmod_25519(a11,a11)
      a_2_5  = multmod_25519(a22,a9)
      b_2_10 = modpow2_n(a_2_5,5)
      a_2_10 = multmod_25519(b_2_10,a_2_5)
      b_2_20 = modpow2_n(a_2_10,10)
      a_2_20 = multmod_25519(b_2_20,a_2_10)
      b_2_40 = modpow2_n(a_2_20,20)
      a_2_40 = multmod_25519(b_2_40,a_2_20)
      b_2_50 = modpow2_n(a_2_40,10)
      a_2_50 = multmod_25519(b_2_50,a_2_10)
      b_2_100 = modpow2_n(a_2_50,50)
      a_2_100 = multmod_25519(b_2_100,a_2_50)
      b_2_200 = modpow2_n(a_2_100,100)
      a_2_200 = multmod_25519(b_2_200,a_2_100)
      b_2_250 = modpow2_n(a_2_200,50)
      a_2_250 = multmod_25519(b_2_250,a_2_50)
      b_2_255 = modpow2_n(a_2_250,5)
      inv = multmod_25519(b_2_255,a11)
      return inv
end

function even(x)
    return ((x & 1) == 0) ? true : false
end

function signbit(x)
    return (x < 0) ? 1 : 0
end

function bitsize(M)
    return length(string(M,base=2))
end

# Montgomery modular inverse.
# Input X in 1:M-1 and M
# Output Lrs in 1:M-1 where Lrs = Xinv 2^n mod M
function inv_montgomery(X, M)
    # Phase1
    k = -bitsize(M)
    Luv = BigInt(0)
    Ruv = BigInt(X) << 1
    Lrs = BigInt(0)
    Rrs = BigInt(1)
    Luv = (Luv>>1)+Ruv
    Ruv = M
    Lrs = Lrs + Rrs
    Rrs = 0
    while true
        # println("Luv $(Luv) Ruv $(Ruv) Lrs $(Lrs) Rrs $(Rrs) k $(k)")
        SLuv, SRuv = signbit(Luv), signbit(Ruv)
        if (even(Luv>>1))
            if Luv == 0 # SLuv == signbit(-Luv)
                break
            end
            Luv = Luv>>1
            Rrs = Rrs<<1
            k = k+1
        else
            tmpuv = Luv>>1
            tmprs = Lrs
            Lrs = Lrs + Rrs
            if (SLuv ⊻ SRuv) == 1
                Luv = (Luv>>1)+Ruv
            else
                Luv = (Luv>>1)-Ruv
            end
            k = k+1
            ctrl = ((~SLuv & ~SRuv) | (~SLuv & SRuv)) & 1
            if signbit(Luv) == ctrl
                Ruv = tmpuv
                Rrs = tmprs<<1
            else
                Rrs = Rrs<<1
            end
        end
    end
    # Here we have Lrs == M
    Lrs = Lrs-Rrs
    Rrs = M
    if signbit(Lrs) == 1
        Lrs = Lrs + Rrs
    end

    # Phase 2
    while (k != 0)
        # println("Phase2 Lrs $(Lrs) Rrs $(Rrs) k $(k)")
        k = k - 1
        if even(Lrs)
            Lrs = Lrs>>1
        else
            Lrs = (Lrs+Rrs)>>1
        end
    end
    return Lrs
end

# Modular inverse modulo 2^255-19 with Montgomery modular inverse.
function invmod_25519_M(x)
    P = BigInt(2)^255-19
    iM = inv_montgomery(x, P)
    # i2n = inverse of 2^255 mod P = inverse of 19 mod P
    i2n = 21330121701610878104342023554231983025602365596302209165163239159352418617876
    return multmod_25519(iM, i2n)
end
