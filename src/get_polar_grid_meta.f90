!-------------------------------------------------------------------------
! National Center for Atmospheric Research
! Research Applications Laboratory
!-------------------------------------------------------------------------

subroutine get_polar_grid_meta(len1,fileIn,nx,ny,dx,dy,lat1,lon1,lonv, &
                               snFlag,iret)

  include "regrid_header.h"
  !DESCRIPTION:
  ! Subroutine that opens a GRIB file and extracts meta data about
  ! the polar stereographic grid contained. Meta data is pulled
  ! based on the first message (variable). This subroutine assumes
  ! all variables in the GRIB file are on the same grid. Arguments are
  ! as follows:
  ! len1 - Length of the character string fileIn. This is needed to properly
  !        read in character strings. 
  ! fileIn - Character string of GRIB file name to be read.
  ! nx - Integer of the number of columns of the GRIB data.
  ! ny - Integer of the number of rows of the GRIB data.
  ! dx - Integer of the resolution in the x-direction (meters) of the GRIB data.
  ! dy - Integer of the resolution in the y-direction (meters) of the GRIB data.
  ! lat1 - FLoat of the lower left pixel cell latitude in degrees of the GRIB data.
  ! lon1 - Float of the lower left pixel cell longitude in degrees of the 
  !        GRIB data.
  ! lonv - Float of the orientation longitude of the GRIB data domain. 
  ! snFlag - Integer indicating if data is read south-north or north-south. 
  !          1 - Data read south-north
  !          0 - Data read north-south 
  ! iret - Error value out. 0 for success. Greater than 0 for error. 

  !AUTHOR:
  ! Logan Karsten
  ! National Center for Atmospheric Research
  ! Research Applications Laboratory
  ! 303-497-2693
  ! karsten@ucar.edu

  !USES:
  #if REGRID_FLAG != 0
    use grib_api
  #endif

  implicit none
  
  !ARGUMENTS:
  integer, intent(in)         :: len1
  character(len1), intent(in) :: fileIn
  integer, intent(inout)      :: nx, ny, dx, dy
  real*8, intent(inout)       :: lat1, lon1, lonv
  integer, intent(inout)      :: snFlag
  integer, intent(inout)      :: iret 

  !LOCAL VARIABLES:
  integer :: ftn, nvars, igrib
  logical :: file_exists
  integer :: radius, gdef
  integer :: edition

  !Inquire for file existence
  inquire(file=trim(fileIn),exist=file_exists)
 
  #if REGRID_FLAG != 0 
    if(file_exists) then
      !Open GRIB file
      call grib_open_file(ftn,trim(fileIn),'r',iret)
      if(iret .ne. 0) return
    else
      iret = 1
      return
    endif

    !Pull the first message (variable) as we are only interested in grid metadata.
    call grib_count_in_file(ftn,nvars,iret)
    if(nvars .le. 0) then
      iret = 2
      return
    else
      !Pull grid metadata from first message
      call grib_new_from_file(ftn,igrib,iret)
      if(iret .ne. 0) return
 
      !Get GRIB edition number 
      call grib_get(igrib,'editionNumber',edition,iret)
      if(iret .ne. 0) return

      !Unfortunately, GRIB 1 files do not contain grid definition information for checking. 
      !Proceed with caution....
   
      !Sanity check to double check grid is polar stereographic and has an assumed
      !spherical Earth radius. If not, throw a error back to R for 
      !diagnostics.
      if(edition .eq. 2) then
        call grib_get(igrib,'gridDefinitionTemplateNumber',gdef,iret)
        if(iret .ne. 0) return
      else
        gdef = 20
        iret = 0 !GRIB1 no check
      endif
      if (gdef .ne. 20) then
        iret = 20
        return
      else
        if(edition .eq. 2) then
          call grib_get(igrib,'shapeOfTheEarth',radius,iret)
          if(iret .ne. 0) return
        else
          radius = 6
          iret = 0
        endif
        if (radius .ne. 6) then
          iret = 6
          return
        endif
      endif

      if (iret .eq. 0) then !Extract meta data
        call grib_get(igrib,'latitudeOfFirstGridPointInDegrees',lat1,iret)
        if(iret .ne. 0) return 
        call grib_get(igrib,'longitudeOfFirstGridPointInDegrees',lon1,iret)
        if(iret .ne. 0) return
        call grib_get(igrib,'orientationOfTheGridInDegrees',lonv,iret)
        if(iret .ne. 0) return
        call grib_get(igrib,'DxInMetres',dx,iret)
        if(iret .ne. 0) return
        call grib_get(igrib,'DyInMetres',dy,iret)
        if(iret .ne. 0) return
        call grib_get(igrib,'Nx',nx,iret)
        if(iret .ne. 0) return
        call grib_get(igrib,'Ny',ny,iret)
        if(iret .ne. 0) return
        call grib_get(igrib,'jScansPositively',snFlag,iret)
        if(iret .ne. 0) return
      endif
    endif

    !Close GRIB file
    call grib_close_file(ftn,iret)
    if(iret .ne. 0) return
  #else
    iret = -99
    return
  #endif

end subroutine get_polar_grid_meta
