# Instructions to build and profile

To build with more or less than 4 CPU cores, change `N4` to something
else.

    stack build
    stack exec -- haskell-dnc-mergesort-exe +RTS -l -N4
    threadscope haskell-dnc-mergesort-exe.eventlog
        
# Threadscope results

Threadscope profile also showing spark creation per HEC:

![Threadscope
profile](https://raw.githubusercontent.com/robstewart57/haskell-dnc-mergesort/master/haskell-dnc-mergesort-exe.png)

Spark information 

![Spark stats](https://raw.githubusercontent.com/robstewart57/haskell-dnc-mergesort/master/spark-stats.png)

# Question

As you can see, 32862 sparks are created, but 29215 sparks are being
GC'd. Why are so many sparks GC'd? I'd understand if they fizzle
e.g. because one HEC (in this case HEC3) evaluates thunks before
parallelism has its opportunity. But GC'd sparks suggests that the
`mergeSort` values evaluated at the leaves of the divide-and-conquer
tree are not being consumed to compute the overall sorted result.

1. How can I reduce the number of GC'd sparks, ideally to 0?

2. How can I increase the parallelism efficiency of this
   implementation? Might this relate to question 1?
