! $Id: radiation_ray.f90,v 1.44 2003-11-06 16:54:10 theine Exp $

!!!  NOTE: this routine will perhaps be renamed to radiation_feautrier
!!!  or it may be combined with radiation_ray.

!** AUTOMATIC CPARAM.INC GENERATION ****************************
! Declare (for generation of cparam.inc) the number of f array
! variables and auxiliary variables added by this module
!
! MVAR CONTRIBUTION 0
! MAUX CONTRIBUTION 1
!
!***************************************************************

module Radiation

!  Radiation (solves transfer equation along rays)
!  The direction of the ray is given by the vector (lrad,mrad,nrad),
!  and the parameters radx0,rady0,radz0 gives the maximum number of
!  steps of the direction vector in the corresponding direction.

  use Cparam
!
  implicit none
!
  character (len=2*bclen+1), dimension(3) :: bc_rad=(/'0:0','0:0','S:0'/)
  character (len=bclen), dimension(3) :: bc_rad1,bc_rad2
  integer, parameter :: maxdir=26
  real, dimension (mx,my,mz) :: Srad,lnchi,tau,Qrad,Qrad0
  integer, dimension (maxdir,3) :: dir
  real, dimension (maxdir) :: weight
  real :: dtau_thresh
  integer :: lrad,mrad,nrad,rad2
  integer :: idir,ndir
  integer :: llstart,llstop,lsign
  integer :: mmstart,mmstop,msign
  integer :: nnstart,nnstop,nsign
  integer :: ipystart,ipystop,ipzstart,ipzstop
  logical :: lperiodic_ray,lperiodic_ray1,lperiodic_ray2,lperiodic_ray3
!
!  default values for one pair of vertical rays
!
  integer :: radx=0,rady=0,radz=1,rad2max=1
!
  logical :: nocooling=.false.
!
!  definition of dummy variables for FLD routine
!
  real :: DFF_new=0.  !(dum)
  integer :: i_frms=0,i_fmax=0,i_Erad_rms=0,i_Erad_max=0
  integer :: i_Egas_rms=0,i_Egas_max=0,i_Qradrms,i_Qradmax

  namelist /radiation_init_pars/ &
       radx,rady,radz,rad2max,bc_rad

  namelist /radiation_run_pars/ &
       radx,rady,radz,rad2max,bc_rad,nocooling

  contains

!***********************************************************************
    subroutine register_radiation()
!
!  initialise radiation flags
!
!  24-mar-03/axel+tobi: coded
!
      use Cdata, only: iQrad,nvar,naux,aux_var,aux_count,lroot
      use Cdata, only: lradiation,lradiation_ray
      use Sub, only: cvs_id
      use Mpicomm, only: stop_it
!
      logical, save :: first=.true.
!
      if (first) then
        first = .false.
      else
        call stop_it('register_radiation called twice')
      endif
!
      lradiation=.true.
      lradiation_ray=.true.
!
!  set indices for auxiliary variables
!
      iQrad = mvar + naux +1; naux = naux + 1
!
      if ((ip<=8) .and. lroot) then
        print*, 'register_radiation: radiation naux = ', naux
        print*, 'iQrad = ', iQrad
      endif
!
!  identify version number (generated automatically by CVS)
!
      if (lroot) call cvs_id( &
           "$Id: radiation_ray.f90,v 1.44 2003-11-06 16:54:10 theine Exp $")
!
!  Check that we aren't registering too many auxilary variables
!
      if (nvar > mvar) then
        if (lroot) write(0,*) 'naux = ', naux, ', maux = ', maux
        call stop_it('register_radiation: naux > maux')
      endif
!
!  Writing files for use with IDL
!
      if (naux < maux) aux_var(aux_count)=',Qrad $'
      if (naux == maux) aux_var(aux_count)=',Qrad'
      aux_count=aux_count+1
      if (lroot) write(15,*) 'Qrad = fltarr(mx,my,mz)*one'
!
    endsubroutine register_radiation
!***********************************************************************
    subroutine initialize_radiation()
!
!  Calculate number of directions of rays
!  Do this in the beginning of each run
!
!  16-jun-03/axel+tobi: coded
!  03-jul-03/tobi: position array added
!
      use Cdata, only: lroot
      use Sub, only: parse_bc_rad
      use Mpicomm, only: stop_it
!
!  check that the number of rays does not exceed maximum
!
      if(radx>1) call stop_it("radx currently must not be greater than 1")
      if(rady>1) call stop_it("rady currently must not be greater than 1")
      if(radz>1) call stop_it("radz currently must not be greater than 1")
!
!  count
!
      idir=1
!
      do nrad=-radz,radz
      do mrad=-rady,rady
      do lrad=-radx,radx
        rad2=lrad**2+mrad**2+nrad**2
        if(rad2>0.and.rad2<=rad2max) then 
          dir(idir,1)=lrad
          dir(idir,2)=mrad
          dir(idir,3)=nrad
          idir=idir+1
        endif
      enddo
      enddo
      enddo
!
!  total number of directions
!
      ndir=idir-1
!
!  determine when terms like  exp(-dtau)-1  are to be evaluated
!  as a power series 
! 
!  experimentally determined optimum
!  relative errors for (emdtau1, emdtau2) will be
!  (1e-6, 1.5e-4) for floats and (3e-13, 1e-8) for doubles
!
      dtau_thresh=1.6*epsilon(dtau_thresh)**0.25
!
!  calculate weights
!
      weight=1.0/ndir
!
      if (lroot) print*,'initialize_radiation: ndir=',ndir
!
!  check boundary conditions
!
      if (lroot) print*,'initialize_radiation: bc_rad=',bc_rad
      call parse_bc_rad(bc_rad,bc_rad1,bc_rad2)
      if (lroot) print*,'initialize_radiation: bc_rad1,bc_rad2=',bc_rad1,bc_rad2
!
    endsubroutine initialize_radiation
!***********************************************************************
    subroutine radtransfer(f)
!
!  Integration radioation transfer equation along rays
!
!  This routine is called before the communication part
!  (certainly needs to be given a better name)
!  All rays start with zero intensity
!
!  16-jun-03/axel+tobi: coded
!
      use Cdata, only: ldebug,headt,iQrad
      use Ionization, only: radcalc
!
      real, dimension(mx,my,mz,mvar+maux) :: f
!
!  identifier
!
      if(ldebug.and.headt) print*,'radtransfer'
!
!  calculate source function and opacity
!
      call radcalc(f,lnchi,Srad)
!
!  initialize heating rate
!
      f(:,:,:,iQrad)=0
!
!  loop over rays
!
      do idir=1,ndir
!
        call Qintrinsic
!
        if (lperiodic_ray) then
          call Qperiodic_ray
        else
          call Qcommunicate
          call Qrevision
        endif
!
        f(:,:,:,iQrad)=f(:,:,:,iQrad)+weight(idir)*Qrad
!
      enddo
!
    endsubroutine radtransfer
!***********************************************************************
    subroutine Qintrinsic
!
!  Integration radiation transfer equation along rays
!
!  This routine is called before the communication part
!  All rays start with zero intensity
!
!  16-jun-03/axel+tobi: coded
!   3-aug-03/axel: added amax1(dtau,dtaumin) construct
!
      use Cdata, only: ldebug,headt,dx,dy,dz
!
      real :: dlength,emdtau
      real :: Srad1st,Srad2nd,emdtau1,emdtau2
      real :: dtau_m,dtau_p,dSdtau_m,dSdtau_p
      integer :: l,m,n
!
!  identifier
!
      if(ldebug.and.headt) print*,'Qintrinsic'
!
!  get direction components
!
      lrad=dir(idir,1)
      mrad=dir(idir,2)
      nrad=dir(idir,3)
!
!  are we dealing with a periodic ray?
!
      lperiodic_ray1=bc_rad1(1)=='p'.and.bc_rad2(1)=='p'.and.mrad==0.and.nrad==0
      lperiodic_ray1=bc_rad1(2)=='p'.and.bc_rad2(2)=='p'.and.nrad==0.and.lrad==0
      lperiodic_ray1=bc_rad1(3)=='p'.and.bc_rad2(3)=='p'.and.lrad==0.and.mrad==0
      lperiodic_ray=lperiodic_ray1.or.lperiodic_ray2.or.lperiodic_ray3
!
!  line elements
!
      dlength=sqrt((dx*lrad)**2+(dy*mrad)**2+(dz*nrad)**2)
!
!  determine start and stop positions
!
      llstart=l1; llstop=l2; lsign=+1
      mmstart=m1; mmstop=m2; msign=+1
      nnstart=n1; nnstop=n2; nsign=+1
      if (lrad>0) then; llstart=l1; llstop=l2; lsign=+1; endif
      if (lrad<0) then; llstart=l2; llstop=l1; lsign=-1; endif
      if (mrad>0) then; mmstart=m1; mmstop=m2; msign=+1; endif
      if (mrad<0) then; mmstart=m2; mmstop=m1; msign=-1; endif
      if (nrad>0) then; nnstart=n1; nnstop=n2; nsign=+1; endif
      if (nrad<0) then; nnstart=n2; nnstop=n1; nsign=-1; endif
!
!  set optical depth and intensity initially to zero
!
      tau=0
      Qrad=0
!
!  loop over all meshpoints
!
      do l=llstart,llstop,lsign 
      do m=mmstart,mmstop,msign
      do n=nnstart,nnstop,nsign
!
        dtau_m=exp((lnchi(l-lrad,m-mrad,n-nrad)+lnchi(l,m,n))/2)*dlength
        dtau_p=exp((lnchi(l,m,n)+lnchi(l+lrad,m+mrad,n+nrad))/2)*dlength
        dSdtau_m=(Srad(l,m,n)-Srad(l-lrad,m-mrad,n-nrad))/dtau_m
        dSdtau_p=(Srad(l+lrad,m+mrad,n+nrad)-Srad(l,m,n))/dtau_p
        Srad1st=(dSdtau_p*dtau_m+dSdtau_m*dtau_p)/(dtau_m+dtau_p)
        Srad2nd=2*(dSdtau_p-dSdtau_m)/(dtau_m+dtau_p)
        emdtau=exp(-dtau_m)
        if (dtau_m>dtau_thresh) then
          emdtau1=1-emdtau
          emdtau2=emdtau*(1+dtau_m)-1
        else
          emdtau1=dtau_m-dtau_m**2/2+dtau_m**3/6
          emdtau2=-dtau_m**2/2+dtau_m**3/3
        endif
        tau(l,m,n)=tau(l-lrad,m-mrad,n-nrad)+dtau_m
        Qrad(l,m,n)=Qrad(l-lrad,m-mrad,n-nrad)*emdtau &
                   -Srad1st*emdtau1-Srad2nd*emdtau2
!
      enddo
      enddo
      enddo
!
    endsubroutine Qintrinsic
!***********************************************************************
    subroutine Qperiodic_ray
!
!  calculate boundary intensities for rays parallel to a coordinate
!  axis with periodic boundary conditions
!
!  11-jul-03/tobi: coded
!
      use Cdata
      use Mpicomm
!
      real, dimension(mx,mz) :: Qrad0_zx
      real, dimension(nx,nz) :: tau0_zx,emtau01_zx
      real, dimension(mx,my) :: Qrad0_xy
      real, dimension(nx,ny) :: tau0_xy,emtau01_xy
!
!  y-direction
!
      if (bc_rad1(2)=='p'.and.bc_rad2(2)=='p'.and.lrad==0.and.nrad==0.and.nprocy>1) then
!
        if (mrad>0) then
          if (ipy==0) then
            Qrad0_zx=0
            tau0_zx=0
          else
            call radboundary_zx_recv(mrad,idir,Qrad0_zx,tau0_zx)
          endif
          tau0_zx=tau0_zx+tau(l1:l2,m2,n1:n2)
          Qrad0_zx=Qrad0_zx*exp(-tau(:,m2,:))+Qrad(:,m2,:)
          if (ipy/=nprocy-1) then
            call radboundary_zx_send(mrad,idir,Qrad0_zx,tau0_zx)
          else
            where (tau0_zx>dtau_thresh)
              emtau01_zx=1-exp(-tau0_zx)
            elsewhere
              emtau01_zx=tau0_zx-tau0_zx**2/2+tau0_zx**3/6
            endwhere
            Qrad0_zx(l1:l2,n1:n2)=Qrad0_zx(l1:l2,n1:n2)/emtau01_zx
            call radboundary_zx_send(mrad,idir,Qrad0_zx)
          endif 
        endif
!
        if (mrad<0) then
          if (ipy==nprocy-1) then
            Qrad0_zx=0
            tau0_zx=0
          else
            call radboundary_zx_recv(mrad,idir,Qrad0_zx,tau0_zx)
          endif
          tau0_zx=tau0_zx+tau(l1:l2,m1,n1:n2)
          Qrad0_zx=Qrad0_zx*exp(-tau(:,m1,:))+Qrad(:,m1,:)
          if (ipy/=0) then
            call radboundary_zx_send(mrad,idir,Qrad0_zx,tau0_zx)
          else
            where (tau0_zx>dtau_thresh)
              emtau01_zx=1-exp(-tau0_zx)
            elsewhere
              emtau01_zx=tau0_zx-tau0_zx**2/2+tau0_zx**3/6
            endwhere
            Qrad0_zx(l1:l2,n1:n2)=Qrad0_zx(l1:l2,n1:n2)/emtau01_zx
            call radboundary_zx_send(mrad,idir,Qrad0_zx)
          endif 
        endif
!
      endif
!
!  z-direction
!
      if (bc_rad1(3)=='p'.and.bc_rad2(3)=='p'.and.lrad==0.and.mrad==0.and.nprocz>1) then
!
        if (nrad>0) then
          if (ipz==0) then
            Qrad0_xy=0
            tau0_xy=0
          else
            call radboundary_xy_recv(nrad,idir,Qrad0_xy,tau0_xy)
          endif
          tau0_xy=tau0_xy+tau(l1:l2,m1:m2,n2)
          Qrad0_xy=Qrad0_xy*exp(-tau(:,:,n2))+Qrad(:,:,n2)
          if (ipz/=nprocz-1) then
            call radboundary_xy_send(nrad,idir,Qrad0_xy,tau0_xy)
          else
            where (tau0_xy>dtau_thresh)
              emtau01_xy=1-exp(-tau0_xy)
            elsewhere
              emtau01_xy=tau0_xy-tau0_xy**2/2+tau0_xy**3/6
            end where
            Qrad0_xy(l1:l2,m1:m2)=Qrad0_xy(l1:l2,m1:m2)/emtau01_xy
            call radboundary_xy_send(nrad,idir,Qrad0_xy)
          endif 
        endif
!
        if (nrad<0) then
          if (ipz==nprocz-1) then
            Qrad0_xy=0
            tau0_xy=0
          else
            call radboundary_xy_recv(nrad,idir,Qrad0_xy,tau0_xy)
          endif
          tau0_xy=tau0_xy+tau(l1:l2,m1:m2,n1)
          Qrad0_xy=Qrad0_xy*exp(-tau(:,:,n1))+Qrad(:,:,n1)
          if (ipz/=0) then
            call radboundary_xy_send(nrad,idir,Qrad0_xy,tau0_xy)
          else
            where (tau0_xy>dtau_thresh)
              emtau01_xy=1-exp(-tau0_xy)
            elsewhere
              emtau01_xy=tau0_xy-tau0_xy**2/2+tau0_xy**3/6
            end where
            Qrad0_xy(l1:l2,m1:m2)=Qrad0_xy(l1:l2,m1:m2)/emtau01_xy
            call radboundary_xy_send(nrad,idir,Qrad0_xy)
          endif 
        endif
!
      endif
!
    endsubroutine Qperiodic_ray
!***********************************************************************
    subroutine Qcommunicate
!
!  set boundary intensities or receive from neighboring processors
!
!  11-jul-03/tobi: coded
!
      use Mpicomm, only: ipy,nprocy,ipz,nprocz
      use Mpicomm, only: radboundary_zx_recv,radboundary_zx_send
      use Mpicomm, only: radboundary_xy_recv,radboundary_xy_send
!
      real, dimension(my,mz) :: Qrad0_yz
      real, dimension(mx,mz) :: Qrad0_zx
      real, dimension(mx,my) :: Qrad0_xy
      integer :: raysteps
      integer :: l,m,n
!
!  determine start and stop processors
!
      if (mrad>0) then; ipystart=0; ipystop=nprocy-1; endif
      if (mrad<0) then; ipystart=nprocy-1; ipystop=0; endif
      if (nrad>0) then; ipzstart=0; ipzstop=nprocz-1; endif
      if (nrad<0) then; ipzstart=nprocz-1; ipzstop=0; endif
!
!  set boundary values
!
      if (lrad/=0) then
        call radboundary_yz_set(Qrad0_yz)
        Qrad0(llstart-lrad,mmstart-mrad:mmstop:msign,nnstart-nrad:nnstop:nsign) &
    =Qrad0_yz(             mmstart-mrad:mmstop:msign,nnstart-nrad:nnstop:nsign)
      endif
!
      if (mrad/=0) then
        if (ipy==ipystart) call radboundary_zx_set(Qrad0_zx)
        if (ipy/=ipystart) call radboundary_zx_recv(mrad,idir,Qrad0_zx)
        Qrad0(llstart-lrad:llstop:lsign,mmstart-mrad,nnstart-nrad:nnstop:nsign) &
    =Qrad0_zx(llstart-lrad:llstop:lsign,             nnstart-nrad:nnstop:nsign)
      endif
!
      if (nrad/=0) then
        if (ipz==ipzstart) call radboundary_xy_set(Qrad0_xy)
        if (ipz/=ipzstart) call radboundary_xy_recv(nrad,idir,Qrad0_xy)
        Qrad0(llstart-lrad:llstop:lsign,mmstart-mrad:mmstop:msign,nnstart-nrad) &
    =Qrad0_xy(llstart-lrad:llstop:lsign,mmstart-mrad:mmstop:msign             )
      endif
!
!  propagate boundary values
!
      if (lrad/=0) then
        do m=mmstart,mmstop,msign
        do n=nnstart,nnstop,nsign
          raysteps=(llstop-llstart)/lrad
          if (mrad/=0) raysteps=min(raysteps,(mmstop-m)/mrad)
          if (nrad/=0) raysteps=min(raysteps,(nnstop-n)/nrad)
          Qrad0(llstart+lrad*raysteps,m+mrad*raysteps,n+nrad*raysteps) &
           =Qrad0(llstart-lrad,m-mrad,n-nrad)
        enddo
        enddo
      endif
!
      if (mrad/=0) then
        do n=nnstart,nnstop,nsign
        do l=llstart,llstop,lsign
          raysteps=(mmstop-mmstart)/mrad
          if (nrad/=0) raysteps=min(raysteps,(nnstop-n)/nrad)
          if (lrad/=0) raysteps=min(raysteps,(llstop-l)/lrad)
          Qrad0(l+lrad*raysteps,mmstart+mrad*raysteps,n+nrad*raysteps) &
           =Qrad0(l-lrad,mmstart-mrad,n-nrad)
        enddo
        enddo
      endif
!
      if (nrad/=0) then
        do l=llstart,llstop,lsign
        do m=mmstart,mmstop,msign
          raysteps=(nnstop-nnstart)/nrad
          if (lrad/=0) raysteps=min(raysteps,(llstop-l)/lrad)
          if (mrad/=0) raysteps=min(raysteps,(mmstop-m)/mrad)
          Qrad0(l+lrad*raysteps,m+mrad*raysteps,nnstart+nrad*raysteps) &
           =Qrad0(l-lrad,m-mrad,nnstart-nrad)
        enddo
        enddo
      endif
!
!  send boundary values
!
      if (mrad/=0.and.ipy/=ipystop) then
        Qrad0_zx(llstart-lrad:llstop:lsign,       nnstart-nrad:nnstop:nsign) &
          =Qrad0(llstart-lrad:llstop:lsign,mmstop,nnstart-nrad:nnstop:nsign) &
       *exp(-tau(llstart-lrad:llstop:lsign,mmstop,nnstart-nrad:nnstop:nsign)) &
           +Qrad(llstart-lrad:llstop:lsign,mmstop,nnstart-nrad:nnstop:nsign)
        call radboundary_zx_send(mrad,idir,Qrad0_zx)
      endif
!
      if (nrad/=0.and.ipz/=ipzstop) then
        Qrad0_xy(llstart-lrad:llstop:lsign,mmstart-mrad:mmstop:msign       ) &
          =Qrad0(llstart-lrad:llstop:lsign,mmstart-mrad:mmstop:msign,nnstop) &
       *exp(-tau(llstart-lrad:llstop:lsign,mmstart-mrad:mmstop:msign,nnstop)) &
           +Qrad(llstart-lrad:llstop:lsign,mmstart-mrad:mmstop:msign,nnstop)
        call radboundary_xy_send(nrad,idir,Qrad0_xy)
      endif
!
    endsubroutine Qcommunicate
!***********************************************************************
    subroutine Qrevision
!
!  This routine is called after the communication part
!  The true boundary intensities I0 are now known and
!  the correction term I0*exp(-tau) is added
!
!  16-jun-03/axel+tobi: coded
!
      use Cdata, only: ldebug,headt
!
      integer :: l,m,n
!
!  identifier
!
      if(ldebug.and.headt) print*,'Qrevision'
!
!  do the ray...
!
      do n=nnstart,nnstop,nsign
      do m=mmstart,mmstop,msign
      do l=llstart,llstop,lsign
          Qrad0(l,m,n)=Qrad0(l-lrad,m-mrad,n-nrad)
          Qrad(l,m,n)=Qrad(l,m,n)+Qrad0(l,m,n)*exp(-tau(l,m,n))
      enddo
      enddo
      enddo
!
    endsubroutine Qrevision
!***********************************************************************
    subroutine radboundary_yz_set(Qrad0_yz)
!
!  sets the physical boundary condition on yz plane
!
!   6-jul-03/axel: coded
!
      real, dimension(my,mz) :: Qrad0_yz
!
!--------------------
!  lower x-boundary
!--------------------
!
      if (lrad>0) then
!
! no incoming intensity
!
        if (bc_rad1(1)=='0') then
          Qrad0_yz=-Srad(l1-1,:,:)
        endif
!
! periodic boundary consition
!
        if (bc_rad1(1)=='p') then
          Qrad0_yz=Qrad(l2,:,:)
        endif
!
! set intensity equal to source function
!
        if (bc_rad1(1)=='S') then
          Qrad0_yz=0
        endif
!
      endif
!
!--------------------
!  upper x-boundary
!--------------------
!
      if (lrad<0) then
!
! no incoming intensity
!
        if (bc_rad2(1)=='0') then
          Qrad0_yz=-Srad(l2+1,:,:)
        endif
!
! periodic boundary consition (currently only implemented for
! rays parallel to an axis
!
        if (bc_rad2(1)=='p') then
          Qrad0_yz=Qrad(l1,:,:)
        endif
!
! set intensity equal to source function
!
        if (bc_rad2(1)=='S') then
          Qrad0_yz=0
        endif
!
      endif
!
    endsubroutine radboundary_yz_set
!***********************************************************************
    subroutine radboundary_zx_set(Qrad0_zx)
!
!  sets the physical boundary condition on zx plane
!
!   6-jul-03/axel: coded
!
      use Mpicomm, only: stop_it
!
      real, dimension(mx,mz) :: Qrad0_zx
!
!--------------------
!  lower y-boundary
!--------------------
!
      if (mrad>0) then
!
! no incoming intensity
!
        if (bc_rad1(2)=='0') then
          Qrad0_zx=-Srad(:,m1-1,:)
        endif
!
! periodic boundary consition (currently not implemented for
! multiple processors in the y-direction)
!
        if (bc_rad1(2)=='p') then
          if (nprocy>1) then
            call stop_it("radboundary_zx_set: periodic bc not implemented for nprocy>1")
          endif
          Qrad0_zx=Qrad(:,m2,:)
        endif
!
! set intensity equal to source function
!
        if (bc_rad1(2)=='S') then
          Qrad0_zx=0
        endif
!
      endif
!
!--------------------
!  upper y-boundary
!--------------------
!
      if (mrad<0) then
!
! no incoming intensity
!
        if (bc_rad2(2)=='0') then
          Qrad0_zx=-Srad(:,m2+1,:)
        endif
!
! periodic boundary consition (currently not implemented for
! multiple processors in the y-direction)
!
        if (bc_rad2(2)=='p') then
          if (nprocy>1) then
            call stop_it("radboundary_zx_set: periodic bc not implemented for nprocy>1")
          endif
          Qrad0_zx=Qrad(:,m1,:)
        endif
!
! set intensity equal to source function
!
        if (bc_rad2(2)=='S') then
          Qrad0_zx=0
        endif
!
      endif
!
    endsubroutine radboundary_zx_set
!***********************************************************************
    subroutine radboundary_xy_set(Qrad0_xy)
!
!  sets the physical boundary condition on xy plane
!
!   6-jul-03/axel: coded
!
      use Mpicomm, only: stop_it
!
      real, dimension(mx,my) :: Qrad0_xy
!
!--------------------
!  lower z-boundary
!--------------------
!
      if (nrad>0) then
!
!  no incoming intensity
!
        if (bc_rad1(3)=='0') then
          Qrad0_xy=-Srad(:,:,n1-1)
        endif
!
! periodic boundary consition (currently not implemented for
! multiple processors in the z-direction)
!
        if (bc_rad1(3)=='p') then
          if (nprocz>1) then
            call stop_it("radboundary_xy_set: periodic bc not implemented for nprocz>1")
          endif
          Qrad0_xy=Qrad(:,:,n2)
        endif
!
!  set intensity equal to source function
!
        if (bc_rad1(3)=='S') then
          Qrad0_xy=0
        endif
!
      endif
!
!--------------------
!  upper z-boundary
!--------------------
!
      if (nrad<0) then
!
! no incoming intensity
!
        if (bc_rad2(3)=='0') then
          Qrad0_xy=-Srad(:,:,n2+1)
        endif
!
! periodic boundary consition (currently not implemented for
! multiple processors in the z-direction)
!
        if (bc_rad2(3)=='p') then
          if (nprocz>1) then
            call stop_it("radboundary_xy_set: periodic bc not implemented for nprocz>1")
          endif
          Qrad0_xy=Qrad(:,:,n1)
        endif
!
! set intensity equal to source function
!
        if (bc_rad2(3)=='S') then
          Qrad0_xy=0
        endif
!
      endif
!
    endsubroutine radboundary_xy_set
!***********************************************************************
    subroutine radiative_cooling(f,df)
!
!  calculate source function
!
!  25-mar-03/axel+tobi: coded
!
      use Cdata
      use Sub
      use Ionization
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (mx,my,mz,mvar) :: df
      real, dimension (nx) :: lnrho,Qrad,lnTT,Qrad2
!
      lnrho=f(l1:l2,m,n,ilnrho)
      Qrad=f(l1:l2,m,n,iQrad)
      lnTT=f(l1:l2,m,n,ilnTT)
!
!  Add radiative cooling
!
      if(.not. nocooling) then
         df(l1:l2,m,n,iss)=df(l1:l2,m,n,iss) &
                           +4*pi*exp(lnchi(l1:l2,m,n)-lnTT-lnrho)*Qrad
      endif
!
!  diagnostics
!
      if(ldiagnos) then
         Qrad2=f(l1:l2,m,n,iQrad)**2
         if(i_Qradrms/=0) call sum_mn_name(Qrad2,i_Qradrms,lsqrt=.true.)
         if(i_Qradmax/=0) call max_mn_name(Qrad2,i_Qradmax,lsqrt=.true.)
      endif
!
    endsubroutine radiative_cooling
!***********************************************************************
    subroutine init_rad(f,xx,yy,zz)
!
!  Dummy routine for Flux Limited Diffusion routine
!  initialise radiation; called from start.f90
!
!  15-jul-2002/nils: dummy routine
!
      use Cdata
      use Sub
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (mx,my,mz)      :: xx,yy,zz
!
      if(ip==0) print*,f,xx,yy,zz !(keep compiler quiet)
    endsubroutine init_rad
!***********************************************************************
   subroutine de_dt(f,df,rho1,divu,uu,uij,TT1,gamma)
!
!  Dummy routine for Flux Limited Diffusion routine
!
!  15-jul-2002/nils: dummy routine
!
      use Cdata
      use Sub
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (mx,my,mz,mvar) :: df
      real, dimension (nx,3) :: uu
      real, dimension (nx) :: rho1,TT1
      real, dimension (nx,3,3) :: uij
      real, dimension (nx) :: divu
      real :: gamma
!
      if(ip==0) print*,f,df,rho1,divu,uu,uij,TT1,gamma !(keep compiler quiet)
    endsubroutine de_dt
!*******************************************************************
    subroutine rprint_radiation(lreset,lwrite)
!
!  Dummy routine for Flux Limited Diffusion routine
!  reads and registers print parameters relevant for radiative part
!
!  16-jul-02/nils: adapted from rprint_hydro
!
      use Cdata
      use Sub
!  
      integer :: iname
      logical :: lreset,lwr
      logical, optional :: lwrite
!
      lwr = .false.
      if (present(lwrite)) lwr=lwrite
!
!  reset everything in case of RELOAD
!  (this needs to be consistent with what is defined above!)
!
      if (lreset) then
        i_Qradrms=0; i_Qradmax=0
      endif
!
!  check for those quantities that we want to evaluate online
!
      do iname=1,nname
        call parse_name(iname,cname(iname),cform(iname),'Qradrms',i_Qradrms)
        call parse_name(iname,cname(iname),cform(iname),'Qradmax',i_Qradmax)
      enddo
!
!  write column where which radiative variable is stored
!
      if (lwr) then
        write(3,*) 'i_frms=',i_frms
        write(3,*) 'i_fmax=',i_fmax
        write(3,*) 'i_Erad_rms=',i_Erad_rms
        write(3,*) 'i_Erad_max=',i_Erad_max
        write(3,*) 'i_Egas_rms=',i_Egas_rms
        write(3,*) 'i_Egas_max=',i_Egas_max
        write(3,*) 'i_Qradrms=',i_Qradrms
        write(3,*) 'i_Qradmax=',i_Qradmax
        write(3,*) 'nname=',nname
        write(3,*) 'ie=',ie
        write(3,*) 'ifx=',ifx
        write(3,*) 'ify=',ify
        write(3,*) 'ifz=',ifz
        write(3,*) 'iQrad=',iQrad
      endif
!   
      if(ip==0) print*,lreset  !(to keep compiler quiet)
    endsubroutine rprint_radiation
!***********************************************************************
    subroutine  bc_ee_inflow_x(f,topbot)
!
!  Dummy routine for Flux Limited Diffusion routine
!
!  8-aug-02/nils: coded
!
      character (len=3) :: topbot
      real, dimension (mx,my,mz,mvar+maux) :: f
!
      if (ip==1) print*,topbot,f(1,1,1,1)  !(to keep compiler quiet)
!
    end subroutine bc_ee_inflow_x
!***********************************************************************
    subroutine  bc_ee_outflow_x(f,topbot)
!
!  Dummy routine for Flux Limited Diffusion routine
!
!  8-aug-02/nils: coded
!
      character (len=3) :: topbot
      real, dimension (mx,my,mz,mvar+maux) :: f
!
      if (ip==1) print*,topbot,f(1,1,1,1)  !(to keep compiler quiet)
!
    end subroutine bc_ee_outflow_x
!***********************************************************************

endmodule Radiation
