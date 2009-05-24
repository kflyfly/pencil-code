! $Id$

module Initcond

!  This module contains code used by the corresponding physics
!  modules to set up various initial conditions (stratitication,
!  perturbations, and other structures). This module is not used
!  during run time (although it is used by the physics modules that
!  are used both during run time and for the initial condition).

  use Cdata
  use General
  use Mpicomm
  use Sub, Only : erfunc
  implicit none

  private
  public :: arcade_x, vecpatternxy,  bipolar
  public :: soundwave,sinwave,sinwave_phase,coswave,coswave_phase,cos_cos_sin
  public :: hatwave
  public :: gaunoise, posnoise
  public :: gaunoise_rprof
  public :: gaussian, gaussian3d, beltrami, rolls, tor_pert
  public :: jump, bjump, bjumpz, stratification, stratification_x
  public :: modes, modev, modeb, crazy
  public :: trilinear, baroclinic
  public :: diffrot, olddiffrot
  public :: const_omega
  public :: powern, power_randomphase
  public :: planet, planet_hc
  public :: random_isotropic_KS
  public :: htube, htube2, htube_x, hat, hat3d
  public :: htube_erf
  public :: wave_uu, wave, parabola
  public :: sinxsinz, cosx_cosy_cosz, cosx_coscosy_cosz
  public :: x_siny_cosz, x1_siny_cosz, x1_cosy_cosz, lnx_cosy_cosz
  public :: sinx_siny_sinz, cosx_siny_cosz, sinx_siny_cosz
  public :: sin2x_sin2y_cosz, cosy_sinz, x3_cosy_cosz, cos2x_cos2y_cos2z
  public :: halfcos_x, magsupport, vfield
  public :: uniform_x, uniform_y, uniform_z, uniform_phi, phi_comp_over_r
  public :: vfluxlayer, hfluxlayer
  public :: vortex_2d
  public :: vfield2
  public :: hawley_etal99a
  public :: robertsflow
  public :: set_thermodynamical_quantities
  public :: const_lou
  public :: corona_init,mdi_init
  public :: innerbox
  public :: couette, couette_rings

  interface posnoise            ! Overload the `posnoise' function
    module procedure posnoise_vect
    module procedure posnoise_scal
  endinterface

  interface gaunoise            ! Overload the `gaunoise' function
    module procedure gaunoise_vect
    module procedure gaunoise_scal
    module procedure gaunoise_prof_vect
    module procedure gaunoise_prof_scal
  endinterface

  interface gaunoise_rprof      ! Overload the `gaunoise_rprof' function
    module procedure gaunoise_rprof_vect
    module procedure gaunoise_rprof_scal
  endinterface

  character(LEN=labellen) :: wave_fmt1='(1x,a,4f8.2)'

  contains

!***********************************************************************
    subroutine sinxsinz(ampl,f,i,kx,ky,kz,KKx,KKy,KKz)
!
!  sinusoidal wave. Note: f(:,:,:,j) with j=i+1 is set.
!
!  26-jul-02/axel: coded
!
      integer :: i,j
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: kx,ky,kz,KKx,KKy,KKz
      real :: ampl,kx1=pi/2.,ky1=0.,kz1=pi/2.,KKx1=0.,KKy1=0.,KKz1=0.
!
!  wavenumber k, helicity H=ampl (can be either sign)
!
!  sinx(kx*x)*sin(kz*z)
!
      if (present(kx)) kx1=kx
      if (present(ky)) ky1=ky
      if (present(kz)) kz1=kz
!
!  Gaussian scake heights
!
      if (present(KKx)) KKx1=KKx
      if (present(KKy)) KKy1=KKy
      if (present(KKz)) KKz1=KKz
!
      if (ampl==0) then
        if (lroot) print*,'sinxsinz: ampl=0 in sinx*sinz wave; kx,kz=',kx1,kz1
      else
        if (lroot) print*,'sinxsinz: sinx*sinz wave; ampl,kx,kz=',ampl,kx1,kz1
        j=i+1
        f(:,:,:,j)=f(:,:,:,j)+ampl*(&
          spread(spread(cos(kx1*x)*exp(-.5*(KKx1*x)**2),2,my),3,mz)*&
          spread(spread(cos(ky1*y)*exp(-.5*(KKy1*y)**2),1,mx),3,mz)*&
          spread(spread(cos(kz1*z)*exp(-.5*(KKz1*z)**2),1,mx),2,my))
      endif
!
    endsubroutine sinxsinz
!***********************************************************************
    subroutine sinx_siny_sinz(ampl,f,i,kx,ky,kz)
!
!  sinusoidal wave, adapted from sinxsinz (that routine was already doing
!  this, but under a different name)
!
!  20-jan-07/axel: adapted
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: kx,ky,kz
      real :: ampl,kx1=pi/2.,ky1=0.,kz1=pi/2.
!
!  wavenumber k, helicity H=ampl (can be either sign)
!
!  sinx(kx*x)*sin(kz*z)
!
      if (present(kx)) kx1=kx
      if (present(ky)) ky1=ky
      if (present(kz)) kz1=kz
      if (ampl==0) then
        if (lroot) print*,'sinx_siny_sinz: ampl=0'
      else
        if (lroot) write(*,wave_fmt1) 'sinx_siny_sinz: ampl,kx,ky,kz=', &
                                      ampl,kx1,ky1,kz1
        f(:,:,:,i)=f(:,:,:,i)+ampl*(spread(spread(sin(kx1*x),2,my),3,mz)&
                                   *spread(spread(sin(ky1*y),1,mx),3,mz)&
                                   *spread(spread(sin(kz1*z),1,mx),2,my))
      endif
!
    endsubroutine sinx_siny_sinz
!***********************************************************************
    subroutine sinx_siny_cosz(ampl,f,i,kx,ky,kz)
!
!  sinusoidal wave, adapted from sinxsinz (that routine was already doing
!  this, but under a different name)
!
!   2-dec-03/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: kx,ky,kz
      real :: ampl,kx1=pi/2.,ky1=0.,kz1=pi/2.
!
!  wavenumber k, helicity H=ampl (can be either sign)
!
!  sinx(kx*x)*sin(kz*z)

      if (present(kx)) kx1=kx
      if (present(ky)) ky1=ky
      if (present(kz)) kz1=kz
      if (ampl==0) then
        if (lroot) print*,'sinx_siny_cosz: ampl=0'
      else
        if (lroot) write(*,wave_fmt1) 'sinx_siny_cosz: ampl,kx,ky,kz=', &
                                      ampl,kx1,ky1,kz1
        f(:,:,:,i)=f(:,:,:,i)+ampl*(spread(spread(sin(kx1*x),2,my),3,mz)&
                                   *spread(spread(sin(ky1*y),1,mx),3,mz)&
                                   *spread(spread(cos(kz1*z),1,mx),2,my))
      endif
!
    endsubroutine sinx_siny_cosz
!***********************************************************************
    subroutine x_siny_cosz(ampl,f,i,kx,ky,kz)
!
!  sinusoidal wave, adapted from sinxsinz (that routine was already doing
!  this, but under a different name)
!
!   2-dec-03/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: kx,ky,kz
      real :: ampl,kx1=pi/2.,ky1=0.,kz1=pi/2.
!
!  wavenumber k, helicity H=ampl (can be either sign)
!
!  sinx(kx*x)*sin(kz*z)
!
      if (present(kx)) kx1=kx
      if (present(ky)) ky1=ky
      if (present(kz)) kz1=kz
      if (ampl==0) then
        if (lroot) print*,'x_siny_cosz: ampl=0'
      else
        if (lroot) write(*,wave_fmt1) 'x_siny_cosz: ampl,kx,ky,kz=', &
                                      ampl,kx1,ky1,kz1
        f(:,:,:,i)=f(:,:,:,i)+ampl*(spread(spread(   (    x),2,my),3,mz)&
                                   *spread(spread(sin(ky1*y),1,mx),3,mz)&
                                   *spread(spread(cos(kz1*z),1,mx),2,my))
      endif
!
    endsubroutine x_siny_cosz
!***********************************************************************
    subroutine x1_siny_cosz(ampl,f,i,kx,ky,kz,phasey)
!
!  sinusoidal wave, adapted from sinxsinz (that routine was already doing
!  this, but under a different name)
!
!   2-dec-03/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: kx,ky,kz,phasey
      real :: ampl,kx1=pi/2.,ky1=0.,kz1=pi/2., phasey1=0.
!
!  wavenumber k, helicity H=ampl (can be either sign)
!
!  sinx(kx*x)*sin(kz*z)
!
      if (present(kx)) kx1=kx
      if (present(ky)) ky1=ky
      if (present(kz)) kz1=kz
      if (present(phasey)) phasey1=phasey
      if (ampl==0) then
        if (lroot) print*,'x1_siny_cosz: ampl=0'
      else
        if (lroot) write(*,wave_fmt1) 'x1_siny_cosz: ampl,kx,ky,kz=', &
                                      ampl,kx1,ky1,kz1
        f(:,:,:,i)=f(:,:,:,i)+ampl*(spread(spread(   ( 1./x),2,my),3,mz)&
                                   *spread(spread(sin(ky1*y+phasey1),1,mx),3,mz)&
                                   *spread(spread(cos(kz1*z),1,mx),2,my))
      endif
!
    endsubroutine x1_siny_cosz
!***********************************************************************
    subroutine x1_cosy_cosz(ampl,f,i,kx,ky,kz)
!
!  sinusoidal wave, adapted from sinxsinz (that routine was already doing
!  this, but under a different name)
!
!   1-jul-07/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: kx,ky,kz
      real :: ampl,kx1=pi/2.,ky1=0.,kz1=pi/2.
!
!  wavenumber k, 1/x radial profile
!
      if (present(kx)) kx1=kx
      if (present(ky)) ky1=ky
      if (present(kz)) kz1=kz
      if (ampl==0) then
        if (lroot) print*,'x1_siny_cosz: ampl=0'
      else
        if (lroot) write(*,wave_fmt1) 'x1_siny_cosz: ampl,kx,ky,kz=', &
                                      ampl,kx1,ky1,kz1
        f(:,:,:,i)=f(:,:,:,i)+ampl*(spread(spread(   ( 1./x),2,my),3,mz)&
                                   *spread(spread(cos(ky1*y),1,mx),3,mz)&
                                   *spread(spread(cos(kz1*z),1,mx),2,my))
      endif
!
    endsubroutine x1_cosy_cosz
!***********************************************************************
    subroutine lnx_cosy_cosz(ampl,f,i,kx,ky,kz)
!
!  sinusoidal wave, adapted from sinxsinz (that routine was already doing
!  this, but under a different name)
!
!   2-jul-07/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: kx,ky,kz
      real :: ampl,kx1=pi/2.,ky1=0.,kz1=pi/2.
!
!  wavenumber k, 1/x radial profile
!
      if (present(kx)) kx1=kx
      if (present(ky)) ky1=ky
      if (present(kz)) kz1=kz
      if (ampl==0) then
        if (lroot) print*,'lnx_cosy_cosz: ampl=0'
      else
        if (lroot) write(*,wave_fmt1) 'lnx_cosy_cosz: ampl,kx,ky,kz=', &
                                      ampl,kx1,ky1,kz1
        f(:,:,:,i)=f(:,:,:,i)+ampl*(spread(spread(alog(   x),2,my),3,mz)&
                                   *spread(spread(cos(ky1*y),1,mx),3,mz)&
                                   *spread(spread(cos(kz1*z),1,mx),2,my))
      endif
!
    endsubroutine lnx_cosy_cosz
!***********************************************************************
    subroutine cosx_siny_cosz(ampl,f,i,kx,ky,kz)
!
!  sinusoidal wave, adapted from sinxsinz (that routine was already doing
!  this, but under a different name)
!
!  15-mar-07/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: kx,ky,kz
      real :: ampl,kx1=pi/2.,ky1=0.,kz1=pi/2.
!
!  wavenumber k, helicity H=ampl (can be either sign)
!
!  sinx(kx*x)*sin(kz*z)
!
      if (present(kx)) kx1=kx
      if (present(ky)) ky1=ky
      if (present(kz)) kz1=kz
      if (ampl==0) then
        if (lroot) print*,'cosx_siny_cosz: ampl=0'
      else
        if (lroot) write(*,wave_fmt1) 'cosx_siny_cosz: ampl,kx,ky,kz=', &
                                      ampl,kx1,ky1,kz1
        f(:,:,:,i)=f(:,:,:,i)+ampl*(spread(spread(cos(kx1*x),2,my),3,mz)&
                                   *spread(spread(sin(ky1*y),1,mx),3,mz)&
                                   *spread(spread(cos(kz1*z),1,mx),2,my))
      endif
!
    endsubroutine cosx_siny_cosz
!***********************************************************************
    subroutine sin2x_sin2y_cosz(ampl,f,i,kx,ky,kz)
!
!  sinusoidal wave, adapted from sinxsinz (that routine was already doing
!  this, but under a different name)
!
!   2-dec-03/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: kx,ky,kz
      real :: ampl,kx1=pi/2.,ky1=0.,kz1=pi/2.
!
!  wavenumber k, helicity H=ampl (can be either sign)
!
!  sin2(kx*x)*sin2(kz*z)
!
      if (present(kx)) kx1=kx
      if (present(ky)) ky1=ky
      if (present(kz)) kz1=kz
      if (ampl==0) then
        if (lroot) print*,'sin2x_sin2y_cosz: ampl=0'
      else
        if (lroot) write(*,wave_fmt1) 'sin2x_sin2y_cosz: ampl,kx,ky,kz=',&
                                      ampl,kx1,ky1,kz1
        f(:,:,:,i)=f(:,:,:,i)+ampl*(spread(spread(sin(kx1*x)**2,2,my),3,mz)&
                                   +spread(spread(sin(ky1*y)**2,1,mx),3,mz))&
                                   *spread(spread(cos(kz1*z),1,mx),2,my)
      endif
!
    endsubroutine sin2x_sin2y_cosz
!***********************************************************************
    subroutine cosx_cosy_cosz(ampl,f,i,kx,ky,kz)
!
!  sinusoidal wave, adapted from sinxsinz (that routine was already doing
!  this, but under a different name)
!
!   2-dec-03/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: kx,ky,kz
      real :: ampl,kx1=pi/2.,ky1=0.,kz1=pi/2.
!
!  wavenumber k, helicity H=ampl (can be either sign)
!
!  sinx(kx*x)*sin(kz*z)
!
      if (present(kx)) kx1=kx
      if (present(ky)) ky1=ky
      if (present(kz)) kz1=kz
      if (ampl==0) then
        if (lroot) print*,'cosx_cosy_cosz: ampl=0'
      else
        if (lroot) write(*,wave_fmt1) 'cosx_cosy_cosz: ampl,kx,ky,kz=', &
                                      ampl,kx1,ky1,kz1
        f(:,:,:,i)=f(:,:,:,i)+ampl*(spread(spread(cos(kx1*x),2,my),3,mz)&
                                   *spread(spread(cos(ky1*y),1,mx),3,mz)&
                                   *spread(spread(cos(kz1*z),1,mx),2,my))
      endif
!
    endsubroutine cosx_cosy_cosz
!***********************************************************************
    subroutine cosy_sinz(ampl,f,i,ky,kz)
!
!  initial condition for potential field test
!
!   06-oct-06/axel: coded
!   11-oct-06/wolf: modified to only set one component of aa
!
      integer :: i,j
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: ky,kz
      real :: ampl,ky1=1.,kz1=pi
!
!  wavenumber k
!
      if (present(ky)) ky1=ky
      if (present(kz)) kz1=kz
!
      j=i; f(:,:,:,j)=f(:,:,:,j)+ampl*spread(spread(cos(ky1*y),1,mx),3,mz)&
                                     *spread(spread(sin(kz1*z),1,mx),2,my)
!
!  Axel, are you OK with this? If so, I'll eliminate j above.
!
!  Don't do this: we now call this twice from magnetic.f90, and setting
!  just Ax /= 0 makes perfect sense for potential bc tests.
!
!      j=i+1; f(:,:,:,j)=f(:,:,:,j)+ampl*spread(spread(sin(ky1*y),1,mx),3,mz)&
!                                       *spread(spread(cos(kz1*z),1,mx),2,my)
!
    endsubroutine cosy_sinz
!***********************************************************************
    subroutine x3_cosy_cosz(ampl,f,i,ky,kz)
!
!  special initial condition for producing toroidal field (ndynd decay test)
!
!   06-oct-06/axel: coded
!   11-oct-06/wolf: modified to only set one component of aa
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: ky,kz
      real :: ampl,ky1=1.,kz1=pi
!
!  wavenumber k
!
      if (present(ky)) ky1=ky
      if (present(kz)) kz1=kz
!
      f(:,:,:,i)=f(:,:,:,i)+ampl*spread(spread(x*(1.-x)*(x-.2),2,my),3,mz)&
                                *spread(spread(cos(ky1*y),1,mx),3,mz)&
                                *spread(spread(cos(kz1*z),1,mx),2,my)
!
    endsubroutine x3_cosy_cosz
!***********************************************************************
    subroutine cosx_coscosy_cosz(ampl,f,i,kx,ky,kz)
!
!  sinusoidal wave, adapted from sinxsinz (that routine was already doing
!  this, but under a different name)
!
!   2-dec-03/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: kx,ky,kz
      real :: ampl,kx1=pi/2.,ky1=0.,kz1=pi/2.
!
!  wavenumber k, helicity H=ampl (can be either sign)
!
!  sinx(kx*x)*sin(kz*z)
!
      if (present(kx)) kx1=kx
      if (present(ky)) ky1=ky
      if (present(kz)) kz1=kz
      if (ampl==0) then
        if (lroot) print*,'cosx_cosy_cosz: ampl=0'
      else
        if (lroot) write(*,wave_fmt1) 'cosx_cosy_cosz: ampl,kx,ky,kz=', &
                                      ampl,kx1,ky1,kz1
        f(:,:,:,i)=f(:,:,:,i)+ampl*(spread(spread(cos(kx1*x),2,my),3,mz) &
                                   *spread(spread(-cos(ky1*y)*(          &
                                     ((1./9.)*sin(ky*y)**8)+((8./63.)*   &
                                     sin(ky*y)**6)+((16./105.)*          &
                                     sin(ky*y)**4)+((64./315.)*          &
                                     sin(ky*y)**2)                       &
                                     + (128./315.)                       &
                                    ),1,mx),3,mz)                        &
                                   *spread(spread(cos(kz1*z),1,mx),2,my))
      endif
!
    endsubroutine cosx_coscosy_cosz
!***********************************************************************
    subroutine cos2x_cos2y_cos2z(ampl,f,i,kx,ky,kz)
!
!  sinusoidal wave, adapted from sinxsinz (that routine was already doing
!  this, but under a different name)
!
!  21-feb-08/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: kx,ky,kz
      real :: ampl,kx1=1.,ky1=1.,kz1=1.
!
!  wavenumber k, helicity H=ampl (can be either sign)
!
!  sinx(kx*x)*sin(kz*z)
!
      if (present(kx)) kx1=kx
      if (present(ky)) ky1=ky
      if (present(kz)) kz1=kz
      if (ampl==0) then
        if (lroot) print*,'cos2x_cos2y_cos2z: ampl=0'
      else
        if (lroot) write(*,wave_fmt1) 'cos2x_cos2y_cos2z: ampl,kx,ky,kz=', &
                                      ampl,kx1,ky1,kz1
        if (ampl>0.) then
          f(:,:,:,i)=f(:,:,:,i)+ampl*tanh(10.* &
              spread(spread(cos(.5*kx1*x)**2,2,my),3,mz) &
             *spread(spread(cos(.5*ky1*y)**2,1,mx),3,mz) &
             *spread(spread(cos(.5*kz1*z)**2,1,mx),2,my))
        else
          f(:,:,:,i)=f(:,:,:,i)-ampl*(1.-tanh(10.* &
              spread(spread(cos(.5*kx1*x)**2,2,my),3,mz) &
             *spread(spread(cos(.5*ky1*y)**2,1,mx),3,mz) &
             *spread(spread(cos(.5*kz1*z)**2,1,mx),2,my)))
        endif
      endif
!
    endsubroutine cos2x_cos2y_cos2z
!***********************************************************************
    subroutine innerbox(ampl,ampl2,f,i,width)
!
!  set background value plus a different value inside a box
!
!   9-mar-08/axel: coded
!
      use General, only: find_index_range
!
      integer :: i,ll1,ll2,mm1,mm2,nn1,nn2
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl,ampl2,width
!
      intent(in)  :: ampl,ampl2,i,width
      intent(out) :: f
!
!  inner box
!
      if (ampl==0.and.ampl2==0) then
        if (lroot) print*,'innerbox: ampl=0'
      else
        if (lroot) write(*,wave_fmt1) 'innerbox: ampl,ampl2,width=', &
                                                 ampl,ampl2,width
        f(:,:,:,i)=ampl
        call find_index_range(x,mx,-width,width,ll1,ll2)
        call find_index_range(y,my,-width,width,mm1,mm2)
        call find_index_range(z,mz,-width,width,nn1,nn2)
        if (lroot) print*,'innerbox: ll1,ll2,mm1,mm2,nn1,nn2=', &
                                     ll1,ll2,mm1,mm2,nn1,nn2
        f(ll1:ll2,mm1:mm2,nn1:nn2,i)=ampl2
      endif
!
    endsubroutine innerbox
!***********************************************************************
    subroutine couette(ampl,mu,f,i)
!
!   couette flow,  Omega = a + b/r^2
!
!   12-jul-07/mgellert: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl, mu, omegao, omegai, rinner, router, a, b
!
      rinner=xyz0(1)
      router=xyz1(1)
      omegai=ampl
      omegao=ampl*mu
!
      if (ampl==0) then
        if (lroot) print*,'couette flow: omegai=0'
      else
        if (lroot) write(*,wave_fmt1) 'couette flow: omegai,omegao=', omegai,omegao
        a = ( (omegao/omegai) - (rinner/router)**2 ) / ( 1. - (rinner/router)**2 ) * omegai
        b = ( ( 1. - (omegao/omegai) ) / ( 1. - (rinner/router)**2 ) ) * rinner**2 * omegai
        f(:,:,:,i)=f(:,:,:,i)+spread(spread((a*x + b/x),2,my),3,mz)
      endif
!
    endsubroutine couette
!***********************************************************************
    subroutine couette_rings(ampl,mu,nr,om_nr,gap,f,i)
!
!   * (finite) couette flow  with top/bottom split in several rings
!   * can be used with the 'freeze' condition for top/bottom BCs
!   * gap is the width of the gap between two rings filled with a tanh smoothing profile
!     (in experiments you usually have something around gap=0.05*D)
!
!   18-jul-07/mgellert: coded
!   21-aug-07/mgellert: made compatible with nprocx>1
!   09-oct-07/mgellert: smoothing profile between neighboring rings added
!
      use Cdata, only: tini

      integer                           :: i, k, l, nr
      real, dimension(nr)               :: om_nr, xsteps
      real, dimension(nr+2)             :: om_all, om_diff
      real, dimension(:), allocatable   :: omx
      real, dimension(mx,my,mz,mfarray) :: f
      real                              :: ampl, mu, gap, omegao, omegai, rinner, router, step
      real                              :: x0, y0
      character(len=20)                 :: unfmt
!
      rinner=xyz0(1)
      router=xyz1(1)
      omegai=ampl
      omegao=ampl*mu
!
      allocate(omx(mx))
      omx=0.
!
      step=(router-rinner)/nr
      do k=1,nr
        xsteps(k)=rinner+k*step-gap/2. ! ring boundaries
      enddo
!
      if (gap>tini) then
        om_all(1)=omegai
        om_all(2:nr+1)=om_nr
        om_all(nr+2)=omegao
        om_diff=0.
        om_diff=om_all(1:nr+1)-om_all(2:nr+2) ! difference in omega from ring to ring
        omx(l1:l2)=omegai
        do k=1,nr+1
          if (k==1) then
            x0=rinner+gap/2.
          else
            x0=rinner+(k-1)*step-gap/2.
          endif
          y0=0.5*om_diff(k)
          omx(l1:l2) = omx(l1:l2) - ( y0*(1.+tanh((x(l1:l2)-x0)/(0.15*gap+tini))) );
        enddo
      else
        do l=l1,l2
          k=nr
          do while (k>0)
            if (x(l).le.xsteps(k)) omx(l)=om_nr(k)*omegai
            k=k-1
          enddo
        enddo
      endif
!
      if (ampl==0) then
        if (lroot) print*,'couette flow with rings: omegai=0'
      else
        write(unfmt,FMT='(A12,1I2.2,A6)') '(A19,I2,A24,',nr,'2F7.3)'
        if (lroot) write(*,FMT=unfmt) 'couette flow with ',nr,' rings: omegai,omegao = ', omegai,omegao
        write(unfmt,FMT='(A12,1I2.2,A5)') '(A19,I2,A24,',nr,'F7.3)'
        if (lroot) write(*,FMT=unfmt) 'couette flow with ',nr,' rings: omega_rings   = ',om_nr*omegai
        if (lroot) write(*,FMT=unfmt) 'couette flow with ',nr,' rings: radius_rings  = ',xsteps
        f(:,:,:,i)=f(:,:,:,i)+spread(spread((omx*x),2,my),3,mz) ! velocity up=omx*x
      endif
!
      if (allocated(omx))    deallocate(omx)
!
    endsubroutine couette_rings
!***********************************************************************
    subroutine hat(ampl,f,i,width,kx,ky,kz)
!
!  hat bump
!
!   2-may-03/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: kx,ky,kz
      real :: ampl,width,k=1.,width2,k2
!
!  prepare
!
      width2=width**2
!
!  set x-hat
!
      if (present(kx)) then
        k=kx
        k2=k**2
        if (ampl==0) then
          if (lroot) print*,'hat: ampl=0; kx=',k
        else
          if (lroot) print*,'hat: kx,i,ampl=',k,i,ampl
          f(:,:,:,i)=f(:,:,:,i)+ampl*spread(spread(.5+.5*tanh(k2*(width2-x**2)),2,my),3,mz)
        endif
      endif
!
!  set y-hat
!
      if (present(ky)) then
        k=ky
        k2=k**2
        if (ampl==0) then
          if (lroot) print*,'hat: ampl=0; ky=',k
        else
          if (lroot) print*,'hat: ky,i,ampl=',k,i,ampl
          f(:,:,:,i)=f(:,:,:,i)+ampl*spread(spread(.5+.5*tanh(k2*(width2-y**2)),1,mx),3,mz)
        endif
      endif
!
!  set z-hat
!
      if (present(kz)) then
        k=kz
        k2=k**2
        if (ampl==0) then
          if (lroot) print*,'hat: ampl=0; kz=',k
        else
          if (lroot) print*,'hat: kz,i,ampl=',k,i,ampl
          f(:,:,:,i)=f(:,:,:,i)+ampl*spread(spread(.5+.5*tanh(k2*(width2-z**2)),1,mx),2,my)
        endif
      endif
!
    endsubroutine hat
!***********************************************************************
    subroutine hat3d(ampl,f,i,width,kx,ky,kz)
!
!  Three-dimensional hat bump
!
!   9-nov-04/anders: coded
!
      integer :: i,l
      real, dimension (mx,my,mz,mfarray) :: f
      real :: kx,ky,kz,kx2,ky2,kz2
      real :: ampl,width,width2
!
!  set hat
!
      if (lroot) print*,'hat3d: kx,ky,kz=',kx,ky,kz
      if (ampl==0) then
        if (lroot) print*,'hat3d: ampl=0'
      else
        if (lroot) print*,'hat3d: ampl=',ampl
        width2=width**2
        kx2=kx**2
        ky2=ky**2
        kz2=kz**2
        do l=l1,l2; do m=m1,m2; do n=n1,n2
            f(l,m,n,i) = f(l,m,n,i) + ampl*( &
                (0.5+0.5*tanh(kx2*(width2-x(l)**2))) * &
                (0.5+0.5*tanh(ky2*(width2-y(m)**2))) * &
                (0.5+0.5*tanh(kz2*(width2-z(n)**2))) )
        enddo; enddo; enddo
      endif
!
    endsubroutine hat3d
!***********************************************************************
    subroutine gaussian(ampl,f,i,kx,ky,kz)
!
!  gaussian bump
!
!   2-may-03/axel: coded
!  20-sep-03/axel: added 1/2 factor in defn; hopefully ok with everyone?
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: kx,ky,kz
      real :: ampl,k=1.
!
!  wavenumber k
!
!  set x-wave
!
      if (present(kx)) then
        k=kx
        if (ampl==0) then
          if (lroot) print*,'gaussian: ampl=0; kx=',k
        else
          if (lroot) print*,'gaussian: kx,i=',k,i
          f(:,:,:,i)=f(:,:,:,i)+ampl*spread(spread(exp(-.5*(k*x)**2),2,my),3,mz)
        endif
      endif
!
!  set y-wave
!
      if (present(ky)) then
        k=ky
        if (ampl==0) then
          if (lroot) print*,'gaussian: ampl=0; ky=',k
        else
          if (lroot) print*,'gaussian: ky,i=',k,i
          f(:,:,:,i)=f(:,:,:,i)+ampl*spread(spread(exp(-.5*(k*y)**2),1,mx),3,mz)
        endif
      endif
!
!  set z-wave
!
      if (present(kz)) then
        k=kz
        if (ampl==0) then
          if (lroot) print*,'gaussian: ampl=0; kz=',k
        else
          if (lroot) print*,'gaussian: kz,i=',k,i
          f(:,:,:,i)=f(:,:,:,i)+ampl*spread(spread(exp(-.5*(k*z)**2),1,mx),2,my)
        endif
      endif
!
    endsubroutine gaussian
!***********************************************************************
    subroutine gaussian3d(ampl,f,i,radius)
!
!  gaussian 3-D bump
!
!  28-may-03/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl,radius,radius21
!
      radius21=1./radius**2
      do n=n1,n2; do m=m1,m2
        f(l1:l2,m,n,i)=f(l1:l2,m,n,i)+ampl*exp(-(x(l1:l2)**2+y(m)**2+z(n)**2)*radius21)
      enddo; enddo
!
    endsubroutine gaussian3d
!***********************************************************************
    subroutine parabola(ampl,f,i,kx,ky,kz)
!
!  gaussian bump
!
!   2-may-03/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: kx,ky,kz
      real :: ampl,k=1.
!
!  wavenumber k
!
!  set x-wave
!
      if (present(kx)) then
        k=kx
        if (ampl==0) then
          if (lroot) print*,'parabola: ampl=0; kx=',k
        else
          if (lroot) print*,'parabola: kx,i=',k,i
          f(:,:,:,i)=f(:,:,:,i)+ampl*spread(spread((-(k*x)**2),2,my),3,mz)
        endif
      endif
!
!  set y-wave
!
      if (present(ky)) then
        k=ky
        if (ampl==0) then
          if (lroot) print*,'parabola: ampl=0; ky=',k
        else
          if (lroot) print*,'parabola: ky,i=',k,i
          f(:,:,:,i)=f(:,:,:,i)+ampl*spread(spread((-(k*y)**2),1,mx),3,mz)
        endif
      endif
!
!  set z-wave
!
      if (present(kz)) then
        k=kz
        if (ampl==0) then
          if (lroot) print*,'parabola: ampl=0; kz=',k
        else
          if (lroot) print*,'parabola: kz,i=',k,i
          f(:,:,:,i)=f(:,:,:,i)+ampl*spread(spread((-(k*z)**2),1,mx),2,my)
        endif
      endif
!
    endsubroutine parabola
!***********************************************************************
    subroutine wave(ampl,f,i,kx,ky,kz)
!
!  sinusoidal wave
!
!   6-jul-02/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: kx,ky,kz
      real :: ampl,k=1.
!
!  wavenumber k
!
!  set x-wave
!
      if (present(kx)) then
        k=kx
        if (ampl==0) then
          if (lroot) print*,'wave: ampl=0; kx=',k
        else
          if (lroot) print*,'wave: kx,i=',k,i
          f(:,:,:,i)=f(:,:,:,i)+ampl*spread(spread(sin(k*x),2,my),3,mz)
        endif
      endif
!
!  set y-wave
!
      if (present(ky)) then
        k=ky
        if (ampl==0) then
          if (lroot) print*,'wave: ampl=0; ky=',k
        else
          if (lroot) print*,'wave: ky,i=',k,i
          f(:,:,:,i)=f(:,:,:,i)+ampl*spread(spread(sin(k*y),1,mx),3,mz)
        endif
      endif
!
!  set z-wave
!
      if (present(kz)) then
        k=kz
        if (ampl==0) then
          if (lroot) print*,'wave: ampl=0; kz=',k
        else
          if (lroot) print*,'wave: kz,i=',k,i
          f(:,:,:,i)=f(:,:,:,i)+ampl*spread(spread(sin(k*z),1,mx),2,my)
        endif
      endif
!
    endsubroutine wave
!***********************************************************************
    subroutine wave_uu(ampl,f,i,kx,ky,kz)
!
!  sinusoidal wave
!
!  14-apr-03/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: kx,ky,kz
      real :: ampl,k=1.
!
!  wavenumber k
!
!  set x-wave
!
      if (present(kx)) then
        k=kx
        if (ampl==0) then
          if (lroot) print*,'wave_uu: ampl=0; kx=',k
        else
          if (lroot) print*,'wave_uu: kx,i=',k,i
          f(:,:,:,i)=log(1.+ampl*spread(spread(sin(k*x),2,my),3,mz)*f(:,:,:,iux))
        endif
      endif
!
!  set y-wave
!
      if (present(ky)) then
        k=ky
        if (ampl==0) then
          if (lroot) print*,'wave_uu: ampl=0; ky=',k
        else
          if (lroot) print*,'wave_uu: ky,i=',k,i
          f(:,:,:,i)=log(1.+ampl*spread(spread(sin(k*y),1,mx),3,mz)*f(:,:,:,iuy))
        endif
      endif
!
!  set z-wave
!
      if (present(kz)) then
        k=kz
        if (ampl==0) then
          if (lroot) print*,'wave_uu: ampl=0; kz=',k
        else
          if (lroot) print*,'wave_uu: kz,i=',k,i,iuz
          f(:,:,:,i)=log(1.+ampl*spread(spread(sin(k*z),1,mx),2,my)*f(:,:,:,iuz))
        endif
      endif
!
    endsubroutine wave_uu
!***********************************************************************
    subroutine modes(ampl,coef,f,i,kx,ky,kz)
!
!  mode
!
!  30-oct-03/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      complex :: coef
      complex :: ii=(0.,1.)
      real :: ampl,kx,ky,kz
!
      do n=n1,n2; do m=m1,m2
        f(l1:l2,m,n,i)=ampl*real(coef*exp(ii*(kx*x(l1:l2)+ky*y(m)+kz*z(n))))
      enddo; enddo
!
    endsubroutine modes
!***********************************************************************
    subroutine modev(ampl,coef,f,i,kx,ky,kz)
!
!  mode
!
!  30-oct-03/axel: coded
!
      integer :: i,ivv
      real, dimension (mx,my,mz,mfarray) :: f
      complex, dimension (3) :: coef
      complex :: ii=(0.,1.)
      real :: ampl,kx,ky,kz
!
      do ivv=0,2
        f(l1:l2,m,n,ivv+i)=ampl*real(coef(ivv+1)*exp(ii*(kx*x(l1:l2)+ky*y(m)+kz*z(n))))
      enddo
!
    endsubroutine modev
!***********************************************************************
    subroutine modeb(ampl,coefb,f,i,kx,ky,kz)
!
!  mode
!
!  30-oct-03/axel: coded
!
      integer :: i,ivv
      real, dimension (mx,my,mz,mfarray) :: f
      complex, dimension (3) :: coef,coefb
      complex :: ii=(0.,1.)
      real :: ampl,kx,ky,kz,k2
!
      print*,'print Ak coefficients from Bk coefficients'
      k2=kx**2+ky**2+kz**2
      coef(1)=(ky*coefb(3)-kz*coefb(2))/k2
      coef(2)=(kz*coefb(1)-kx*coefb(3))/k2
      coef(3)=(kx*coefb(2)-ky*coefb(1))/k2
      print*,'coef=',coef
!
      do ivv=0,2
        f(l1:l2,m,n,ivv+i)=ampl*real(coef(ivv+1)*exp(ii*(kx*x(l1:l2)+ky*y(m)+kz*z(n))))
      enddo
!
    endsubroutine modeb
!***********************************************************************
    subroutine jump(f,i,fleft,fright,width,dir)
!
!  jump
!
!  19-sep-02/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mx) :: profx
      real, dimension (my) :: profy
      real, dimension (mz) :: profz
      real :: fleft,fright,width
      character(len=*) :: dir
!
!  jump; check direction
!
      select case(dir)
!
      case('x')
        profx=fleft+(fright-fleft)*.5*(1.+tanh(x/width))
        f(:,:,:,i)=f(:,:,:,i)+spread(spread(profx,2,my),3,mz)
!
      case('y')
        profy=fleft+(fright-fleft)*.5*(1.+tanh(y/width))
        f(:,:,:,i)=f(:,:,:,i)+spread(spread(profy,1,mx),3,mz)
!
      case('z')
        profz=fleft+(fright-fleft)*.5*(1.+tanh(z/width))
        f(:,:,:,i)=f(:,:,:,i)+spread(spread(profz,1,mx),2,my)
!
      case default
        print*,'jump: no default value'
!
      endselect
!
    endsubroutine jump
!***********************************************************************
    subroutine bjump(f,i,fyleft,fyright,fzleft,fzright,width,dir)
!
!  jump in B-field (in terms of magnetic vector potential)
!
!   9-oct-02/wolf+axel: coded
!  21-apr-05/axel: added possibility of Bz component
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mx) :: profy,profz,alog_cosh_xwidth
      real :: fyleft,fyright,fzleft,fzright,width
      character(len=*) :: dir
!
!  jump; check direction
!
      select case(dir)
!
!  use correct signs when calling this routine
!  Ay=+int Bz dx
!  Az=-int By dx
!
!  alog(cosh(x/width)) =
!
      case('x')
        alog_cosh_xwidth=abs(x/width)+alog(.5*(1.+exp(-2*abs(x/width))))
        profz=.5*(fyright+fyleft)*x &
             +.5*(fyright-fyleft)*width*alog_cosh_xwidth
        profy=.5*(fzright+fzleft)*x &
             +.5*(fzright-fzleft)*width*alog_cosh_xwidth
        f(:,:,:,i+1)=f(:,:,:,i+1)+spread(spread(profy,2,my),3,mz)
        f(:,:,:,i+2)=f(:,:,:,i+2)-spread(spread(profz,2,my),3,mz)

      case default
        print*,'bjump: no default value'
!
      endselect
!
    endsubroutine bjump
!***********************************************************************
    subroutine bjumpz(f,i,fxleft,fxright,fyleft,fyright,width,dir)
!
!  jump in B-field (in terms of magnetic vector potential)
!
!   9-oct-02/wolf+axel: coded
!  21-apr-05/axel: added possibility of Bz component
!
      integer :: i,il,im
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mz) :: profx,profy,alog_cosh_zwidth
      real :: fyleft,fyright,fxleft,fxright,width
      character(len=*) :: dir

      select case(dir)
      case('z')
        alog_cosh_zwidth=abs(z/width)+alog(.5*(1.+exp(-2*abs(z/width))))
        profx=.5*(fyright+fyleft)*z &
             +.5*(fyright-fyleft)*width*alog_cosh_zwidth
        profy=.5*(fxright+fxleft)*z &
             +.5*(fxright-fxleft)*width*alog_cosh_zwidth
        do il=1,mx
        do im=1,my
          f(il,im,:,i ) =f(il,im,:,i  )+profx
          f(il,im,:,i+1)=f(il,im,:,i+1)-profy
        enddo
        enddo
      case default
        print*,'bjump: no default value'
!
      endselect
!
    endsubroutine bjumpz
!***********************************************************************
    subroutine beltrami(ampl,f,i,kx,ky,kz,phase)
!
!  Beltrami field (as initial condition)
!
!  19-jun-02/axel: coded
!   5-jul-02/axel: made additive (if called twice), kx,ky,kz are optional
!
      integer :: i,j
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: kx,ky,kz,phase
      real :: ampl,k=1.,fac,ph
!
!  possibility of shifting the Beltrami wave by phase ph
!
      if (present(phase)) then
        if (lroot) print*,'Beltrami: phase=',phase
        ph=phase
      else
        ph=0.
      endif
!
!  wavenumber k, helicity H=ampl (can be either sign)
!
!  set x-dependent Beltrami field
!
      if (present(kx)) then
        k=abs(kx)
        if (k==0) print*,'beltrami: k must not be zero!'
        fac=sign(sqrt(abs(ampl/k)),kx)
        if (iproc==0) print*,'beltrami: fac=',fac
        if (ampl==0) then
          if (lroot) print*,'beltrami: ampl=0; kx=',k
        elseif (ampl>0) then
          if (lroot) print*,'beltrami: Beltrami field (pos-hel): kx,i=',k,i
          j=i+1; f(:,:,:,j)=f(:,:,:,j)+fac*spread(spread(sin(k*x+ph),2,my),3,mz)
          j=i+2; f(:,:,:,j)=f(:,:,:,j)+fac*spread(spread(cos(k*x+ph),2,my),3,mz)
        elseif (ampl<0) then
          if (lroot) print*,'beltrami: Beltrami field (neg-hel): kx,i=',k,i
          j=i+1; f(:,:,:,j)=f(:,:,:,j)+fac*spread(spread(cos(k*x+ph),2,my),3,mz)
          j=i+2; f(:,:,:,j)=f(:,:,:,j)+fac*spread(spread(sin(k*x+ph),2,my),3,mz)
        endif
      endif
!
!  set y-dependent Beltrami field
!
      if (present(ky)) then
        k=abs(ky)
        if (k==0) print*,'beltrami: k must not be zero!'
        fac=sign(sqrt(abs(ampl/k)),ky)
        if (ampl==0) then
          if (lroot) print*,'beltrami: ampl=0; ky=',k
        elseif (ampl>0) then
          if (lroot) print*,'beltrami: Beltrami field (pos-hel): ky,i=',k,i
          j=i;   f(:,:,:,j)=f(:,:,:,j)+fac*spread(spread(cos(k*y+ph),1,mx),3,mz)
          j=i+2; f(:,:,:,j)=f(:,:,:,j)+fac*spread(spread(sin(k*y+ph),1,mx),3,mz)
        elseif (ampl<0) then
          if (lroot) print*,'beltrami: Beltrami field (neg-hel): ky,i=',k,i
          j=i;   f(:,:,:,j)=f(:,:,:,j)+fac*spread(spread(sin(k*y+ph),1,mx),3,mz)
          j=i+2; f(:,:,:,j)=f(:,:,:,j)+fac*spread(spread(cos(k*y+ph),1,mx),3,mz)
        endif
      endif
!
!  set z-dependent Beltrami field
!
      if (present(kz)) then
        k=abs(kz)
        if (k==0) print*,'beltrami: k must not be zero!'
        fac=sign(sqrt(abs(ampl/k)),kz)
        if (ampl==0) then
          if (lroot) print*,'beltrami: ampl=0; kz=',k
        elseif (ampl>0) then
          if (lroot) print*,'beltrami: Beltrami field (pos-hel): kz,i=',k,i
          j=i;   f(:,:,:,j)=f(:,:,:,j)+fac*spread(spread(sin(k*z+ph),1,mx),2,my)
          j=i+1; f(:,:,:,j)=f(:,:,:,j)+fac*spread(spread(cos(k*z+ph),1,mx),2,my)
        elseif (ampl<0) then
          if (lroot) print*,'beltrami: Beltrami field (neg-hel): kz,i=',k,i
          j=i;   f(:,:,:,j)=f(:,:,:,j)+fac*spread(spread(cos(k*z+ph),1,mx),2,my)
          j=i+1; f(:,:,:,j)=f(:,:,:,j)+fac*spread(spread(sin(k*z+ph),1,mx),2,my)
        endif
      endif
!
    endsubroutine beltrami
!***********************************************************************
    subroutine rolls(ampl,f,i,kx,kz)
!
!  convection rolls (as initial condition)
!
!  21-aug-07/axel: coded
!
      integer :: i,j
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl,kx,kz,zbot
!
!  check input parameters
!
      zbot=xyz0(3)
      if (lroot) print*,'rolls: i,kx,kz,zbot=',i,kx,kz,zbot
!
!  set stream function psi=sin(kx*x)*sin(kz*(z-zbot))
!
      j=i
      f(:,:,:,j)=f(:,:,:,j)-ampl*kz*spread(spread(sin(kx*x       ),2,my),3,mz)&
                                   *spread(spread(cos(kz*(z-zbot)),1,mx),2,my)
      j=i+2
      f(:,:,:,j)=f(:,:,:,j)+ampl*kx*spread(spread(cos(kx*x       ),2,my),3,mz)&
                                   *spread(spread(sin(kz*(z-zbot)),1,mx),2,my)
!
    endsubroutine rolls
!***********************************************************************
    subroutine robertsflow(ampl,f,i)
!
!  Roberts Flow (as initial condition)
!
!   9-jun-05/axel: coded
!
      integer :: i,j
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl,k=1.,kf,fac1,fac2
!
!  prepare coefficients
!
      kf=k*sqrt(2.)
      fac1=sqrt(2.)*ampl*k/kf
      fac2=sqrt(2.)*ampl
!
      j=i+0; f(:,:,:,j)=f(:,:,:,j)-fac1*spread(spread(cos(k*x),2,my),3,mz)&
                                       *spread(spread(sin(k*y),1,mx),3,mz)
!
      j=i+1; f(:,:,:,j)=f(:,:,:,j)+fac1*spread(spread(sin(k*x),2,my),3,mz)&
                                       *spread(spread(cos(k*y),1,mx),3,mz)
!
      j=i+2; f(:,:,:,j)=f(:,:,:,j)+fac2*spread(spread(cos(k*x),2,my),3,mz)&
                                       *spread(spread(cos(k*y),1,mx),3,mz)
!
    endsubroutine robertsflow
!***********************************************************************
    subroutine vecpatternxy(ampl,f,i,kx,ky,kz)
!
!  horizontal pattern with exponential decay (as initial condition)
!
!   9-jun-05/axel: coded
!
      integer :: i,j
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl,kx,ky,kz
!
!  prepare coefficients
!
      j=i+0; f(:,:,:,j)=f(:,:,:,j)-ampl*spread(spread(sin(ky*y),1,mx),3,mz) &
        *spread(spread(exp(-abs(kz*z)),1,mx),2,my)
      j=i+1; f(:,:,:,j)=f(:,:,:,j)+ampl*spread(spread(sin(kx*x),2,my),3,mz) &
        *spread(spread(exp(-abs(kz*z)),1,mx),2,my)
!
    endsubroutine vecpatternxy
!***********************************************************************
    subroutine bipolar(ampl,f,i,kx,ky,kz)
!
!  horizontal pattern with exponential decay (as initial condition)
!
!  24-may-09/axel: coded
!
      integer :: i,j
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl,kx,ky,kz
!
!  sets up a nearly force-free bipolar region
!
      j=i+1; f(:,:,:,j)=f(:,:,:,j)+ampl &
        *spread(spread(exp(-(kx*x)**2),2,my),3,mz) &
        *spread(spread(exp(-(ky*y)**2),1,mx),3,mz) &
        *spread(spread(exp(-abs(kz*z)),1,mx),2,my)
      j=i+2; f(:,:,:,j)=f(:,:,:,j)+ampl &
        *spread(spread(exp(-(kx*x)**2)*(-2*x),2,my),3,mz) &
        *spread(spread(exp(-(ky*y)**2),1,mx),3,mz) &
        *spread(spread(exp(-abs(kz*z)),1,mx),2,my)
!
    endsubroutine bipolar
!***********************************************************************
    subroutine soundwave(ampl,f,i,kx,ky,kz)
!
!  sound wave (as initial condition)
!
!   2-aug-02/axel: adapted from Beltrami
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: kx,ky,kz
      real :: ampl,k=1.,fac
!
!  wavenumber k
!
!  set x-dependent sin wave
!
      if (present(kx)) then
        k=kx; if (k==0) print*,'soundwave: k must not be zero!'; fac=sqrt(abs(ampl/k))
        if (ampl==0) then
          if (lroot) print*,'soundwave: ampl=0; kx=',k
        else
          if (lroot) print*,'soundwave: kx,i=',k,i
          f(:,:,:,i)=f(:,:,:,i)+fac*spread(spread(sin(k*x),2,my),3,mz)
        endif
      endif
!
!  set y-dependent sin wave field
!
      if (present(ky)) then
        k=ky; if (k==0) print*,'soundwave: k must not be zero!'; fac=sqrt(abs(ampl/k))
        if (ampl==0) then
          if (lroot) print*,'soundwave: ampl=0; ky=',k
        else
          if (lroot) print*,'soundwave: ky,i=',k,i
          f(:,:,:,i)=f(:,:,:,i)+fac*spread(spread(sin(k*y),1,mx),3,mz)
        endif
      endif
!
!  set z-dependent sin wave field
!
      if (present(kz)) then
        k=kz; if (k==0) print*,'soundwave: k must not be zero!'; fac=sqrt(abs(ampl/k))
        if (ampl==0) then
          if (lroot) print*,'soundwave: ampl=0; kz=',k
        else
          if (lroot) print*,'soundwave: kz,i=',k,i
          f(:,:,:,i)=f(:,:,:,i)+fac*spread(spread(sin(k*z),1,mx),2,my)
        endif
      endif
!
    endsubroutine soundwave
!***********************************************************************
    subroutine coswave(ampl,f,i,kx,ky,kz)
!
!  cosine wave (as initial condition)
!
!  14-nov-03/axel: adapted from sinwave
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: kx,ky,kz
      real :: ampl,k=1.,fac
!
!  wavenumber k
!
!  set x-dependent cos wave
!
      if (present(kx)) then
        k=kx; if (k==0) print*,'coswave: k must not be zero!'; fac=ampl
        if (ampl==0) then
          if (lroot) print*,'coswave: ampl=0; kx=',k
        else
          if (lroot) print*,'coswave: kx,i=',k,i
          f(:,:,:,i)=f(:,:,:,i)+fac*spread(spread(cos(k*x),2,my),3,mz)
        endif
      endif
!
!  set y-dependent cos wave field
!
      if (present(ky)) then
        k=ky; if (k==0) print*,'coswave: k must not be zero!'; fac=ampl
        if (ampl==0) then
          if (lroot) print*,'coswave: ampl=0; ky=',k
        else
          if (lroot) print*,'coswave: ky,i=',k,i
          f(:,:,:,i)=f(:,:,:,i)+fac*spread(spread(cos(k*y),1,mx),3,mz)
        endif
      endif
!
!  set z-dependent cos wave field
!
      if (present(kz)) then
        k=kz; if (k==0) print*,'coswave: k must not be zero!'; fac=ampl
        if (ampl==0) then
          if (lroot) print*,'coswave: ampl=0; kz=',k
        else
          if (lroot) print*,'coswave: kz,i=',k,i
          f(:,:,:,i)=f(:,:,:,i)+fac*spread(spread(cos(k*z),1,mx),2,my)
        endif
      endif
!
    endsubroutine coswave
!***********************************************************************
    subroutine hatwave(ampl,f,i,width,kx,ky,kz)
!
!  cosine wave (as initial condition)
!
!   9-jan-08/axel: adapted from coswave
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: kx,ky,kz
      real :: ampl,k=1.,fac,width
!
!  wavenumber k
!
!  set x-dependent hat wave
!
      if (present(kx)) then
        k=kx; if (k==0) print*,'hatwave: k must not be zero!'; fac=.5*ampl
        if (ampl==0) then
          if (lroot) print*,'hatwave: ampl=0; kx=',k
        else
          if (lroot) print*,'hatwave: kx,i=',k,i
          f(:,:,:,i)=f(:,:,:,i)+fac*spread(spread(1+tanh(cos(k*x)/width),2,my),3,mz)
        endif
      endif
!
!  set y-dependent hat wave field
!
      if (present(ky)) then
        k=ky; if (k==0) print*,'hatwave: k must not be zero!'; fac=.5*ampl
        if (ampl==0) then
          if (lroot) print*,'hatwave: ampl=0; ky=',k
        else
          if (lroot) print*,'hatwave: ky,i=',k,i
          f(:,:,:,i)=f(:,:,:,i)+fac*spread(spread(1+tanh(5*cos(k*y)),1,mx),3,mz)
        endif
      endif
!
!  set z-dependent hat wave field
!
      if (present(kz)) then
        k=kz; if (k==0) print*,'hatwave: k must not be zero!'; fac=.5*ampl
        if (ampl==0) then
          if (lroot) print*,'hatwave: ampl=0; kz=',k
        else
          if (lroot) print*,'hatwave: kz,i=',k,i
          f(:,:,:,i)=f(:,:,:,i)+fac*spread(spread(1+tanh(5*cos(k*z)),1,mx),2,my)
        endif
      endif
!
    endsubroutine hatwave
!***********************************************************************
    subroutine sinwave(ampl,f,i,kx,ky,kz)
!
!  sine wave (as initial condition)
!
!  14-nov-03/axel: adapted from sound wave
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: kx,ky,kz
      real :: ampl,k=1.,fac
!
!  wavenumber k
!
!  set x-dependent sin wave
!
      if (present(kx)) then
        k=kx; if (k==0) print*,'sinwave: k must not be zero!'; fac=ampl
        if (ampl==0) then
          if (lroot) print*,'sinwave: ampl=0; kx=',k
        else
          if (lroot) print*,'sinwave: kx,i=',k,i
          f(:,:,:,i)=f(:,:,:,i)+fac*spread(spread(sin(k*x),2,my),3,mz)
        endif
      endif
!
!  set y-dependent sin wave field
!
      if (present(ky)) then
        k=ky; if (k==0) print*,'sinwave: k must not be zero!'; fac=ampl
        if (ampl==0) then
          if (lroot) print*,'sinwave: ampl=0; ky=',k
        else
          if (lroot) print*,'sinwave: ky,i=',k,i
          f(:,:,:,i)=f(:,:,:,i)+fac*spread(spread(sin(k*y),1,mx),3,mz)
        endif
      endif
!
!  set z-dependent sin wave field
!
      if (present(kz)) then
        k=kz; if (k==0) print*,'sinwave: k must not be zero!'; fac=ampl
        if (ampl==0) then
          if (lroot) print*,'sinwave: ampl=0; kz=',k
        else
          if (lroot) print*,'sinwave: kz,i=',k,i
          f(:,:,:,i)=f(:,:,:,i)+fac*spread(spread(sin(k*z),1,mx),2,my)
        endif
      endif
!
    endsubroutine sinwave
!***********************************************************************
    subroutine sinwave_phase(f,i,ampl,kx,ky,kz,phase)
!
!  Sine wave (as initial condition)
!
!  23-jan-06/anders: adapted from sinwave.
!
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl, kx, ky, kz, phase
      integer :: i
!
!  Set sin wave
!
      if (lroot) print*, 'sinwave_phase: i, ampl, kx, ky, kz, phase=', &
          i, ampl, kx, ky, kz, phase
!
      do m=m1,m2; do n=n1,n2
        f(l1:l2,m,n,i) = f(l1:l2,m,n,i) + &
            ampl*sin(kx*x(l1:l2)+ky*y(m)+kz*z(n)+phase)
      enddo; enddo
!
    endsubroutine sinwave_phase
!***********************************************************************
    subroutine coswave_phase(f,i,ampl,kx,ky,kz,phase)
!
!  Cosine wave (as initial condition)
!
!  13-jun-06/anders: adapted from sinwave-phase.
!
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl, kx, ky, kz, phase
      integer :: i
!
!  Set cos wave
!
      if (lroot) print*, 'coswave_phase: i, ampl, kx, ky, kz, phase=', &
          i, ampl, kx, ky, kz, phase
!
      do m=m1,m2; do n=n1,n2
        f(l1:l2,m,n,i) = f(l1:l2,m,n,i) + &
            ampl*cos(kx*x(l1:l2)+ky*y(m)+kz*z(n)+phase)
      enddo; enddo
!
    endsubroutine coswave_phase
!***********************************************************************
    subroutine hawley_etal99a(ampl,f,i,width,Lxyz)
!
!  velocity perturbations as used by Hawley et al (1999, ApJ,518,394)
!
!  13-jun-05/maurice reyes: sent to axel via email
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mx) :: funx
      real, dimension (my) :: funy
      real, dimension (mz) :: funz
      real, dimension(3) :: Lxyz
      real :: k1,k2,k3,k4,phi1,phi2,phi3,phi4,ampl,width
      integer :: i,iux,iuy,iuz,l,m,n
!
!  set iux, iuy, iuz, based on the value of i
!
      iux=i
      iuy=i+1
      iuz=i+2
!
!  velocity perturbations as used by Hawley et al (1999, ApJ,518,394)
!
      if (lroot) print*,'init_uu: hawley-et-al'
      k1=2.0*pi/(Lxyz(1))
      k2=4.0*pi/(Lxyz(1))
      k3=6.0*pi/(Lxyz(1))
      k4=8.0*pi/(Lxyz(1))
      phi1=k1*0.226818
      phi2=k2*0.597073
      phi3=k3*0.962855
      phi4=k4*0.762091
!
!  use l,m,n as loop variables; inner loop should be on first index
!
      funx=sin(k1*x+phi1)+sin(k2*x+phi2)+sin(k3*x+phi3)+sin(k4*x+phi4)
      funy=sin(k1*y+phi1)+sin(k2*y+phi2)+sin(k3*y+phi3)+sin(k4*y+phi4)
      funz=sin(k1*z+phi1)+sin(k2*z+phi2)+sin(k3*z+phi3)+sin(k4*z+phi4)
      do n=1,mz; do m=1,my; do l=1,mx
        f(l,m,n,iuy)=ampl*funx(l)*funy(m)*funz(n)
      enddo; enddo; enddo
!
    endsubroutine hawley_etal99a
!***********************************************************************
    subroutine stratification(f,strati_type)
!
!  read mean stratification from "stratification.dat"
!
!   8-apr-03/axel: coded
!  23-may-04/anders: made structure for other input variables
!
      use Mpicomm, only: stop_it
      use EquationOfState, only: eoscalc,ilnrho_lnTT
!
      real, dimension (mx,my,mz,mfarray) :: f
      integer, parameter :: ntotal=nz*nprocz,mtotal=nz*nprocz+2*nghost
      real, dimension (mtotal) :: lnrho0,ss0,lnTT0
      real :: tmp,var1,var2
      logical :: exist
      integer :: stat
      character (len=labellen) :: strati_type
!
!  read mean stratification and write into array
!  if file is not found in run directory, search under trim(directory)
!
      inquire(file='stratification.dat',exist=exist)
      if (exist) then
        open(19,file='stratification.dat')
      else
        inquire(file=trim(directory)//'/stratification.ascii',exist=exist)
        if (exist) then
          open(19,file=trim(directory)//'/stratification.ascii')
        else
          call stop_it('stratification: *** error *** - no input file')
        endif
      endif
!
!  read data
!  first the entire stratification file
!
      select case(strati_type)
      case('lnrho_ss')
        do n=1,mtotal
          read(19,*,iostat=stat) tmp,var1,var2
          if (stat>=0) then
            if (ip<5) print*,"stratification: ",tmp,var1,var2
            if (ldensity) lnrho0(n)=var1
            if (lentropy) ss0(n)=var2
          else
            exit
          endif
        enddo
!
      case('lnrho_lnTT')
        do n=1,mtotal
          read(19,*,iostat=stat) tmp,var1,var2
          if (stat>=0) then
            if (ip<5) print*,"stratification: ",tmp,var1,var2
            if (ldensity) lnrho0(n)=var1
            if (ltemperature) lnTT0(n)=var2
            if (lentropy) then
              call eoscalc(ilnrho_lnTT,var1,var2,ss=tmp)
              ss0(n)=tmp
            endif
          else
            exit
          endif
        enddo
      endselect
!
!  select the right region for the processor afterwards
!
      select case (n)
  !
  !  without ghost zones
  !
      case (ntotal+1)
        if (lentropy) then
          do n=n1,n2
            f(:,:,n,ilnrho)=lnrho0(ipz*nz+n-nghost)
            f(:,:,n,iss)=ss0(ipz*nz+n-nghost)
          enddo
        endif
        if (ltemperature) then
          do n=n1,n2
            f(:,:,n,ilnrho)=lnrho0(ipz*nz+n-nghost)
            f(:,:,n,ilnTT)=lnTT0(ipz*nz+n-nghost)
          enddo
        endif
  !
  !  with ghost zones
  !
      case (mtotal+1)
        if (lentropy) then
          do n=1,mz
            f(:,:,n,ilnrho)=lnrho0(ipz*nz+n)
            f(:,:,n,iss)=ss0(ipz*nz+n)
          enddo
        endif
        if (ltemperature) then
          do n=1,mz
            f(:,:,n,ilnrho)=lnrho0(ipz*nz+n)
            f(:,:,n,ilnTT)=lnTT0(ipz*nz+n)
          enddo
        endif

      case default
        if (lroot) then
          print '(A,I4,A,I4,A,I4,A)','ERROR: The stratification file '// &
                'for this run is allowed to contain either',ntotal, &
                ' lines (without ghost zones) or more than',mtotal, &
                ' lines (with ghost zones). It does contain',n-1, &
                ' lines though.'
        endif
        call stop_it('')

      endselect
!
      close(19)
!
    endsubroutine stratification
!***********************************************************************
    subroutine stratification_x(f,strati_type)
!
!  read mean stratification from "stratification.dat"
!
!   02-mar-09/petri: adapted from stratification
!
      use Mpicomm, only: stop_it
      use EquationOfState, only: eoscalc,ilnrho_lnTT
!
      real, dimension (mx,my,mz,mfarray) :: f
      integer, parameter :: ntotal=nx*nprocx,mtotal=nx*nprocx+2*nghost
      real, dimension (mtotal) :: lnrho0,ss0,lnTT0
      real :: tmp,var1,var2
      logical :: exist
      integer :: stat
      character (len=labellen) :: strati_type
!
!  read mean stratification and write into array
!  if file is not found in run directory, search under trim(directory)
!
      inquire(file='stratification.dat',exist=exist)
      if (exist) then
        open(19,file='stratification.dat')
      else
        inquire(file=trim(directory)//'/stratification.ascii',exist=exist)
        if (exist) then
          open(19,file=trim(directory)//'/stratification.ascii')
        else
          call stop_it('stratification: *** error *** - no input file')
        endif
      endif
!
!  read data
!  first the entire stratification file
!
      select case(strati_type)
      case('lnrho_ss')
        do n=1,mtotal
          read(19,*,iostat=stat) tmp,var1,var2
          if (stat>=0) then
            if (ip<5) print*,"stratification: ",tmp,var1,var2
            if (ldensity) lnrho0(n)=var1
            if (lentropy) ss0(n)=var2
          else
            exit
          endif
        enddo
!
      case('lnrho_lnTT')
        do n=1,mtotal
          read(19,*,iostat=stat) tmp,var1,var2
          if (stat>=0) then
            if (ip<5) print*,"stratification: ",tmp,var1,var2
            if (ldensity) lnrho0(n)=var1
            if (ltemperature) lnTT0(n)=var2
            if (lentropy) then
              call eoscalc(ilnrho_lnTT,var1,var2,ss=tmp)
              ss0(n)=tmp
            endif
          else
            exit
          endif
        enddo
      endselect
!
!  select the right region for the processor afterwards
!
      select case (n)
  !
  !  without ghost zones
  !
      case (ntotal+1)
        if (lentropy) then
          do n=l1,l2
            f(n,:,:,ilnrho)=lnrho0(ipx*nx+n-nghost)
            f(n,:,:,iss)=ss0(ipx*nx+n-nghost)
          enddo
        endif
        if (ltemperature) then
          do n=l1,l2
            f(n,:,:,ilnrho)=lnrho0(ipx*nx+n-nghost)
            f(n,:,:,ilnTT)=lnTT0(ipx*nx+n-nghost)
          enddo
        endif
  !
  !  with ghost zones
  !
      case (mtotal+1)
        if (lentropy) then
          do n=1,mx
            f(n,:,:,ilnrho)=lnrho0(ipx*nx+n)
            f(n,:,:,iss)=ss0(ipx*nx+n)
          enddo
        endif
        if (ltemperature) then
          do n=1,mx
            f(n,:,:,ilnrho)=lnrho0(ipx*nx+n)
            f(n,:,:,ilnTT)=lnTT0(ipx*nx+n)
          enddo
        endif

      case default
        if (lroot) then
          print '(A,I4,A,I4,A,I4,A)','ERROR: The stratification file '// &
                'for this run is allowed to contain either',ntotal, &
                ' lines (without ghost zones) or more than',mtotal, &
                ' lines (with ghost zones). It does contain',n-1, &
                ' lines though.'
        endif
        call stop_it('')

      endselect
!
      close(19)
!
    endsubroutine stratification_x
!***********************************************************************
    subroutine planet_hc(ampl,f,eps,radius,gamma,cs20,rho0,width)
!
!  Ellipsoidal planet solution (Goldreich, Narayan, Goodman 1987)
!
!   6-jul-02/axel: coded
!  22-feb-03/axel: fixed 3-D background solution for enthalpy
!  26-Jul-03/anders: Revived from June 1 version
!
      use Mpicomm, only: mpireduce_sum, mpibcast_real
!
      real, dimension (mx,my,mz,mvar) :: f
      real, dimension (nx) :: hh, xi
      real, dimension (mz) :: hz
      real :: delS,ampl,sigma2,sigma,delta2,delta,eps,radius,a_ell,b_ell,c_ell
      real :: gamma,cs20,gamma1,eps2,radius2,width
      real :: lnrhosum_thisbox,rho0
      real, dimension(1) :: lnrhosum_thisbox_tmp,lnrhosum_wholebox
      integer :: l
!
!  calculate sigma
!
      if (lroot) print*,'planet_hc: qshear,eps=',qshear,eps
      eps2=eps**2
      radius2=radius**2
      sigma2=2*qshear/(1.-eps2)
      if (sigma2<0.) then
        if (lroot) print*, &
          'planet_hc: sigma2<0 not allowed; choose another value of eps_planet'
      else
        sigma=sqrt(sigma2)
      endif
!
!  calculate delta
!
      delta2=(2.-sigma)*sigma
      if (lroot) print*,'planet_hc: sigma,delta2,radius=',sigma,delta2,radius
      if (delta2<=0.) then
        if (lroot) print*,'planet_hc: delta2<=0 not allowed'
      else
        delta=sqrt(delta2)
      endif
!
!  calculate gamma1
!
      gamma1=gamma-1.
      if (lroot) print*,'planet_hc: gamma=',gamma
!
!  ellipse parameters
!
      b_ell = radius
      a_ell = radius/eps
      c_ell = radius*delta
      if (lroot) print*,'planet_hc: Ellipse axes (b_ell,a_ell,c_ell)=', &
          b_ell,a_ell,c_ell
      if (lroot) print*,"planet_hc: integrate hot corona"
!
!  xi=1 inside vortex, and 0 outside
!
      do n=n1,n2; do m=m1,m2
        hh=0.5*delta2*Omega**2*(radius2-x(l1:l2)**2-eps2*y(m)**2)-.5*Omega**2*z(n)**2
        xi=0.5+0.5*tanh(hh/width)
!
!  Calculate velocities (Kepler speed subtracted)
!
        f(l1:l2,m,n,iux)=   eps2*sigma *Omega*y(m)    *xi
        f(l1:l2,m,n,iuy)=(qshear-sigma)*Omega*x(l1:l2)*xi
        if (lentropy) f(l1:l2,m,n,iss)=-log(ampl)*xi
      enddo; enddo
!
      do m=m1,m2; do l=l1,l2
!
!  add continuous vertical stratification to horizontal planet solution
!  NOTE: if width is too small, the vertical integration below may fail.
!
        hz(n2)=1.0  !(initial condition)
        do n=n2-1,n1,-1
          delS=f(l,m,n+1,iss)-f(l,m,n,iss)
          hz(n)=(hz(n+1)*(1.0-0.5*delS)+ &
               Omega**2*0.5*(z(n)+z(n+1))*dz)/(1.0+0.5*delS)
        enddo
!
!  calculate density, depending on what gamma is
!
        if (lentropy) then
          f(l,m,n1:n2,ilnrho)= &
               (log(gamma1*hz(n1:n2)/cs20)-gamma*f(l,m,n1:n2,iss))/gamma1
          if (lroot) &
            print*,'planet_hc: planet solution with entropy for gamma=',gamma
        else
          if (gamma==1.) then
            f(l,m,n1:n2,ilnrho)=hz(n1:n2)/cs20
            if (lroot) print*,'planet_hc: planet solution for gamma=1'
          else
            f(l,m,n1:n2,ilnrho)=log(gamma1*hz(n1:n2)/cs20)/gamma1
            if (lroot) print*,'planet_hc: planet solution for gamma=',gamma
          endif
        endif
!
      enddo; enddo
!
      if (gamma1<0. .and. lroot) &
          print*,'planet_hc: must have gamma>1 for planet solution'
!
!  Use average density of box as unit density
!
      lnrhosum_thisbox = sum(f(l1:l2,m1:m2,n1:n2,ilnrho))
      if (ip<14) &
        print*,'planet_hc: iproc,lnrhosum_thisbox=',iproc,lnrhosum_thisbox
!
!  Must put sum_thisbox in 1-dimensional array
!
      lnrhosum_thisbox_tmp = (/ lnrhosum_thisbox /)
!
!  Add sum_thisbox up for all processors, deliver to root
!
      call mpireduce_sum(lnrhosum_thisbox_tmp,lnrhosum_wholebox,1)
      if (lroot .and. ip<14) &
        print*,'planet_hc: lnrhosum_wholebox=',lnrhosum_wholebox
!
!  Calculate <rho> and send to all processors
!
      if (lroot) rho0 = exp(-lnrhosum_wholebox(1)/(nxgrid*nygrid*nzgrid))
      call mpibcast_real(rho0,1)
      if (ip<14) print*,'planet_hc: iproc,rho0=',iproc,rho0
!
!  Multiply density by rho0 (divide by <rho>)
!
      f(l1:l2,m1:m2,n1:n2,ilnrho) = f(l1:l2,m1:m2,n1:n2,ilnrho) + log(rho0)
!
    endsubroutine planet_hc
!***********************************************************************
    subroutine planet(rbound,f,eps,radius,gamma,cs20,rho0,width,hh0)
!
!  Cylindrical planet solution (Goldreich, Narayan, Goodman 1987)
!
!   jun-03/anders: coded (adapted from old 'planet', now 'planet_hc')
!
      use Mpicomm, only: mpireduce_sum, mpibcast_real
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (nx) :: hh, xi, r_ell
      real :: rbound,sigma2,sigma,delta2,delta,eps,radius
      real :: gamma,eps2,radius2,width,a_ell,b_ell,c_ell
      real :: gamma1,ztop,cs20,hh0
      real :: lnrhosum_thisbox,rho0
      real, dimension(1) :: lnrhosum_thisbox_tmp,lnrhosum_wholebox
!
!  calculate sigma
!
      if (lroot) print*,'planet: qshear,eps=',qshear,eps
      eps2=eps**2
      radius2=radius**2
      sigma2=2*qshear/(1.-eps2)
      if (sigma2<0. .and. lroot) then
        print*, &
            'planet: sigma2<0 not allowed; choose another value of eps_planet'
      else
        sigma=sqrt(sigma2)
      endif
!
      gamma1=gamma-1.
!
!  calculate delta
!
      delta2=(2.-sigma)*sigma
      if (lroot) print*,'planet: sigma,delta2,radius=',sigma,delta2,radius
      if (delta2<0. .and. lroot) then
        print*,'planet: delta2<0 not allowed'
      else
        delta=sqrt(delta2)
      endif
!
      ztop=z0+lz
      if (lroot) print*,'planet: ztop=', ztop
!
!  Cylinder vortex 3-D solution (b_ell along x, a_ell along y)
!
      b_ell = radius
      a_ell = radius/eps
      c_ell = radius*delta
      if (lroot) print*,'planet: Ellipse axes (b_ell,a_ell,c_ell)=', &
          b_ell,a_ell,c_ell
      if (lroot) print*,'planet: width,rbound',width,rbound
!
      do n=n1,n2; do m=m1,m2
        r_ell = sqrt(x(l1:l2)**2/b_ell**2+y(m)**2/a_ell**2)
!
!  xi is 1 inside vortex and 0 outside
!
        xi = 1/(exp((1/width)*(r_ell-rbound))+1.0)
!
!  Calculate enthalpy inside vortex
!
        hh = 0.5*delta2*Omega**2*(radius2-x(l1:l2)**2-eps2*y(m)**2) &
             -0.5*Omega**2*z(n)**2 + 0.5*Omega**2*ztop**2 + hh0
!
!  Calculate enthalpy outside vortex
!
        where (r_ell>1.0) hh=-0.5*Omega**2*z(n)**2 + 0.5*Omega**2*ztop**2 + hh0
!
!  Calculate velocities (Kepler speed subtracted)
!
        f(l1:l2,m,n,iux)=   eps2*sigma *Omega*y(m)*xi
        f(l1:l2,m,n,iuy)=(qshear-sigma)*Omega*x(l1:l2)*xi
!
!  calculate density, depending on what gamma is
!
        if (lentropy) then
          f(l1:l2,m,n,ilnrho)=(log(gamma1*hh/cs20)-gamma*f(l1:l2,m,n,iss))/gamma1
        else
          if (gamma==1.) then
            f(l1:l2,m,n,ilnrho) = hh/cs20
          else
            f(l1:l2,m,n,ilnrho) = log(gamma1*hh/cs20)/gamma1
          endif
        endif
      enddo; enddo
!
!  Use average density of box as unit density
!
      lnrhosum_thisbox = sum(f(l1:l2,m1:m2,n1:n2,ilnrho))
      if (ip<14) &
        print*,'planet_hc: iproc,lnrhosum_thisbox=',iproc,lnrhosum_thisbox
!
!  Must put sum_thisbox in 1-dimensional array
!
      lnrhosum_thisbox_tmp = (/ lnrhosum_thisbox /)
!
!  Add sum_thisbox up for all processors, deliver to root
!
      call mpireduce_sum(lnrhosum_thisbox_tmp,lnrhosum_wholebox,1)
      if (lroot .and. ip<14) &
          print*,'planet_hc: lnrhosum_wholebox=',lnrhosum_wholebox
!
!  Calculate <rho> and send to all processors
!
      if (lroot) rho0 = exp(-lnrhosum_wholebox(1)/(nxgrid*nygrid*nzgrid))
      call mpibcast_real(rho0,1)
      if (ip<14) print*,'planet_hc: iproc,rho0=',iproc,rho0
!
!  Multiply density by rho0 (divide by <rho>)
!
      f(l1:l2,m1:m2,n1:n2,ilnrho) = f(l1:l2,m1:m2,n1:n2,ilnrho) + log(rho0)
!
    endsubroutine planet
!***********************************************************************
    subroutine vortex_2d(f,b_ell,width,rbound)
!
!  Ellipsoidal planet solution (Goldreich, Narayan, Goodman 1987)
!
!   8-jun-04/anders: adapted from planet
!
      real, dimension (mx,my,mz,mvar) :: f
      real, dimension (nx) :: r_ell, xi
      real :: sigma,eps_ell,a_ell,b_ell,width,rbound
!
!  calculate sigma
!
      eps_ell=0.5
      if (lroot) print*,'vortex_2d: qshear,eps_ell=',qshear,eps_ell
      sigma=sqrt(2*qshear/(1.-eps_ell**2))
!
!  ellipse parameters
!
      a_ell = b_ell/eps_ell
      if (lroot) print*,'vortex_2d: Ellipse axes (b_ell,a_ell)=', b_ell,a_ell
!
!  Limit vortex to within r_ell
!
      do n=n1,n2; do m=m1,m2
        r_ell = sqrt(x(l1:l2)**2/b_ell**2+y(m)**2/a_ell**2)
        xi = 1./(exp((1/width)*(r_ell-rbound))+1.)
!
!  Calculate velocities (Kepler speed subtracted)
!
        f(l1:l2,m,n,iux)=eps_ell**2*sigma*Omega*y(m)*xi
        f(l1:l2,m,n,iuy)=(qshear-sigma)  *Omega*x(l1:l2)*xi
      enddo; enddo
!
    endsubroutine vortex_2d
!***********************************************************************
    subroutine baroclinic(f,gamma,rho0,dlnrhobdx,co1_ss,co2_ss,cs20)
!
!  Baroclinic shearing sheet initial condition
!  11-nov-03/anders: coded
!
      real, dimension (mx,my,mz,mfarray) :: f
      real :: sz,I_int
      real :: gamma,rho0,dlnrhobdx,co1_ss,co2_ss,cs20
!
!  Specify vertical entropy and integral of exp(-sz/cp)*z
!
      do n=n1,n2; do m=m1,m2
        if (co1_ss/=0.0 .and. co2_ss==0.0) then
          if (lroot) print*,'baroclinic: sz =', co1_ss,'*abs(z(n))'
          sz = co1_ss*abs(z(n))
          I_int = 1/(co1_ss**2)*( 1 - exp(-sz) * (1+co1_ss*abs(z(n))) )
        elseif (co1_ss==0.0 .and. co2_ss/=0.0) then
          if (lroot) print*,'baroclinic: sz =', co2_ss,'*zz**2'
          sz = co2_ss*z(n)**2
          I_int = -1/(2*co2_ss)*( exp(-co2_ss*z(n)**2)-1 )
        elseif (lroot) then
          print*, 'baroclinic: no valid sz specified'
        endif
 
        f(l1:l2,m,n,iss) = sz
!
!  Solution to hydrostatic equlibrium in the z-direction
!
        f(l1:l2,m,n,ilnrho) = 1/(gamma-1)*log( (1-gamma)/cs20 * I_int + 1 ) - sz
!
!  Toroidal velocity comes from hyd. stat. eq. equ. in the x-direction
!
        f(l1:l2,m,n,iuy) = cs20/(2*Omega)*exp( gamma*f(l1:l2,m,n,iss) + &
            (gamma-1)*f(l1:l2,m,n,ilnrho) ) * dlnrhobdx/gamma
!
      enddo; enddo
!
    endsubroutine baroclinic
!***********************************************************************
    subroutine crazy(ampl,f,i)
!
!  A crazy initial condition
!  (was useful to initialize all points with finite values)
!
!  19-may-02/axel: coded
!
      integer :: i,j
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl
!
      if (lroot) print*, 'crazy: sinusoidal magnetic field: for debugging purposes'
      j=i; f(:,:,:,j)=f(:,:,:,j)+ampl*&
        spread(spread(sin(2*x),2,my),3,mz)*&
        spread(spread(sin(3*y),1,mx),3,mz)*&
        spread(spread(cos(1*z),1,mx),2,my)
      j=i+1; f(:,:,:,j)=f(:,:,:,j)+ampl*&
        spread(spread(sin(5*x),2,my),3,mz)*&
        spread(spread(sin(1*y),1,mx),3,mz)*&
        spread(spread(cos(2*z),1,mx),2,my)
      j=i+2; f(:,:,:,j)=f(:,:,:,j)+ampl*&
        spread(spread(sin(3*x),2,my),3,mz)*&
        spread(spread(sin(4*y),1,mx),3,mz)*&
        spread(spread(cos(2*z),1,mx),2,my)
!
    endsubroutine crazy
!***********************************************************************
    subroutine htube(ampl,f,i1,i2,radius,eps,center1_x,center1_y,center1_z)
!
!  Horizontal flux tube (for vector potential, or passive scalar)
!
!   7-jun-02/axel+vladimir: coded
!  11-sep-02/axel: allowed for scalar field (if i1=i2)
!
      integer :: i1,i2
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (nx) :: tmp,modulate,tube_radius_sqr
      real :: ampl,radius,eps,ky
      real :: center1_x,center1_y,center1_z
!
      if (ampl==0) then
        f(:,:,:,i1:i2)=0
        if (lroot) print*,'htube: set variable to zero; i1,i2=',i1,i2
      else
        ky=2*pi/Ly
        if (lroot) then
          print*,'htube: implement y-dependent flux tube in xz-plane; i1,i2=',i1,i2
          print*,'htube: radius,eps=',radius,eps
        endif
!
! completely quenched "gaussian"
!
        do n=n1,n2; do m=m1,m2
          tube_radius_sqr=(x(l1:l2)-center1_x)**2+(z(n)-center1_z)**2
!         tmp=.5*ampl/modulate*exp(-tube_radius_sqr)/& 
!                   (max((radius*modulate)**2-tube_radius_sqr,1e-6))
          tmp=1./(1.+tube_radius_sqr/radius**2)
!
!  check whether vector or scalar
!
          if (i1==i2) then
            if (lroot) print*,'htube: set scalar'
            f(l1:l2,m,n,i1)=tmp
          elseif (i1+2==i2) then
            if (lroot) print*,'htube: set vector'
            f(l1:l2,m,n,i1 )=+(z(n)-center1_z)*tmp
            f(l1:l2,m,n,i1+1)=tmp*eps
            f(l1:l2,m,n,i1+2)=-(x(l1:l2)-center1_x)*tmp
         else
            if (lroot) print*,'htube: bad value of i2=',i2
          endif
!
        enddo; enddo
      endif
!
    endsubroutine htube
!***********************************************************************
    subroutine htube_x(ampl,f,i1,i2,radius,eps,center1_x,center1_y,center1_z)
!
!  Horizontal flux tube pointing in the x-direction
!  (for vector potential, or passive scalar)
!
!  14-apr-09/axel: adapted from htube
!
      integer :: i1,i2
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (nx) :: tmp,modulate,tube_radius_sqr
      real :: ampl,radius,eps,kx
      real :: center1_x,center1_y,center1_z
!
      if (ampl==0) then
        f(:,:,:,i1:i2)=0
        if (lroot) print*,'htube_x: set variable to zero; i1,i2=',i1,i2
      else
        kx=2*pi/Lx
        if (lroot) then
          print*,'htube_x: implement y-dependent flux tube in xz-plane; i1,i2=',i1,i2
          print*,'htube_x: radius,eps=',radius,eps
        endif
!
!  modulation pattern
!
        if (eps==0.) then
          modulate=1.
        else
          modulate=1.+eps*cos(kx*x(l1:l2))
        endif
!
! completely quenched "gaussian"
!
        do n=n1,n2; do m=m1,m2
          tube_radius_sqr=(y(m)-center1_y)**2+(z(n)-center1_z)**2
          tmp=modulate/(1.+tube_radius_sqr/radius**2)
!
!  check whether vector or scalar
!
          if (i1==i2) then
            if (lroot.and.ip<10) print*,'htube_x: set scalar'
            f(l1:l2,m,n,i1)=tmp
          elseif (i1+2==i2) then
            if (lroot.and.ip<10) print*,'htube_x: set vector'
            f(l1:l2,m,n,i1  )=+0.
            f(l1:l2,m,n,i1+1)=-(z(n)-center1_z)*tmp
            f(l1:l2,m,n,i1+2)=+(y(m)-center1_y)*tmp
         else
            if (lroot) print*,'htube_x: bad value of i2=',i2
          endif
!
        enddo; enddo
      endif
!
    endsubroutine htube_x
!***********************************************************************
    subroutine htube_erf(ampl,f,i1,i2,a,eps,center1_x,center1_y,center1_z,width)
!
!  Horizontal flux tube (for vector potential) which gives error-function border profile
! for the magnetic field. , or passive scalar)
!
!   18-mar-09/dhruba: aped from htube
!
      integer :: i1,i2,l
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (nx) :: modulate
      real :: ampl,a,eps,ky,width,tmp,radius,a_minus_r
      real :: center1_x,center1_y,center1_z
!
      if (ampl==0) then
        f(:,:,:,i1:i2)=0
        if (lroot) print*,'htube: set variable to zero; i1,i2=',i1,i2
      else
        ky=2*pi/Ly
        if (lroot) then
          print*,'htube: implement y-dependent flux tube in xz-plane; i1,i2=',i1,i2
          print*,'htube: radius,eps=',radius,eps
        endif
!
! An integral of error function. 
!
        do n=n1,n2; do m=m1,m2;do l=l1,l2 
          radius= sqrt((x(l)-center1_x)**2+(z(n)-center1_z)**2)
          a_minus_r= a - radius
          if (radius .gt. tini) then
             tmp = (-(exp(-width*a_minus_r**2))/(4.*sqrt(pi)*width) +  &
                  radius*(1+erfunc(width*a_minus_r))/4. + & 
                  2*a*(exp(-(a**2)*(width**2)) - exp(-(a_minus_r**2)*(width**2)))/(8.*radius*width) + &
                  (1+2*(a**2)*(width**2))*(erfunc(a*width) - erfunc(width*a_minus_r))/(8.*radius*width**2))/radius
          else
             tmp = 0
             write(*,*) 'wrong place:radius,tini',radius,tini
          endif
          write(*,*) 'Dhruba:radius,tini,a,a_minus_r,width,tmp',radius,tini,a,a_minus_r,width,tmp
!         tmp=.5*ampl/modulate*exp(-tube_radius_sqr)/& 
!                   (max((radius*modulate)**2-tube_radius_sqr,1e-6))
!
!  check whether vector or scalar
!
          if (i1==i2) then
            if (lroot) print*,'htube: set scalar'
            f(l,m,n,i1)=tmp
          elseif (i1+2==i2) then
            if (lroot) print*,'htube: set vector'
            f(l,m,n,i1 )=-(z(n)-center1_z)*tmp*ampl
            f(l,m,n,i1+1)=tmp*eps
            f(l,m,n,i1+2)=+(x(l)-center1_x)*tmp*ampl
         else
            if (lroot) print*,'htube: bad value of i2=',i2
          endif
!
        enddo; enddo;enddo
      endif
!
    endsubroutine htube_erf
!***********************************************************************
    subroutine htube2(ampl,f,i1,i2,radius,epsilon_nonaxi)
!
!  Horizontal flux tube (for vector potential, or passive scalar)
!
!   7-jun-02/axel+vladimir: coded
!  11-sep-02/axel: allowed for scalar field (if i1=i2)
!
      integer :: i1,i2
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (nx) :: tmp,modulate
      real :: ampl,radius,epsilon_nonaxi,ky
!
      if (ampl==0) then
        f(:,:,:,i1:i2)=0
        if (lroot) print*,'htube2: set variable to zero; i1,i2=',i1,i2
      else
        ky=2*pi/Ly
        if (lroot) then
          print*,'htube2: implement y-dependent flux tube in xz-plane; i1,i2=',i1,i2
          print*,'htube2: radius,epsilon_nonaxi=',radius,epsilon_nonaxi
        endif
!
!  constant, when epsilon_nonaxi; otherwise modulation about zero
!
        do n=n1,n2; do m=m1,m2
          if (epsilon_nonaxi==0) then
            modulate(:)=1.0
          else
            modulate=epsilon_nonaxi*sin(ky*y(m))
          endif
!
! completely quenched "gaussian"
!
          tmp=.5*ampl*modulate*exp(-(x(l1:l2)**2+z(n)**2)/radius**2)
!
!  check whether vector or scalar
!
          if (i1==i2) then
            if (lroot) print*,'htube2: set scalar'
            f(l1:l2,m,n,i1)=tmp
          elseif (i1+2==i2) then
            if (lroot) print*,'htube2: set vector'
            f(l1:l2,m,n,i1 )=+z(n)*tmp
            f(l1:l2,m,n,i1+1)=0.
            f(l1:l2,m,n,i1+2)=-x(l1:l2)*tmp
          else
            if (lroot) print*,'htube2: bad value of i2=',i2
          endif
        enddo; enddo
      endif
!
    endsubroutine htube2
!***********************************************************************
    subroutine magsupport(ampl,f,gravz,cs0,rho0)
!
!  magnetically supported horizontal flux layer
!  (for aa):  By^2 = By0^2 * exp(-z/H),
!  where H=2*cs20/abs(gravz) and ampl=cs0*sqrt(2*rho0)
!  should be used when invoking this routine.
!  Here, ampl=pmag/pgas.
!
!   7-dec-02/axel: coded
!
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl,H,A0,gravz,cs0,rho0,lnrho0
!
      if (ampl==0) then
        if (lroot) print*,'magsupport: do nothing'
      else
        lnrho0=log(rho0)
        H=(1+ampl)*cs0**2/abs(gravz)
        A0=-2*H*ampl*cs0*sqrt(2*rho0)
        if (lroot) print*,'magsupport: H,A0=',H,A0
        do n=n1,n2; do m=m1,m2
          f(l1:l2,m,n,iaa)=A0*exp(-.5*z(n)/H)
          f(l1:l2,m,n,ilnrho)=lnrho0-z(n)/H
        enddo; enddo
      endif
!
    endsubroutine magsupport
!***********************************************************************
    subroutine hfluxlayer(ampl,f,i,zflayer,width)
!
!  Horizontal flux layer (for vector potential)
!
!  19-jun-02/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl,zflayer,width
!
      if (ampl==0) then
        f(:,:,:,i:i+2)=0
        if (lroot) print*,'hfluxlayer: set variable to zero; i=',i
      else
        if (lroot) print*,'hfluxlayer: horizontal flux layer; i=',i
        if ((ip<=16).and.lroot) print*,'hfluxlayer: ampl,width=',ampl,width
        do n=n1,n2; do m=m1,m2
          f(l1:l2,m,n,i  )=0.0
          f(l1:l2,m,n,i+1)=ampl*tanh((z(n)-zflayer)/width)
          f(l1:l2,m,n,i+2)=0.0
        enddo; enddo
      endif
!
    endsubroutine hfluxlayer
!***********************************************************************
    subroutine vfluxlayer(ampl,f,i,xflayer,width)
!
!  Vertical flux layer (for vector potential)
!
!  22-mar-04/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl,xflayer,width
!
      if (ampl==0) then
        f(:,:,:,i:i+2)=0
        if (lroot) print*,'hfluxlayer: set variable to zero; i=',i
      else
        if (lroot) print*,'hfluxlayer: horizontal flux layer; i=',i
        if ((ip<=16).and.lroot) print*,'hfluxlayer: ampl,width=',ampl,width
        do n=n1,n2; do m=m1,m2
          f(l1:l2,m,n,i  )=0.0
          f(l1:l2,m,n,i+1)=0.0
          f(l1:l2,m,n,i+2)=-ampl*tanh((x(l1:l2)-xflayer)/width)
        enddo; enddo
      endif
!
    endsubroutine vfluxlayer
!***********************************************************************
    subroutine arcade_x(ampl,f,i,kx,kz)
!
!  Arcade-like structures around x=0
!
!  17-jun-04/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl,kx,kz,zmid
!
      if (ampl==0) then
        f(:,:,:,i:i+2)=0
        if (lroot) print*,'expcos_x: set variable to zero; i=',i
      else
        zmid=.5*(xyz0(3)+xyz1(3))
        if ((ip<=16).and.lroot) then
          print*,'arcade_x: i,zmid=',i,zmid
          print*,'arcade_x: ampl,kx,kz=',ampl,kx,kz
        endif
!
        do n=n1,n2; do m=m1,m2
!         f(l1:l2,m,n,i+1)=f(l1:l2,m,n,i+1)+ampl*exp(-.5*(kx*x(l1:l2))**2)* &
!           cos(min(abs(kz*(z(n)-zmid)),.5*pi))
          f(l1:l2,m,n,i+1)=f(l1:l2,m,n,i+1) &
            +ampl*cos(kx*x(l1:l2))*exp(-abs(kz*z(n)))
        enddo; enddo
!
      endif
!
    endsubroutine arcade_x
!***********************************************************************
    subroutine halfcos_x(ampl,f,i)
!
!  Uniform B_x field (for vector potential)
!
!  19-jun-02/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl,kz,zbot
!
      if (ampl==0) then
        f(:,:,:,i:i+2)=0
        if (lroot) print*,'halfcos_x: set variable to zero; i=',i
      else
        print*,'halscos_x: half cosine x-field ; i=',i
        kz=0.5*pi/Lz
        zbot=xyz0(3)
        ! ztop=xyz0(3)+Lxyz(3)
        if ((ip<=16).and.lroot) print*,'halfcos_x: ampl,kz=',ampl,kz
        do n=n1,n2; do m=m1,m2
          f(l1:l2,m,n,i  )=0.0
          f(l1:l2,m,n,i+1)=-ampl*sin(kz*(z(n)-zbot))
          f(l1:l2,m,n,i+2)=0.0
        enddo; enddo
      endif
!
    endsubroutine halfcos_x
!***********************************************************************
    subroutine uniform_x(ampl,f,i)
!
!  Uniform B_x field (for vector potential)
!
!  19-jun-02/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl
!
      if (ampl==0) then
        f(:,:,:,i:i+2)=0
        if (lroot) print*,'uniform_x: set variable to zero; i=',i
      else
        print*,'uniform_x: uniform x-field ; i=',i
        if ((ip<=16).and.lroot) print*,'uniform_x: ampl=',ampl
        do n=n1,n2; do m=m1,m2
          f(l1:l2,m,n,i  )=0.0
          f(l1:l2,m,n,i+1)=-ampl*z(n)
          f(l1:l2,m,n,i+2)=0.0
        enddo; enddo
      endif
!
    endsubroutine uniform_x
!***********************************************************************
    subroutine uniform_y(ampl,f,i)
!
!  Uniform B_y field (for vector potential)
!
!  27-jul-02/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl
!
      if (ampl==0) then
        f(:,:,:,i:i+2)=0
        if (lroot) print*,'uniform_y: set variable to zero; i=',i
      else
        print*,'uniform_y: uniform y-field ; i=',i
        if ((ip<=16).and.lroot) print*,'uniform_y: ampl=',ampl
        do n=n1,n2; do m=m1,m2
          f(l1:l2,m,n,i  )=ampl*z(n)
          f(l1:l2,m,n,i+1)=0.0
          f(l1:l2,m,n,i+2)=0.0
        enddo; enddo
      endif
!
    endsubroutine uniform_y
!***********************************************************************
    subroutine uniform_z(ampl,f,i)
!
!  Uniform B_z field (for vector potential)
!
!  24-jul-03/axel: adapted from uniform_x
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl
!
      if (ampl==0) then
        f(:,:,:,i:i+2)=0
        if (lroot) print*,'uniform_z: set variable to zero; i=',i
      else
        print*,'uniform_z: uniform z-field ; i=',i
        if ((ip<=16).and.lroot) print*,'uniform_z: ampl=',ampl
        do n=n1,n2; do m=m1,m2
          if (lcartesian_coords) then
            f(l1:l2,m,n,i  )=0.0
            f(l1:l2,m,n,i+1)=+ampl*x(l1:l2)
            f(l1:l2,m,n,i+2)=0.0
          elseif (lcylindrical_coords) then
            f(l1:l2,m,n,i  )=0.0
            f(l1:l2,m,n,i+1)=-ampl*x(l1:l2)*y(m)
            f(l1:l2,m,n,i+2)=0.0
          endif
        enddo; enddo
      endif
!
    endsubroutine uniform_z
!***********************************************************************
    subroutine uniform_phi(ampl,f,i)
!
!  Uniform B_phi field (for vector potential)
!
!  27-jul-02/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (nx) :: rr
      real :: ampl
!
      if (ampl==0) then
        f(:,:,:,i:i+2)=0
        if (lroot) print*,'uniform_phi: set variable to zero; i=',i
      else
        print*,'uniform_phi: uniform phi-field ; i=',i
        if ((ip<=16).and.lroot) print*,'uniform_phi: ampl=',ampl
        do n=n1,n2; do m=m1,m2
          rr=sqrt(x(l1:l2)**2+y(m)**2)
          f(l1:l2,m,n,i  )=0.0
          f(l1:l2,m,n,i+1)=0.0
          f(l1:l2,m,n,i+2)=-ampl*rr
        enddo; enddo
      endif
!
    endsubroutine uniform_phi
!***********************************************************************
    subroutine phi_comp_over_r(ampl,f,i)
!
!  B_phi ~ 1/R field (in terms of vector potential)
!  meaningful mainly in cylindrical coordinates, otherwise it will be By~1/x
!
!  05-jul-07/mgellert: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl
!
      if (ampl==0) then
        f(:,:,:,i:i+2)=0
        if (lroot) print*,'phi_comp_over_r: set variable to zero; i=',i
      else
        if (coord_system=='cylindric') then
          print*,'phi_comp_over_r: set Bphi ~ 1/r ; i=',i
        else
          print*,'phi_comp_over_r: set By ~ 1/x ; i=',i
        endif
        if ((ip<=16).and.lroot) print*,'phi_comp_over_r: ampl=',ampl
        do n=n1,n2; do m=m1,m2
          f(l1:l2,m,n,i  )=0.0!ampl*z(n)/x(l1:l2)
          f(l1:l2,m,n,i+1)=0.0
          f(l1:l2,m,n,i+2)=-ampl*log(x(l1:l2))
        enddo; enddo
      endif
!
    endsubroutine phi_comp_over_r
!***********************************************************************
    subroutine vfield(ampl,f,i,kx)
!
!  Vertical field, for potential field test
!
!  14-jun-02/axel: coded
!  02-aug-2005/joishi: allowed for arbitrary kx
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl
      real,optional :: kx
      real :: k
!
      if (present(kx)) then
         k = kx
      else
         k = 2*pi/Lx
      endif

      if (ampl==0) then
        f(:,:,:,i:i+2)=0
        if (lroot) print*,'vfield: set variable to zero; i=',i
      else
        if (lroot) print*,'vfield: implement x-dependent vertical field'
        if ((ip<=8).and.lroot) print*,'vfield: x-dependent vertical field'
        do n=n1,n2; do m=m1,m2
          f(l1:l2,m,n,i  )=0.0
          f(l1:l2,m,n,i+1)=ampl*sin(k*x(l1:l2))
          f(l1:l2,m,n,i+2)=0.0
        enddo; enddo
      endif
!
    endsubroutine vfield
!***********************************************************************
    subroutine vfield2(ampl,f,i)
!
!  Vertical field, zero on boundaries
!
!  22-jun-04/anders: adapted from vfield
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl,kx
!
      if (ampl==0) then
        f(:,:,:,i:i+2)=0
        if (lroot) print*,'vfield2: set variable to zero; i=',i
      else
        kx=2*pi/Lx
        if (lroot) print*,'vfield2: implement x-dependent vertical field'
        do n=n1,n2; do m=m1,m2
          f(l1:l2,m,n,i  )=0.0
          f(l1:l2,m,n,i+1)=ampl*cos(kx*x(l1:l2))
          f(l1:l2,m,n,i+2)=0.0
        enddo; enddo
      endif
!
    endsubroutine vfield2
!***********************************************************************
    subroutine posnoise_vect(ampl,f,i1,i2)
!
!  Add Gaussian noise (= normally distributed) white noise for variables i1:i2
!
!  28-may-04/axel: adapted from gaunoise
!
      integer :: i,i1,i2
      real, dimension (mx) :: tmp
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl
!
!  set gaussian random noise vector
!
      if (ampl==0) then
        if (lroot) print*,'posnoise_vect: ampl=0 for i1,i2=',i1,i2
      else
        if ((ip<=8).and.lroot) print*,'posnoise_vect: i1,i2=',i1,i2
          if (lroot) print*,'posnoise_vect: variable i=',i
        do n=1,mz; do m=1,my
          do i=i1,i2
            call random_number_wrapper(tmp)
            f(:,m,n,i)=f(:,m,n,i)+ampl*tmp
          enddo
        enddo; enddo
      endif
!
    endsubroutine posnoise_vect
!***********************************************************************
    subroutine posnoise_scal(ampl,f,i)
!
!  Add Gaussian (= normally distributed) white noise for variable i
!
!  28-may-04/axel: adapted from gaunoise
!
      integer :: i
      real, dimension (mx) :: tmp
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl
!
!  set positive random noise vector
!
      if (ampl==0) then
        if (lroot) print*,'posnoise_scal: ampl=0 for i=',i
      else
        if ((ip<=8).and.lroot) print*,'posnoise_scal: i=',i
        if (lroot) print*,'posnoise_scal: variable i=',i
        do n=1,mz; do m=1,my
          call random_number_wrapper(tmp)
          f(:,m,n,i)=f(:,m,n,i)+ampl*tmp
        enddo; enddo
      endif
!
!  Wouldn't the following be equivalent (but clearer)?
!
!  call posnoise_vect(ampl,f,i,i)
!
!
    endsubroutine posnoise_scal
!***********************************************************************
    subroutine gaunoise_vect(ampl,f,i1,i2)
!
!  Add Gaussian noise (= normally distributed) white noise for variables i1:i2
!
!  23-may-02/axel: coded
!  10-sep-03/axel: result only *added* to whatever f array had before
!
      real :: ampl
      real, dimension (mx,my,mz,mfarray) :: f
      integer :: i1,i2
!
      real, dimension (mx) :: r,p,tmp
      integer :: i
!
      intent(in)    :: ampl,i1,i2
      intent(inout) :: f
!
!  set gaussian random noise vector
!
      if (ampl==0) then
        if (lroot) print*,'gaunoise_vect: ampl=0 for i1,i2=',i1,i2
      else
        if ((ip<=8).and.lroot) print*,'gaunoise_vect: i1,i2=',i1,i2
        do n=1,mz; do m=1,my
          do i=i1,i2
            if (lroot.and.m==1.and.n==1) print*,'gaunoise_vect: variable i=',i
            if (modulo(i-i1,2)==0) then
              call random_number_wrapper(r)
              call random_number_wrapper(p)
              tmp=sqrt(-2*log(r))*sin(2*pi*p)
            else
              tmp=sqrt(-2*log(r))*cos(2*pi*p)
            endif
            f(:,m,n,i)=f(:,m,n,i)+ampl*tmp
          enddo
        enddo; enddo
      endif
!
    endsubroutine gaunoise_vect
!***********************************************************************
    subroutine gaunoise_scal(ampl,f,i)
!
!  Add Gaussian (= normally distributed) white noise for variable i
!
!  23-may-02/axel: coded
!  10-sep-03/axel: result only *added* to whatever f array had before
!
      real :: ampl
      real, dimension (mx,my,mz,mfarray) :: f
      integer :: i
!
      real, dimension (mx) :: r,p,tmp
!
      intent(in)    :: ampl,i
      intent(inout) :: f
!
!  set gaussian random noise vector
!
      if (ampl==0) then
        if (lroot) print*,'gaunoise_scal: ampl=0 for i=',i
      else
        if ((ip<=8).and.lroot) print*,'gaunoise_scal: i=',i
        if (lroot) print*,'gaunoise_scal: variable i=',i
        do n=1,mz; do m=1,my
          call random_number_wrapper(r)
          call random_number_wrapper(p)
          tmp=sqrt(-2*log(r))*sin(2*pi*p)
          f(:,m,n,i)=f(:,m,n,i)+ampl*tmp
        enddo; enddo
      endif
!
!  Wouldn't the following be equivalent (but clearer)?
!
!  call gaunoise_vect(ampl,f,i,i)
!
!
    endsubroutine gaunoise_scal
!***********************************************************************
    subroutine gaunoise_prof_vect(ampl,f,i1,i2)
!
!  Add Gaussian (= normally distributed) white noise for variables i1:i2
!  with amplitude profile AMPL.
!
! 18-apr-04/wolf: adapted from gaunoise_vect
!
      real, dimension (nz) :: ampl
      real, dimension (mx,my,mz,mfarray) :: f
      integer :: i1,i2
!
      real, dimension (mx) :: r,p,tmp
      integer :: i
!
      intent(in)    :: ampl,i1,i2
      intent(inout) :: f
!
      if ((ip<=8).and.lroot) print*,'GAUNOISE_PROF_VECT: i1,i2=',i1,i2
      do n=1,mz; do m=1,my
        do i=i1,i2
          print*, m, n
          if (lroot.and.m==1.and.n==1) print*,'gaunoise_vect: variable i=',i
          if (modulo(i-i1,2)==0) then
            call random_number_wrapper(r)
            call random_number_wrapper(p)
            tmp=sqrt(-2*log(r))*sin(2*pi*p)
          else
            tmp=sqrt(-2*log(r))*cos(2*pi*p)
          endif
          f(:,m,n,i)=f(:,m,n,i)+ampl(n)*tmp
        enddo
      enddo; enddo
!
    endsubroutine gaunoise_prof_vect
!***********************************************************************
    subroutine gaunoise_prof_scal(ampl,f,i)
!
!  Add Gaussian (= normally distributed) white noise for variable i with
!  amplitude profile AMPL.
!
! 18-apr-04/wolf: coded
!
      real, dimension (nz) :: ampl
      real, dimension (mx,my,mz,mfarray) :: f
      integer :: i
!
      intent(in)    :: ampl,i
      intent(inout) :: f
!
      if ((ip<=8).and.lroot) print*,'GAUNOISE_PROF_SCAL: i=',i
      call gaunoise_prof_vect(ampl,f,i,i)
!
    endsubroutine gaunoise_prof_scal
!***********************************************************************
    subroutine gaunoise_rprof_vect(ampl,f,i1,i2)
!
!  Add Gaussian noise within r_int < r < r_ext.
!  Use PROF as buffer variable so we don't need to allocate a large
!  temporary.
!
!  18-apr-04/wolf: coded
!
      use Sub, only: cubic_step
!
      real :: ampl
      real, dimension (mx,my,mz,mfarray) :: f
      integer :: i1,i2
!
      real, dimension (mx) :: prof, rr, r, p, tmp
      real :: dr
      integer :: i
!
      intent(in)  :: ampl,i1,i2
      intent(out) :: f
!
!  set up profile
!
      do n=1,mz; do m=1,my
        rr=sqrt(x(:)**2+y(m)**2+z(n)**2)
        dr = r_ext-max(0.,r_int)
        prof = 1 - cubic_step(rr,r_ext,0.25*dr,SHIFT=-1.)
        prof = 1 - cubic_step(rr,r_ext,0.25*dr,SHIFT=-1.)
        if (r_int>0.) then
          prof = prof*cubic_step(rr,r_int,0.25*dr,SHIFT=1.)
        endif
        prof = ampl*prof
!
        do i=i1,i2
          if (lroot.and.m==1.and.n==1) print*,'gaunoise_vect: variable i=',i
          if (modulo(i-i1,2)==0) then
            call random_number_wrapper(r)
            call random_number_wrapper(p)
            tmp=sqrt(-2*log(r))*sin(2*pi*p)
          else
            tmp=sqrt(-2*log(r))*cos(2*pi*p)
          endif
          f(:,m,n,i)=f(:,m,n,i)+prof*tmp
        enddo
!
      enddo; enddo
!
    endsubroutine gaunoise_rprof_vect
!***********************************************************************
    subroutine gaunoise_rprof_scal(ampl,f,i)
!
!  Add Gaussian noise within r_int < r < r_ext.
!  Use PROF as buffer variable so we don't need to allocate a large
!  temporary.
!
!  18-apr-04/wolf: coded
!
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl
      integer :: i
!
      intent(in) :: ampl,i
      intent(out) :: f
!
      call gaunoise_rprof_vect(ampl,f,i,i)
!
    endsubroutine gaunoise_rprof_scal
!***********************************************************************
    subroutine trilinear(ampl,f,ivar)
!
!  Produce a profile that is linear in any non-periodic direction, but
!  periodic in periodic ones (for testing purposes).
!
!  5-nov-02/wolf: coded
! 23-nov-02/axel: included scaling factor ampl, corrected lperi argument
!
      real :: ampl
      real, dimension (mx,my,mz,mfarray) :: f
      integer :: ivar
!
      real, dimension (nx) :: tmp
!
      if (lroot) print*, 'trilinear: ivar = ', ivar
!
!  x direction
!
      do n=n1,n2; do m=m1,m2
        if (lperi(1)) then
          tmp = sin(2*pi/Lx*(x(l1:l2)-xyz0(1)-0.25*Lxyz(1)))
        else
          tmp = x(l1:l2)
        endif
!
!  y direction
!
        if (lperi(2)) then
          tmp = tmp + 10*sin(2*pi/Ly*(y(m)-xyz0(2)-0.25*Lxyz(2)))
        else
          tmp = tmp + 10*y(m)
        endif
!
!  z direction
!
        if (lperi(3)) then
          tmp = tmp + 100*sin(2*pi/Lz*(z(n)-xyz0(3)-0.25*Lxyz(3)))
        else
          tmp = tmp + 100*z(n)
        endif
!
        f(l1:l2,m,n,ivar) = ampl*tmp
!
      enddo; enddo
!
    endsubroutine trilinear
!***********************************************************************
    subroutine cos_cos_sin(ampl,f,ivar)
!
!  Produce a profile that is linear in any non-periodic direction, but
!  periodic in periodic ones (for testing purposes).
!
!  7-dec-02/axel: coded
!
      integer :: ivar
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl,kx,ky,kz
!
      if (lroot) print*, 'cos_cos_sin: ivar = ', ivar
!
      kx=2*pi/Lx*3
      ky=2*pi/Ly*3
      kz=pi/Lz
      do n=n1,n2; do m=m1,m2
        f(l1:l2,m,n,ivar) = ampl*cos(kx*x(l1:l2))*cos(ky*y(m))*sin(kz*z(n))
      enddo; enddo
!
    endsubroutine cos_cos_sin
!***********************************************************************
    subroutine tor_pert(ampl,f,ivar)
!
!  Produce a profile that is periodic in the y- and z-directions.
!  For testing the Balbus-Hawley instability of a toroidal magnetic field
!
!  12-feb-03/ulf: coded
!
      integer :: ivar
      real, dimension (mx,my,mz,mfarray) :: f
      real :: ampl,ky,kz
!
      if (lroot) print*, 'tor_pert: sinusoidal modulation of ivar = ', ivar
!
      ky=2*pi/Ly
      kz=2.*pi/Lz
      do n=n1,n2; do m=m1,m2
        f(l1:l2,m,n,ivar) = ampl*cos(ky*y(m))*cos(kz*z(n))
      enddo; enddo
!
    endsubroutine tor_pert
!***********************************************************************
    subroutine const_omega(ampl,f,ivar)
!
!  Set up profile for differential rotation
!
!  16-jul-03/axel: coded
!
      real :: ampl
      real, dimension (mx,my,mz,mfarray) :: f
      integer :: ivar
!
      if (lroot) print*, 'const_omega: constant angular velcoity  = ', ivar
!
      do n=n1,n2; do m=m1,m2
        f(l1:l2,m,n,ivar) = ampl*x(l1:l2)*sinth(m)
      enddo; enddo
!
    endsubroutine const_omega
!***********************************************************************
    subroutine diffrot(ampl,f,ivar)
!
!  Set up profile for differential rotation
!
!  16-jul-03/axel: coded
!
      real :: ampl
      real, dimension (mx,my,mz,mfarray) :: f
      integer :: ivar
!
      if (lroot) print*, 'diffrot: sinusoidal modulation of ivar = ', ivar
!
      do n=n1,n2; do m=m1,m2
        f(l1:l2,m,n,ivar) = ampl*cos(x(l1:l2))*cos(z(n))
      enddo; enddo
!
    endsubroutine diffrot
!***********************************************************************
    subroutine olddiffrot(ampl,f,ivar)
!
!  Set up profile for differential rotation
!
!  16-jul-03/axel: coded
!
      real :: ampl
      real, dimension (mx,my,mz,mfarray) :: f
      integer :: ivar
!
      real :: kx,kz
!
      if (lroot) print*, 'olddiffrot: sinusoidal modulation of ivar = ', ivar
!
      kx=.5*pi/Lx
      kz=.5*pi/Lz
      do n=n1,n2; do m=m1,m2
        f(l1:l2,m,n,ivar) = ampl*sin(kx*x(l1:l2))*cos(kz*z(n))
      enddo; enddo
!
    endsubroutine olddiffrot
!***********************************************************************
    subroutine powern(ampl,initpower,cutoff,f,i1,i2)
!
!   Produces k^initpower*exp(-k**2/cutoff**2)  spectrum.
!   Still just one processor (but can be remeshed afterwards).
!
!   07-may-03/tarek: coded
!
      use Fourier
!
      real :: ampl,initpower,cutoff
      integer :: i1,i2
!
      real, dimension (nx,ny,nz) :: k2
      real, dimension (nx) :: k2x
      real, dimension (ny) :: k2y
      real, dimension (nz) :: k2z
      real, dimension (mx,my,mz,mfarray) :: f
!
      real, dimension (nx,ny,nz) :: u_re,u_im
      integer :: i
!
      if (ampl==0) then
        f(:,:,:,i1:i2)=0
        if (lroot) print*,'powern: set variable to zero; i1,i2=',i1,i2
      else
        call gaunoise_vect(ampl,f,i1,i2) ! which has a k^2. spectrum

        if ((initpower.ne.2.).or.(cutoff.ne.0.)) then

          k2x = cshift((/(i-(nx+1)/2,i=0,nx-1)/),+(nx+1)/2)*2*pi/Lx
          k2 =      (spread(spread(k2x,2,ny),3,nz))**2

          k2y = cshift((/(i-(ny+1)/2,i=0,ny-1)/),+(ny+1)/2)*2*pi/Ly
          k2 = k2 + (spread(spread(k2y,1,nx),3,nz))**2

          k2z = cshift((/(i-(nz+1)/2,i=0,nz-1)/),+(nz+1)/2)*2*pi/Lz
          k2 = k2 + (spread(spread(k2z,1,nx),2,ny))**2

          k2(1,1,1) = 1.  ! Avoid division by zero

          do i=i1,i2
            u_re=f(l1:l2,m1:m2,n1:n2,i)
            u_im=0.
            !  fft of gausian noise w/ k^2 spectrum
            call fourier_transform(u_re,u_im)
            ! change to k^n spectrum
            u_re =(k2)**(.25*initpower-.5)*u_re
            u_im =(k2)**(.25*initpower-.5)*u_im
            ! cutoff (changed to hyperviscous cutoff filter)
            if (cutoff .ne. 0.) then
              u_re = u_re*exp(-(k2/cutoff**2.)**2)
              u_im = u_im*exp(-(k2/cutoff**2.)**2)
            endif
            ! back to real space
            call fourier_transform(u_re,u_im,linv=.true.)
            f(l1:l2,m1:m2,n1:n2,i)=u_re

            if (lroot .and. (cutoff.eq.0)) then
              print*,'powern: k^',initpower,' spectrum : var  i=',i
            else
              print*,'powern: with cutoff : k^n*exp(-k^4/k0^4) w/ n=', &
                     initpower,', k0 =',cutoff,' : var  i=',i
            endif
          enddo !i
      endif !(initpower.ne.2.).or.(cutoff.ne.0.)

    endif !(ampl.eq.0)
!
    endsubroutine powern
!***********************************************************************
    subroutine power_randomphase(ampl,initpower,cutoff,f,i1,i2,lscale_tobox)
!
!   Produces k^initpower*exp(-k**2/cutoff**2)  spectrum.
!   Still just one processor (but can be remeshed afterwards).
!
!   07-may-03/tarek: coded
!   08-may-08/nils: adapted to work on multiple processors
!   06-jul-08/nils+andre: Fixed problem when running on 
!      mult. procs (thanks to Andre Kapelrud for finding the bug) 
!
      use Fourier
!
      logical, intent(in), optional :: lscale_tobox
      integer :: i,i1,i2,ikx,iky,ikz
      real, dimension (nx,ny,nz) :: k2
      real, dimension(nxgrid) :: kx
      real, dimension(nygrid) :: ky
      real, dimension(nzgrid) :: kz
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (nx,ny,nz) :: u_re,u_im,r
      real :: ampl,initpower,mhalf,cutoff,scale_factor

      if (ampl==0) then
        f(:,:,:,i1:i2)=0
        if (lroot) print*,'power_randomphase: set variable to zero; i1,i2=',i1,i2
      else
!
!  calculate k^2
!
        scale_factor=1
        if (lscale_tobox) scale_factor=2*pi/Lx
        kx=cshift((/(i-(nxgrid+1)/2,i=0,nxgrid-1)/),+(nxgrid+1)/2)*scale_factor

        scale_factor=1
        if (lscale_tobox) scale_factor=2*pi/Ly
        ky=cshift((/(i-(nygrid+1)/2,i=0,nygrid-1)/),+(nygrid+1)/2)*scale_factor

        scale_factor=1
        if (lscale_tobox) scale_factor=2*pi/Lz
        kz=cshift((/(i-(nzgrid+1)/2,i=0,nzgrid-1)/),+(nzgrid+1)/2)*scale_factor
!
!  integration over shells
!
        if (lroot .AND. ip<10) &
             print*,'power_randomphase:fft done; now integrate over shells...'
        do ikz=1,nz
          do iky=1,ny
            do ikx=1,nx
              k2(ikx,iky,ikz)=kx(ikx)**2+ky(iky+ipy*ny)**2+kz(ikz+ipz*nz)**2
            enddo
          enddo
        enddo        
        if (lroot) k2(1,1,1) = 1.  ! Avoid division by zero
!
!  To get shell integrated power spectrum E ~ k^n, we need u ~ k^m
!  and since E(k) ~ u^2 k^2 we have n=2m+2, so m=n/2-1.
!  Further, since we operate on k^2, we need m/2 (called mhalf below)
!
        mhalf=.5*(.5*initpower-1)
!
!  generate all 3 velocity components separately
!
        do i=i1,i2
          ! generate k^n spectrum with random phase (between -pi and pi)
          call random_number_wrapper(r); u_re=ampl*k2**mhalf*cos(pi*(2*r-1))
          call random_number_wrapper(r); u_im=ampl*k2**mhalf*sin(pi*(2*r-1))
          ! cutoff (changed to hyperviscous cutoff filter)
          if (cutoff .ne. 0.) then
            u_re = u_re*exp(-(k2/cutoff**2.)**2)
            u_im = u_im*exp(-(k2/cutoff**2.)**2)
          endif
          ! back to real space
          call fourier_transform(u_re,u_im,linv=.true.)
          f(l1:l2,m1:m2,n1:n2,i)=u_re
          if (lroot .and. (cutoff.eq.0)) then
            print*,'powern: k^',initpower,' spectrum : var  i=',i
          else
            print*,'powern: with cutoff : k^n*exp(-k^4/k0^4) w/ n=', &
                   initpower,', k0 =',cutoff,' : var  i=',i
          endif
        enddo !i

      endif !(ampl.eq.0)
!
    endsubroutine power_randomphase
!***********************************************************************
    subroutine random_isotropic_KS(ampl,initpower,cutoff,f,i1,i2,N_modes)
!
!   produces random, isotropic field from energy spectrum following the
!   KS method (Malik and Vassilicos, 1999.)
!
!   more to do; unsatisfactory so far - at least for a steep power-law energy spectrum
!
!   24-sept-04/snod: coded first attempt
!
    use Sub
    integer :: modeN,N_modes,l,n,m,i1,i2
    real, dimension (mx,my,mz,mfarray) :: f

! how many wavenumbers?
    real, dimension (3,1024) :: kk,RA,RB !or through whole field for each wavenumber?
    real, dimension (3) :: k_unit,vec,ee,e1,e2,field
    real :: ampl,initpower,cutoff,kmin,ps,k,phi,theta,alpha,beta,dk
    real :: ex,ey,ez,norm,kdotx,r

!
!    minlen=Lxyz(1)/(nx-1)
!    kmax=2.*pi/minlen
!    N_modes=int(0.5*(nx-1))
!    hh=Lxyz(1)/(nx-1)
!    pta=(nx)**(1.0/(nx-1))
!    do modeN=1,N_modes
!       ggt=(kkmax-kkmin)/(N_modes-1)
!       ggt=(kkmax/kkmin)**(1./(N_modes-1))
!        k(modeN)=kmin+(ggt*(modeN-1))
!        k(modeN)=(modeN+3)*2*pi/Lxyz(1)
!       k(modeN)=kkmin*(ggt**(modeN-1)
!    enddo
!
!    do modeN=1,N_modes
!       if (modeN.eq.1)delk(modeN)=(k(modeN+1)-K(modeN))
!       if (modeN.eq.N_modes)delk(modeN)=(k(modeN)-k(modeN-1))
!       if (modeN.gt.1.and.modeN.lt.N_modes)delk(modeN)=(k(modeN+1)-k(modeN-2))/2.0
!    enddo
!          mk=(k2*k2)*((1.0 + (k2/(bk_min*bk_min)))**(0.5*initpower-2.0))
!
!  set kmin
!
    kmin=2.*pi/Lxyz(1)
!
    do modeN=1,N_modes
!
!  pick wavenumber
!
       k=modeN*kmin
!
!  calculate dk
!
       dk=1.0*kmin
!
!   pick 4 random angles for each mode
!

       call random_number_wrapper(r); theta=pi*(2*r - 0.)
       call random_number_wrapper(r); phi=pi*(2*r - 0.)
       call random_number_wrapper(r); alpha=pi*(2*r - 0.)
       call random_number_wrapper(r); beta=pi*(2*r - 0.)
!       call random_number_wrapper(r); gamma(modeN)=pi*(2*r - 0.)  ! random phase?

!
!   make a random unit vector by rotating fixed vector to random position
!   (alternatively make a random transformation matrix for each k)
!
       k_unit(1)=sin(theta)*cos(phi)
       k_unit(2)=sin(theta)*sin(phi)
       k_unit(3)=cos(theta)
!
!   make a vector kk of length k from the unit vector for each mode
!
       kk(:,modeN)=k*k_unit(:)
!
!   construct basis for plane having rr normal to it
!   (bit of code from forcing to construct x', y')
!
       if ((k_unit(2).eq.0).and.(k_unit(3).eq.0)) then
        ex=0.; ey=1.; ez=0.
       else
        ex=1.; ey=0.; ez=0.
       endif
       ee = (/ex, ey, ez/)
       call cross(k_unit(:),ee,e1)
       call dot2(e1,norm); e1=e1/sqrt(norm) ! e1: unit vector perp. to kk
       call cross(k_unit(:),e1,e2)
       call dot2(e2,norm); e2=e2/sqrt(norm) ! e2: unit vector perp. to kk, e1
!
!   make two random unit vectors RB and RA in the constructed plane
!
       RA(:,modeN) = cos(alpha)*e1 + sin(alpha)*e2
       RB(:,modeN) = cos(beta)*e1  + sin(beta)*e2
!
!   define the power spectrum (ps=sqrt(2.*power_spectrum(k)*delta_k/3.))
!
       ps=(k**(initpower/2.))*sqrt(dk*2./3.)
!
!   give RA and RB length ps
!
       RA(:,modeN)=ps*RA(:,modeN)
       RB(:,modeN)=ps*RB(:,modeN)
!
!   form RA = RA x k_unit and RB = RB x k_unit
!
       call cross(RA(:,modeN),k_unit(:),RA(:,modeN))
       call cross(RB(:,modeN),k_unit(:),RB(:,modeN))
!
     enddo
!
!   make the field
!
    do n=n1,n2
      do m=m1,m2
        do l=l1,l2
          field=0.  ! initialize field
          vec(1)=x(l)    ! local coordinates?
          vec(2)=y(m)
          vec(3)=z(n)
          do modeN=1,N_modes  ! sum over N_modes modes
             call dot(kk(:,modeN),vec,kdotx)
             field = field + cos(kdotx)*RA(:,modeN) + sin(kdotx)*RB(:,modeN)
          enddo
          f(l,m,n,i1)   = f(l,m,n,i1)   + field(1)
          f(l,m,n,i1+1) = f(l,m,n,i1+1) + field(2)
          f(l,m,n,i1+2) = f(l,m,n,i1+2) + field(3)
        enddo
      enddo
    enddo
!
    endsubroutine random_isotropic_KS
!**********************************************************
    subroutine set_thermodynamical_quantities&
         (f,ptlaw,ics2,iglobal_cs2,iglobal_glnTT)
!
!  Subroutine that sets the thermodynamical quantities 
!   - static sound speed, temperature or entropy -
!  based on a sound speed which is given as input. 
!  This routine is not general. For llocal_iso (locally 
!  isothermal approximation, the temperature gradient is 
!  stored as a static array, as the (analytical) derivative 
!  of an assumed power-law profile for the sound speed
!  (hence the parameter ptlaw) 
! 
!  05-jul-07/wlad: coded
!  16-dec-08/wlad: moved pressure gradient correction to 
!                  the density module (correct_pressure_gradient)
!                  Now this subroutine really only sets the thermo
!                  variables.
!
      use FArrayManager
      use Mpicomm
      use EquationOfState, only: gamma,gamma1,get_cp1,&
                                 cs20,cs2bot,cs2top,lnrho0
      use Sub,             only: power_law,get_radial_distance
      use Messages       , only: warning
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension(nx) :: rr,rr_sph,rr_cyl,cs2,lnrho
      real, dimension(nx) :: tmp1,tmp2,gslnTT,corr
      real :: cp1,ptlaw
      integer, pointer, optional :: iglobal_cs2,iglobal_glnTT
      integer :: i,ics2
      logical :: lheader,lenergy
!
      intent(in)  :: ptlaw
      intent(out) :: f
!
!  Break if llocal_iso is used with entropy or temperature
!
      lenergy=ltemperature.or.lentropy
!
      if (lenergy.and.llocal_iso) &
           call stop_it("set_thermodynamical_quantities: You are "//&
           "evolving the energy, but llocal_iso is switched "//&
           " on in start.in. Better stop and change it")
!
!  Break if gamma=1.0 and energy is solved
!
      if ((gamma==1.0).and.lenergy) then
        if (lroot) then
          print*,"" 
          print*,"set_thermodynamical_quantities: gamma=1.0 means "         
          print*,"an isothermal disk. You don't need entropy or "           
          print*,"temperature for that. Switch to noentropy instead, "      
          print*,"which is a better way of having isothermality. "          
          print*,"If you do not want isothermality but wants to keep a "    
          print*,"static temperature gradient through the simulation, use " 
          print*,"noentropy with the switch llocal_iso in init_pars "       
          print*,"(start.in file) and add the following line "      
          print*,""
          print*,"! MGLOBAL CONTRIBUTION 4"
          print*,""
          print*,"(containing the '!') to the header of the "//&
               "src/cparam.local file"
          print*,""
          call stop_it("")
        endif
      endif
!
      if (lroot) print*,'Temperature gradient with power law=',ptlaw
!
!  Get the pointers to the global arrays if needed
!
      if (llocal_iso) then
        nullify(iglobal_glnTT)
        call farray_use_global('glnTT',iglobal_glnTT)
      endif
!
      if (lenergy) call get_cp1(cp1)
!
      do m=m1,m2
        do n=n1,n2
          lheader=((m==m1).and.(n==n1).and.lroot)
!
!  Put in the global arrays if they are to be static
!
          cs2=f(l1:l2,m,n,ics2)
          if (llocal_iso) then
!
            f(l1:l2,m,n,iglobal_cs2) = cs2
!
            call get_radial_distance(rr_sph,rr_cyl);   rr=rr_cyl
            if (lspherical_coords.or.lsphere_in_a_box) rr=rr_sph
!
            gslnTT=-ptlaw/((rr/r_ref)**2+rsmooth**2)*rr/r_ref**2
!
            if (lcartesian_coords) then
              f(l1:l2,m,n,iglobal_glnTT  )=gslnTT*x(l1:l2)/rr_cyl
              f(l1:l2,m,n,iglobal_glnTT+1)=gslnTT*y(m)    /rr_cyl
              f(l1:l2,m,n,iglobal_glnTT+2)=0.
            else! (lcylindrical_coords.or.lspherical_coords) then
              f(l1:l2,m,n,iglobal_glnTT  )=gslnTT
              f(l1:l2,m,n,iglobal_glnTT+1)=0.
              f(l1:l2,m,n,iglobal_glnTT+2)=0.
            endif
          elseif (ltemperature) then
!  else do it as temperature ...
            f(l1:l2,m,n,ilnTT)=log(cs2*cp1/gamma1)
          elseif (lentropy) then
!  ... or entropy
            lnrho=f(l1:l2,m,n,ilnrho) ! initial condition, always log
            f(l1:l2,m,n,iss)=1./(gamma*cp1)*(log(cs2/cs20)-gamma1*(lnrho-lnrho0))
          else
!
            call stop_it("No thermodynamical variable. Choose if you want "//&
                 "a local thermodynamical approximation "//&
                 "(switch llocal_iso=T init_pars and entropy=noentropy on "//&
                 "Makefile.local), or if you want to compute the "//&
                 "temperature directly and evolve it in time.")
          endif
        enddo
      enddo
!
!  Word of warning...
!
      if (llocal_iso) then
        if (associated(iglobal_cs2)) then
          print*,"Max global cs2 = ",&
               maxval(f(l1:l2,m1:m2,n1:n2,iglobal_cs2))
          print*,"Sum global cs2 = ",&
               sum(f(l1:l2,m1:m2,n1:n2,iglobal_cs2))
        endif
        if (associated(iglobal_glnTT)) then
          print*,"Max global glnTT(1) = ",&
               maxval(f(l1:l2,m1:m2,n1:n2,iglobal_glnTT))
          print*,"Sum global glnTT(1) = ",&
               sum(f(l1:l2,m1:m2,n1:n2,iglobal_glnTT))
        endif
      endif
!
      cs2bot=cs20
      cs2top=cs20
!
      if (lroot) &
           print*,"thermodynamical quantities successfully set"
!
    endsubroutine set_thermodynamical_quantities
!*************************************************************
    subroutine corona_init(f)
!
!  Initialize the density for a given temperature profile 
!  in the vertical (z) direction by solving for hydrostatic 
!  equilibrium. 
!  The temperature is hard coded as three polynomials.
!
!  07-dec-05/bing : coded.
!
      use Cdata
      use EquationOfState, only: lnrho0,gamma,gamma1,cs20,cs2top,cs2bot
!
      real, dimension(mx,my,mz,mfarray) :: f
      real :: tmp,ztop,zbot
      real, dimension(150) :: b_lnT,b_lnrho,b_z
      integer :: i,lend,j
!
!  temperature given as function lnT(z) in SI units
!  [T] = K   &   [z] = Mm   & [rho] = kg/m^3
!
      if (pretend_lnTT) print*,'corona_init: not implemented for pretend_lnTT=T'
!      
      inquire(IOLENGTH=lend) tmp
      open (10,file='driver/b_lnT.dat',form='unformatted',status='unknown',recl=lend*150)
      read (10) b_lnT
      read (10) b_z
      close (10)
!
      open (10,file='driver/b_lnrho.dat',form='unformatted',status='unknown',recl=lend*150)
      read (10) b_lnrho
      close (10)
!
      b_z = b_z*1.e6/unit_length
      b_lnT = b_lnT - alog(real(unit_temperature))
      b_lnrho = b_lnrho - alog(real(unit_density))
!
! simple linear interpolation
!
      do j=n1,n2
         do i=1,149
            if (z(j) .ge. b_z(i) .and. z(j) .lt. b_z(i+1) ) then
               f(:,:,j,ilnrho) = (b_lnrho(i)*(b_z(i+1) - z(j)) +   &
                    b_lnrho(i+1)*(z(j)-b_z(i)) ) / (b_z(i+1)-b_z(i))
!
               tmp =  (b_lnT(i)*(b_z(i+1) - z(j)) +   &
                    b_lnT(i+1)*(z(j)-b_z(i)) ) / (b_z(i+1)-b_z(i))
!
               if (ltemperature) then
                  f(:,:,j,ilnTT) = tmp
               elseif (lentropy) then
                  f(:,:,j,iss) = (alog(gamma1/cs20)+tmp- &
                       gamma1*(f(l1,m1,j,ilnrho)-lnrho0))/gamma
               endif
               exit
            endif
         enddo
         if (z(j) .ge. b_z(150)) then
            f(:,:,j,ilnrho) = b_lnrho(150)
!
            tmp =  b_lnT(150)
!
            if (ltemperature) then
               f(:,:,j,ilnTT) = tmp
            elseif (lentropy) then
               f(:,:,j,iss) = (alog(gamma1/cs20)+tmp- &
                    gamma1*(f(l1,m1,j,ilnrho)-lnrho0))/gamma
            endif
         endif
      enddo
!
      ztop=xyz0(3)+Lxyz(3)
      zbot=xyz0(3)
!
      do i=1,149
         if (ztop .ge. b_z(i) .and. ztop .lt. b_z(i+1) ) then
!
            tmp =  (b_lnT(i)*(b_z(i+1) - ztop) +   &
                 b_lnT(i+1)*(ztop-b_z(i)) ) / (b_z(i+1)-b_z(i))
            cs2top = gamma1*exp(tmp)
!
         elseif (ztop .ge. b_z(150)) then
            cs2top = gamma1*exp(b_lnT(150))
         endif
         if (zbot .ge. b_z(i) .and. zbot .lt. b_z(i+1) ) then
!
            tmp =  (b_lnT(i)*(b_z(i+1) - zbot) +   &
                 b_lnT(i+1)*(zbot-b_z(i)) ) / (b_z(i+1)-b_z(i))
            cs2bot = gamma1*exp(tmp)
!
         endif
      enddo
!
    endsubroutine corona_init
!*********************************************************
    subroutine mdi_init(f)
!
!  Intialize the vector potential
!  by potential field extrapolation
!  of a mdi magnetogram
!
!  13-dec-05/bing : coded.
!
      use Cdata
      use Fourier
      use Sub
!
      real, dimension(mx,my,mz,mfarray) :: f
      real, dimension(nxgrid,nygrid) :: kx,ky,k2
!
      real, dimension(nxgrid,nygrid) :: Bz0,Bz0_i,Bz0_r
      real, dimension(nxgrid,nygrid) :: Ax_r,Ax_i,Ay_r,Ay_i
!
      real, dimension(nxgrid) :: kxp
      real, dimension(nygrid) :: kyp
!
      real :: mu0_SI,u_b
      integer :: i,idx2,idy2
!
!  Auxiliary quantities:
!
!  idx2 and idy2 are essentially =2, but this makes compilers
!  complain if nygrid=1 (in which case this is highly unlikely to be
!  correct anyway), so we try to do this better:
      idx2 = min(2,nxgrid)
      idy2 = min(2,nygrid)
!
!  Magnetic field strength unit [B] = u_b
!
      mu0_SI = 4.*pi*1.e-7
      u_b = unit_velocity*sqrt(mu0_SI/mu0*unit_density)
!
      kxp=cshift((/(i-(nxgrid-1)/2,i=0,nxgrid-1)/),+(nxgrid-1)/2)*2*pi/Lx
      kyp=cshift((/(i-(nygrid-1)/2,i=0,nygrid-1)/),+(nygrid-1)/2)*2*pi/Ly
!
      kx =spread(kxp,2,nygrid)
      ky =spread(kyp,1,nxgrid)
!
      k2 = kx*kx + ky*ky
!
      open (11,file='driver/magnetogram_k.dat',form='unformatted')
      read (11) Bz0
      close (11)
!
      Bz0_i = 0.
      Bz0_r = Bz0 * 1e-4 / u_b ! Gauss to Tesla  and SI to PENCIL units
!
!  Fourier Transform of Bz0:
!
      call fourier_transform_other(Bz0_r,Bz0_i)
!
      do i=n1,n2
!
!  Calculate transformed vector potential at "each height"
!
         where (k2 .ne. 0 )
            Ax_r = -Bz0_i*ky/k2*exp(-sqrt(k2)*z(i) )
            Ax_i =  Bz0_r*ky/k2*exp(-sqrt(k2)*z(i) )
!
            Ay_r =  Bz0_i*kx/k2*exp(-sqrt(k2)*z(i) )
            Ay_i = -Bz0_r*kx/k2*exp(-sqrt(k2)*z(i) )
         elsewhere
            Ax_r = -Bz0_i*ky/ky(1,idy2)*exp(-sqrt(k2)*z(i) )
            Ax_i =  Bz0_r*ky/ky(1,idy2)*exp(-sqrt(k2)*z(i) )
!
            Ay_r =  Bz0_i*kx/kx(idx2,1)*exp(-sqrt(k2)*z(i) )
            Ay_i = -Bz0_r*kx/kx(idx2,1)*exp(-sqrt(k2)*z(i) )
         endwhere
!
         call fourier_transform_other(Ax_r,Ax_i,linv=.true.)
!
         call fourier_transform_other(Ay_r,Ay_i,linv=.true.)
!
         f(l1:l2,m1:m2,i,iax)=Ax_r(ipx*nx+1:(ipx+1)*nx+1,ipy*ny+1:(ipy+1)*ny+1)
         f(l1:l2,m1:m2,i,iay)=Ay_r(ipx*nx+1:(ipx+1)*nx+1,ipy*ny+1:(ipy+1)*ny+1)
         f(l1:l2,m1:m2,i,iaz)=0.
      enddo
!
    endsubroutine mdi_init
!*********************************************************
    subroutine const_lou(ampl,f,i)
!
!  PLEASE ADD A DESCRIPTION
!
!  5-nov-05/weezy: coded
!
    use Cdata
    use General

    real, dimension (mx,my,mz,mfarray) :: f
    real :: ampl
    integer::i
!
    do n=n1,n2; do m=m1,m2
      f(l1:l2,m,n,i  )=ampl*cos(2.*pi*y(m))/32.*pi
      f(l1:l2,m,n,i+1)=ampl*cos(2.*pi*z(n))/32.*pi
      f(l1:l2,m,n,i+2)=ampl*cos(2.*pi*x(l1:l2))/32.*pi
    enddo; enddo
!
    endsubroutine const_lou
!*********************************************************
endmodule Initcond
