module colours
	use, intrinsic :: ISO_C_BINDING

	implicit none

	! this type represents an RGB colour
	type, bind(C) :: colour
		integer(C_INT) :: r, g, b
	end type

	! parameters: file identifier, and number of colours
	integer, parameter :: fid = 10, n_colours = 360
	! this array will store the colour table
	type(colour), dimension(:), allocatable :: table
	! the name of the csv file containing colour data
	character(*), parameter :: fname = "chelix.csv"

	contains

	subroutine init_colours(max_value) bind(C)
		! load the colours from the file
		implicit none

		! 'max_value' is the largest value in a channel (e.g: 255)
		integer(C_INT), value :: max_value
		! variables for line no. and status
		integer :: index, stat
		! this array will store each line of data
		real, dimension(4) :: vals

		! open the file for reading
		open(fid, file=fname, status="old", action="read")
		allocate(table(n_colours))

		do index=1, n_colours
			! read a line from the file into 'vals'
			read(fid, *, iostat=stat) vals(:)

			if (stat .lt. 0) then
				! status < 0: end of file
				write(*,*) "only", index, "entries read"
				! stop reading
				exit
			else if (stat .gt. 0) then
				! status > 0: some other error
				write(*,*) "error reading ", fname
				! stop reading
				exit
			end if

			! set the entry in the colour table
			table(index)%r = floor(vals(2) * max_value)
			table(index)%g = floor(vals(3) * max_value)
			table(index)%b = floor(vals(4) * max_value)
		end do

		! close the file
		close(fid)
	end subroutine

	type(colour) function get_colour(index) bind(C)
		! returns a colour from the table
		implicit none
		! argument in a C int in range 1:n_colours
		integer(C_INT), value :: index
		! return the requested colour struct
		get_colour = table(index)
	end function

	subroutine cubehelix(start, rots, hue, gamma, nlev) bind(C)
		integer(C_INT), value :: nlev
		real(C_DOUBLE), value :: start, rots, hue, gamma

		real(8) :: pi, fract, angle, amp, r, g, b
		integer :: i, max_value = 255

		pi = 4.0*atan(1.0)

		allocate(table(nlev))

		do i=1, nlev
			fract = float(i-1) / float(nlev-1)
			angle = 2 * pi * (start/3.0 + 1.0 + rots*fract)
			
			fract = fract ** gamma
			amp = hue * fract * (1 - fract) / 2.0

			r = fract + amp * (-0.14861*cos(angle) + 1.78277*sin(angle))
        	g = fract + amp * (-0.29227*cos(angle) - 0.90649*sin(angle))
        	b = fract + amp * (+1.97294*cos(angle))

        	if (r .lt. 0.0) then
        		r = 0.0
        	else if (r .gt. 1.0) then
        		r = 1.0
        	end if

        	if (g .lt. 0.0) then
        		g = 0.0
        	else if (g .gt. 1.0) then
        		g = 1.0
        	end if

        	if (b .lt. 0.0) then
        		b = 0.0
        	else if (b .gt. 1.0) then
        		b = 1.0
        	end if

        	table(i)%r = floor(r * max_value)
        	table(i)%g = floor(g * max_value)
        	table(i)%b = floor(b * max_value)
        end do

	end subroutine
end module colours
