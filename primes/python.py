from time import time
from sympy import primerange
import numpy as np
import sys
import cProfile
np.set_printoptions(threshold=sys.maxsize)

def timer(func, number, iterations):
    times = []
    for _ in range(iterations):
        startTime = time()
        func(number)
        times.append(time() - startTime)
    print("--- %s seconds average for %s iterations ---" % ((sum(times) / iterations), iterations))

def mathematical(number):
    print(1)
    print(2)

    i = 3
    n = 2
    while i < number:
        n = (n - 1) * (i-1) * (i-2) + 1
        if (n % i) == 0:
            print(i)
        i += 2

def firstMe(number):
    i = 3
    n = 1
    while i < number:
        isPrime = True

        for k in range(3, i//n+1, 2):
            if i % k == 0:
                isPrime = False
                break
        if isPrime:
            print(i)

        i += 2
        if i > n**2:
            n += 2

def me(number):
    def check():
        for k in primes[:n+1]:
            if i % k == 0:
                return False
        return True

    primes = []
    i = 5
    n = 0
    while i < number:
        if check():
            #print(i)
            primes.append(i)

        i += 2

        if check():
            #print(i)
            primes.append(i)

        i += 4

        if i > primes[n]**2:
            n += 1

def library(number):
    return [i for i in primerange(number)]

# Define a function that accepts a number as an argument
def chatGPT(number):
  # Create a list of all numbers from 2 to the given number
  numbers = [i for i in range(2, number+1)]

  # Use a for loop to iterate over the numbers in the list
  for i in numbers:
    # If the current number is not prime, remove it from the list
    if i == -1:
      continue
    for j in range(i*i, number+1, i):
      numbers[j-2] = -1

  # Return the list of prime numbers
  return [i for i in numbers if i != -1]

def internet(n):
    """ Input n>=6, Returns a array of primes, 2 <= p < n """
    sieve = np.ones(n//3 + (n%6==2), dtype=bool)
    for i in range(1,int(n**0.5*0.333333333333333)+1):
        if sieve[i]:
            k = 3 * i + 1 | 1
            sieve[int(k*k*0.333333333333333)::2*k] = False
            sieve[k* int((k-2*(i&1)+4) * 0.333333333333333) :: 2*k] = False
    return np.r_[2,3,((3*np.nonzero(sieve)[0][1:]+1)|1)]

def me_and_chatGPT(number):
    sieve = np.ones(number+1, dtype=np.uint8)
    sieve[0] = sieve[1] = False

    for i in range(2, int(number**0.5)+1):
        if sieve[i]:
            sieve[i*i::i] = False

    return np.nonzero(sieve)

# To 10_000_000
# Me: --- 43.81807827949524 seconds ---
# External library: --- 24.6845654964447 seconds ---
# Ai: --- 7.066962003707886 seconds ---
# Internet: --- 0.01201413631439209 seconds ---
# Me and chatGPT: --- 0.036757812261581424 seconds ---
if __name__ == '__main__':
    timer(me_and_chatGPT, 10_000_000, 100)

    #cProfile.run("internet(1_000_000_000)")
    #print(me_and_chatGPT(10_000_000))
    #for i in primes:
    #    print(i)