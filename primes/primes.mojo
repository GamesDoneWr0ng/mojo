from algorithm import parallelize
from math import sqrt
from time import now

alias type = DType.int32

struct Array:
    var data: DTypePointer[type]
    var size: Int

    fn __init__(inout self, size: Int):
        self.data = DTypePointer[type].alloc(size)
        self.size = size
        memset_zero(self.data, size)

    fn __init__(inout self, data: DTypePointer[type], size: Int):
        self.data = data
        self.size = size

    fn arange(self):
        for i in range(self.size):
            self.__setitem__(i, i)

    fn __getitem__(self, idx: Int) -> Scalar[type]:
        return self.data[idx]

    fn __setitem__(self, idx: Int, val: Scalar[type]):
        self.data[idx] = val

    fn printNonZero(self):
        for i in range(self.size):
            if self.__getitem__(i) != 0:
                print(self.__getitem__(i))

"""sieve = np.ones(number+1, dtype=np.uint8)
    sieve[0] = sieve[1] = False

    for i in range(2, int(number**0.5)+1):
        if sieve[i]:
            sieve[i*i::i] = False

    return np.nonzero(sieve)"""

fn calcPrimes(n: Int):
    var primes: Array = Array(n)
    primes.arange()
    primes[1] = 0

    @parameter
    fn sieve(step: Int):
        if primes[step] != 0:
            for i in range(step*step, n, step):
                primes[i] = 0
#                print(k, i, step)
    
    var end: Int = sqrt(n)+1
    parallelize[sieve](end, end)

    #primes.printNonZero()

fn main():
    var sum: Float64 = 0
    for i in range(100):
        var start = now()
        calcPrimes(10000000)
        sum += (now() - start) / 1e9
    
    print(sum / 100)