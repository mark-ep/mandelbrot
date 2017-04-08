module mandelbrot
	use, intrinsic :: ISO_C_BINDING

	implicit none

	! create arrays for mandelbrot calculations
	!   'prev' stores value of z from last iteration
	complex(8), dimension(:,:), pointer :: z, c, prev
	! create array for tracking which values need to
	!   be updated next iteration
	logical, dimension(:,:), pointer :: active
	! dimensions of data
	integer :: r_count, i_count

	contains

	subroutine mandelbrot_init(r_size, i_size) bind(C)
		! this subroutine allocates memory for the arrays
		implicit none

		! args are integers - from C, so they are values
		!   not pointers
		integer(C_INT), value :: r_size, i_size

		! allocate memory for the arrays
		allocate(c(r_size, i_size))
		allocate(z(r_size, i_size))
		allocate(prev(r_size, i_size))
		allocate(active(r_size, i_size))

		! store the dimensions
		r_count = r_size
		i_count = i_size
	end subroutine

	subroutine set_region(r_min, r_max, i_min, i_max) bind(C)
		! this function sets the area of the mandelbrot set
		!   to calculate, and resets the working variables
		implicit none

		! args are C doubles, so values not pointers
		real(C_DOUBLE), value :: r_min, r_max, i_min, i_max
		! this array will store the range of real vals
		real(8), dimension(r_count) :: real_vals
		! this array will store the range of imaginary vals
		real(8), dimension(i_count) :: imag_vals
		! these two doubles are the step between values
		real(8) :: real_interval, imag_interval
		! these ints are iteration variables
		integer :: r, i

		! calculate step sizes
		real_interval = (r_max - r_min) / r_count
		imag_interval = (i_max - i_min) / i_count

		! create values for real components
		real_vals = (/((real_interval * i), i=1,r_count)/)
		real_vals = real_vals + r_min
		! create values for imag components
		imag_vals = (/((imag_interval * i), i=1,i_count)/)
		imag_vals = imag_vals + i_min

		! iterate over the array
		do r=1,r_count
			do i=1,i_count
				! set each value of 'c'
				c(r, i) = cmplx(real_vals(r), imag_vals(i))
			end do
		end do

		! reset the 'active' array
		active = .true.
		! reset 'z' and 'prev'
		z = cmplx(0, 0)
		prev = z
	end subroutine

	subroutine update(changed) bind(C)
		! this function iterates the mandelbrot algorithm and
		!   returns which cells have left the set this iter.
		implicit none
		! the argument is a C boolean array
		logical(C_BOOL), dimension(r_count, i_count), intent(inout) :: changed

		! only update where we need to
		where (active)
			! compute new value for 'z'
			z = (z * z) + c
			! if the new value is outside the set,
			!   set its cell in 'changed' to 'true'
			changed = abs(z) > 2
		elsewhere
			! if it isn't active then it can't have changed
			changed = .false.
		end where

		! everywhere that has been changed no longer
		!   needs to be updated, so set active to 'false'
		where (changed)
			active = .false.
		end where

		! if the value of 'z' hasn't changed from last
		!   iteration and cell is still active, then
		!   set active to 'false'
		where ((z .eq. prev) .and. active)
			active = .false.
		end where

		! update previous values
		prev = z
	end subroutine

	subroutine update_colours(updates, colour, surface) bind(C)
		! this function sets all values in 'surface' which
		!   correspond to the changes in 'updates' to 'colour'
		implicit none

		! 'updates' is a C boolean array
		logical(C_BOOL), dimension(r_count, i_count), intent(inout) :: updates
		! 'surface' is an array of C ints
		integer(C_INT), dimension(r_count, i_count), intent(inout) :: surface
		! 'colour' is a C int
		integer(C_INT), value :: colour

		! everywhere that's changed needs to have a colour set
		where(updates)
			surface = colour
		end where
	end subroutine

	subroutine reset_changes(updates) bind(C)
		! resets the 'updates' array
		implicit none

		logical(C_BOOL), dimension(r_count, i_count), intent(inout) :: updates

		updates = .true.
	end subroutine
end module
