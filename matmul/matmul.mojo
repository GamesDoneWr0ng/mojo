from random import rand
import autotune
from algorithm import vectorize, parallelize
from algorithm import Static2DTileUnitFunc as Tile2DFunc
import benchmark

alias type = DType.float32

struct Matrix[rows: Int, cols: Int]:
    var data: DTypePointer[type]

    fn __init__(inout self):
        self.data = DTypePointer[type].alloc(rows * cols)
        memset_zero(self.data, rows * cols)

    fn __init__(inout self, data: DTypePointer[type]):
        self.data = data

    @staticmethod
    fn rand() -> Self:
        var data = DTypePointer[type].alloc(rows * cols)
        rand(data, rows * cols)
        return Self(data)

    fn __getitem__(self, y: Int, x: Int) -> Scalar[type]:
        return self.load[1](y, x)

    fn __setitem__(self, y: Int, x: Int, val: Scalar[type]):
        self.store[1](y, x, val)

    fn load[nelts: Int](self, y: Int, x: Int) -> SIMD[type, nelts]:
        return self.data.load[width=nelts](y * self.cols + x)

    fn store[nelts: Int](self, y: Int, x: Int, val: SIMD[type, nelts]):
        return self.data.store[width=nelts](y * self.cols + x, val)

fn matmul_naive(C: Matrix, A: Matrix, B: Matrix):
    for m in range(C.rows):
        for k in range(A.cols):
            for n in range(C.cols):
                C[m, n] += A[m, k] * B[k, n]

alias nelts = simdwidthof[type]() * 2

fn matmul_vectorized_0(C: Matrix, A: Matrix, B: Matrix):
    for m in range(C.rows):
        for k in range(A.cols):
            for nv in range(0, C.cols - nelts + 1, nelts):
                C.store(m, nv, C.load[nelts](m, nv) + A[m, k] * B.load[nelts](k, nv))

            for n in range(nelts * (C.cols //nelts), C.cols):
                C[m, n] += A[m, k] * B[k, n]

fn matmul_vectorized_1(C: Matrix, A: Matrix, B: Matrix):
    for m in range(C.cols):
        for k in range(A.cols):
            @parameter
            fn dot[nelts: Int](n: Int):
                C.store(m, n, C.load[nelts](m, n) + A[m, k] * B.load[nelts](k, n))
            vectorize[dot, nelts, size = C.cols]()

fn matmul_parallelized(C: Matrix, A: Matrix, B: Matrix):
    @parameter
    fn calc_row(m: Int):
        for k in range(A.cols):
            @parameter
            fn dot[nelts: Int](n: Int):
                C.store(m, n, C.load[nelts](m, n) + A[m, k] * B.load[nelts](k, n))
            vectorize[dot, nelts, size = C.cols]()
    parallelize[calc_row](C.cols, C.cols)

fn tile[tiled_fn: Tile2DFunc, tile_x: Int, tile_y: Int](end_x: Int, end_y: Int):
    for y in range(0, end_y, tile_y):
        for x in range(0, end_x, tile_x):
            tiled_fn[tile_x, tile_y](x, y)

fn matmul_tiled_parallelized(C: Matrix, A: Matrix, B: Matrix):
    @parameter
    fn calc_row(m: Int):
        @parameter
        fn calc_tile[tile_x: Int, tile_y: Int](x: Int, y: Int):
            for k in range(y, y + tile_y):
                @parameter
                fn dot[nelst: Int](n: Int):
                    C.store(m, n, C.load[nelts](m, n) + A[m, k] * B.load[nelts](k, n))
                vectorize[dot, nelts, size = C.cols]()

        alias tileSize = 128
        tile[calc_tile, nelts * tileSize, tileSize](A.cols, B.cols)

    parallelize[calc_row](C.cols, C.cols)


alias M = 1024
alias N = 1024
alias K = 1024

@always_inline
fn bench[
    func: fn (Matrix, Matrix, Matrix) -> None](base_gflops: Float64):
    var C = Matrix[M, N]()
    var A = Matrix[M, K].rand()
    var B = Matrix[K, N].rand()

    @always_inline
    @parameter
    fn test_fn():
        _ = func(C, A, B)

    var secs = benchmark.run[test_fn](max_runtime_secs=1).mean()

    A.data.free()
    B.data.free()
    C.data.free()

    var gflops = ((2 * M * N * K) / secs) / 1e9
    var speedup: Float64 = gflops / base_gflops

    print(gflops, "GFLOP/s, a", speedup, "x speedup over Python")

fn main():
    var python_gflops = 0.0022177995614993855
    bench[matmul_naive](python_gflops)
    bench[matmul_vectorized_0](python_gflops)
    bench[matmul_vectorized_1](python_gflops)
    bench[matmul_parallelized](python_gflops)
    bench[matmul_tiled_parallelized](python_gflops)