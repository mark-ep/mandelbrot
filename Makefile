mandelbrot: main.o mandelbrot.o colour.o
	gfortran -o mandelbrot main.o mandelbrot.o colour.o -lSDL

main.o:
	gcc -c main.cpp

mandelbrot.o:
	gfortran -c mandelbrot.f03

colour.o:
	gfortran -c colour.f03

clean:
	rm mandelbrot main.o mandelbrot.o colour.o
