#include <SDL/SDL.h>
#include <cstdlib>
#include <cstdio>

using namespace std;

// provide c++ with a definition for the fortran colour type
extern "C" struct colour {int r, g, b;};
// shorten name from 'struct colour' to 'colour'
typedef struct colour colour;

// provide c++ with prototypes of fortran functions
extern "C" {
	// initialilization function
	void mandelbrot_init(int r_size, int i_size);
	// update region function
	void set_region(double r_min, double r_max, double i_min, double i_max);
	// find changes
	void update(bool* changes);

	// load colour table
	void init_colours(int max_value);
	// get a colour from the table
	colour get_colour(int index);

	// update pixels
	void update_colours(bool* updates, Uint32 col, void* surface);
	// reset the screen
	void reset_changes(bool* updates);

	void cubehelix(double start, double rots, double hue, double gamma, int nlev);
}

bool file_exists(const char* fname) {
    FILE *file;
    if (file = fopen(fname, "r")) {
        fclose(file);
        return true;
    }
    return false;
}
int screenshot_name(int index, char* name) {
	return sprintf(name, "mandelbrot_%03d.png", index);
}
int get_screenshot_index() {
	char name[20];
	int index = -1;
	do {
		index++;
		screenshot_name(index, name);
	} while(file_exists(name));

	return index;
}

int main(int argc, char* argv[]) {
	// initialize sdl
	SDL_Init(SDL_INIT_EVERYTHING);

	// create the screen surface
	//   by setting width & height to 0, SDL will fit it the screen resolution
	SDL_Surface* screen = SDL_SetVideoMode(0, 0, 32, SDL_SWSURFACE | SDL_FULLSCREEN);
	// check that it's worked - quit if not
	if (screen == NULL)
		return 1;
	// set the window caption
	SDL_WM_SetCaption("mandelbrot", NULL);

	// get the screen dimensions
	int wsize = screen->w;
	int hsize = screen->h;
	// tell fortran how big the arrays need to be
	mandelbrot_init(wsize, hsize);
	// find initial mandelbrot region
	//   set real range to [-1.5, 0.5]
	double r_min = -1.5, r_max = 0.5;
	//   get aspect ratio of screen (height:width)
	double aspect = (double)hsize / (double)wsize;
	//   set imaginary range to +/- aspect ratio
	//     (ensures that the image isn't stretched)
	double i_min = -aspect, i_max = aspect;
	// get fortran to set the region size
	set_region(r_min, r_max, i_min, i_max);
	// get fortran to load the colour table
	//init_colours(255);
	cubehelix(0, 3, 1.0, 1.0, 1000);

	bool running = true;
	SDL_Event e;

	int updates = 0;

	// create the array we'll use to track updates
	bool* values = (bool*) malloc(sizeof(bool) * wsize * hsize);

	// initialize the array
	reset_changes(values);

	Uint32 white = SDL_MapRGB(screen->format, 0xff, 0xff, 0xff);
	update_colours(values, white, screen->pixels);

	while (running) {
		// check SDL for input events
		while( SDL_PollEvent( &e ) != 0 ) {
			//User requests quit
			if( e.type == SDL_QUIT ) {
				running = false;
			}
			// escape key pressed?
			else if( e.type == SDL_KEYUP ) {
				switch(e.key.keysym.sym) {
					case SDLK_ESCAPE:
						running = false;
						break;
					case SDLK_PRINT:
						char fname[20];
						int n = get_screenshot_index();
						screenshot_name(n, fname);
						SDL_SaveBMP(screen, fname);
						break;
				}
			}
			else if (e.type == SDL_MOUSEBUTTONUP) {
				int x, y;
				// find location of click
				SDL_GetMouseState(&x, &y);
				// get x & y as ratios of screen dimensions
				double fx = (double)x / (double)wsize;
				double fy = (double)y / (double)hsize;
				// get ranges of real & imag values
				double rrange = (r_max - r_min);
				double irange = (i_max - i_min);
				// find complex value of location clicked on
				double real = fx * rrange + r_min;
				double imag = fy * irange + i_min;

				// has the user left-clicked?
				if(e.button.button == SDL_BUTTON_LEFT) {
					// quarter the ranges
					double rquart = rrange / 4;
					double iquart = irange / 4;
					// set new region
					r_min = real - rquart;
					r_max = real + rquart;
					i_min = imag - iquart;
					i_max = imag + iquart;
				}
				// have they right-clicked?
				else if (e.button.button = SDL_BUTTON_RIGHT) {
					// set new region
					r_min = real - rrange;
					r_max = real + rrange;
					i_min = imag - irange;
					i_max = imag + irange;
				}
				// otherwise, it's a middle click so we should ignore it
				else continue;
				// update the region
				set_region(r_min, r_max, i_min, i_max);
				// clear the screen
				Uint32 black = SDL_MapRGB(screen->format, 0xff, 0xff, 0xff);
				reset_changes(values);

				SDL_LockSurface(screen);
				update_colours(values, black, screen->pixels);
				SDL_UnlockSurface(screen);
				// reset iteration counter
				updates = 0;
			}
		}
		// check if we've reached full colour range
		if (updates < 1000) {
			// if not, find the changes for this iteration
			update(values);
			// increment the number of updates
			updates++;
			// get the new colour from the colour table
			colour c = get_colour(updates);
			// get SDL to convert it to a Uint32
			Uint32 col = SDL_MapRGB(screen->format, c.r, c.g, c.b);

			// lock the screen surface
			SDL_LockSurface(screen);
			// get fortran to set the pixel values directly
			update_colours(values, col, screen->pixels);
			// unlock the screen
			SDL_UnlockSurface(screen);
		}
		// update the screen
		if (SDL_Flip(screen) == -1)
			return 1;
		SDL_Delay(1);
	}
	// free the updates array
	free(values);
	// close SDL
	SDL_Quit();
	return 0;
}
