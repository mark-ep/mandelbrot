# mandelbrot

This is a simple Mandelbrot renderer written in Fortan and C++

The core computation is performed by the Fortran code, but the visualisation is rendered using SDL in C++.

To build, use the Makefile included in the project. This requires gfortran, gcc, and the SDL development libraries to be installed
