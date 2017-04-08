# mandelbrot

This is a simple Mandelbrot renderer written in Fortan and C++

The core computation is performed by the Fortran code, but the visualisation is rendered using SDL in C++.

## building

To build, use the Makefile included in the project. This requires gfortran, gcc, and the SDL development libraries to be installed

## running

The program runs in fullscreen, at the native resolution.

- <kbd>left-click</kbd> to zoom in (on the cursor position)
- <kbd>right-click</kbd> to zoom out
- <kbd>prt sc</kbd> saves a screenshot to the current directory
- <kbd>esc</kbd> quits
