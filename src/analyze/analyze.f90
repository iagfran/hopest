#include "hopest_f.h"

MODULE MODH_Analyze
!===================================================================================================================================
! Add comments please!
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
PRIVATE
!-----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES 
!-----------------------------------------------------------------------------------------------------------------------------------
! Private Part ---------------------------------------------------------------------------------------------------------------------
! Public Part ----------------------------------------------------------------------------------------------------------------------
INTERFACE InitAnalyze
  MODULE PROCEDURE InitAnalyze
END INTERFACE

INTERFACE Analyze
  MODULE PROCEDURE Analyze
END INTERFACE

PUBLIC::InitAnalyze
PUBLIC::Analyze
!===================================================================================================================================

CONTAINS

SUBROUTINE InitAnalyze()
!===================================================================================================================================
! Basic Analyze initialization. 
!===================================================================================================================================
! MODULES
USE MODH_Mesh_Vars,ONLY:Ngeo_out,XiCL_Ngeo_out,wBaryCL_NGeo_out
USE MODH_Analyze_Vars
USE MODH_ReadInTools,ONLY:GETINT,GETLOGICAL
USE MODH_Basis,    ONLY: BarycentricWeights,InitializeVandermonde,PolynomialDerivativeMatrix
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
CHARACTER(LEN=5)           :: tmpstr
INTEGER                    :: i
REAL,ALLOCATABLE           :: xi(:)
!===================================================================================================================================

checkJacobian=GETLOGICAL('checkJacobian','T')
doDebugVisu=GETLOGICAL('doDebugVisu','F')

WRITE(tmpstr,'(I5)')FLOOR(1.5*Ngeo_out)
Nanalyze=GETINT('Nanalyze',tmpstr)

ALLOCATE(xi(0:Nanalyze))
DO i=0,Nanalyze
  xi(i)=-1.+2*REAL(i)/REAL(Nanalyze)
END DO
ALLOCATE(Vdm_analyze(0:Nanalyze,0:Ngeo_out))
CALL InitializeVandermonde(Ngeo_out,Nanalyze,wBaryCL_Ngeo_out,xiCL_Ngeo_out,xi,Vdm_analyze)

ALLOCATE(D_Ngeo_out(0:Ngeo_out,0:Ngeo_out))

CALL PolynomialDerivativeMatrix(Ngeo_out,xiCL_Ngeo_out,D_Ngeo_out)

END SUBROUTINE InitAnalyze


SUBROUTINE Analyze()
!===================================================================================================================================
! Basic Analyze initialization. 
!===================================================================================================================================
! MODULES
USE MODH_Analyze_Vars,ONLY:checkJacobian,doDebugVisu
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
!===================================================================================================================================
IF(CheckJacobian) CALL CheckJac()
IF(doDebugVisu)   CALL DebugVisu()
  
END SUBROUTINE Analyze


SUBROUTINE DebugVisu()
!===================================================================================================================================
! Basic Analyze initialization. 
!===================================================================================================================================
! MODULES
USE MODH_Globals
USE MODH_Globals
USE MODH_Mesh_Vars,   ONLY: NGeo_out,nElems,blending_glob,xGeoElem
USE MODH_Mesh_Vars,   ONLY: xi0Elem
USE MODH_Mesh_Vars,   ONLY: xiCL_Ngeo_out,wBaryCL_Ngeo_out
USE MODH_Mesh_Vars,   ONLY: doSplineInterpolation
USE MODH_Spline1D,    ONLY: GetSplineVandermonde
USE MODH_P4EST_Vars,  ONLY: QuadLevel
USE MODH_Basis,       ONLY: LagrangeInterpolationPolys
USE MODH_ChangeBasis, ONLY: ChangeBasis3D_XYZ 
USE MODH_Output_Vars, ONLY: Projectname
USE MODH_Tecplot     ,ONLY: WriteDataToTecplotBinary3D
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
CHARACTER(LEN=255)                    :: VarNames(1)
INTEGER                               :: iElem,i
REAL                                  :: length,dxi
REAL,DIMENSION(0:Ngeo_out,0:NGeo_out) :: Vdm_xi,Vdm_eta,Vdm_zeta
REAL                                  :: XGeo_visu(3,0:NGeo_out,0:NGeo_out,0:Ngeo_out,nElems)
!===================================================================================================================================

WRITE(Unit_StdOut,'(A,A)') ' Writing Debugmesh to Tecplot: ',TRIM(ProjectName)//'_p4est_Debugmesh.plt'
DO iElem=1,nElems
  ! interpolate the HO volume mapping from tree level+Ngeo to quad level+Ngeo_out
  ! length of each quadrant in integers
  length=2./REAL(2**QuadLevel(iElem))
  ! Build Vandermonde matrices for each parameter range in xi, eta,zeta
  DO i=0,Ngeo_out
    dxi=0.5*(xiCL_Ngeo_out(i)+1.)*Length
    CALL LagrangeInterpolationPolys(xi0Elem(1,iElem) + dxi,Ngeo_out,xiCL_Ngeo_out,wBaryCL_Ngeo_out,Vdm_xi(i,:)) 
    CALL LagrangeInterpolationPolys(xi0Elem(2,iElem) + dxi,Ngeo_out,xiCL_Ngeo_out,wBaryCL_Ngeo_out,Vdm_eta(i,:)) 
    CALL LagrangeInterpolationPolys(xi0Elem(3,iElem) + dxi,Ngeo_out,xiCL_Ngeo_out,wBaryCL_Ngeo_out,Vdm_zeta(i,:)) 
  END DO
  !interpolate tree HO mapping on quadrant at Ngeo_out
  CALL ChangeBasis3D_XYZ(3,Ngeo_out,Ngeo_out,Vdm_xi,Vdm_eta,Vdm_zeta,XGeoElem(:,:,:,:,iElem),xGeo_visu(:,:,:,:,iElem))
END DO!iElem

VarNames(1)='blending'
CALL WriteDataToTecplotBinary3D(Ngeo_out,nElems,1,VarNames,blending_glob,TRIM(ProjectName)//'_p4est_Debugmesh.plt',0.,xGeo_visu)

END SUBROUTINE DebugVisu



SUBROUTINE CheckJac()
!===================================================================================================================================
! Basic Analyze initialization. 
!===================================================================================================================================
! MODULES
USE MODH_Globals
USE MODH_Mesh_Vars,   ONLY:Ngeo_out,XgeoElem
USE MODH_Mesh_Vars,   ONLY:nElems
USE MODH_Analyze_Vars,ONLY:Nanalyze,Vdm_analyze,D_Ngeo_out
USE MODH_ChangeBasis, ONLY:ChangeBasis3D
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
INTEGER                                            :: i,j,k,l,iElem
REAL                                               :: scaledJacTol,Xbary(3)
REAL                                               :: scaledJac(nElems),minJac,maxJac
INTEGER                                            :: scaledJacStat(0:10)
REAL,DIMENSION(3,3,0:Ngeo_out,0:Ngeo_out,0:Ngeo_out) :: dX
REAL,DIMENSION(3,3,0:Nanalyze,0:Nanalyze,0:Nanalyze) :: dXa
REAL,DIMENSION(0:Nanalyze,0:Nanalyze,0:Nanalyze)   :: detJac
!===================================================================================================================================
SWRITE(UNIT_stdOut,'   (A)') "Checking Jacobians..."
DO iElem=1,nElems
  dX=0.
  DO k=0,Ngeo_out
    DO j=0,Ngeo_out
      DO i=0,Ngeo_out
      ! Matrix-vector multiplication
        DO l=0,Ngeo_out
          dX(1,:,i,j,k)=dX(1,:,i,j,k) + D_Ngeo_out(i,l)*XgeoElem(:,l,j,k,iElem)
          dX(2,:,i,j,k)=dX(2,:,i,j,k) + D_Ngeo_out(j,l)*XgeoElem(:,i,l,k,iElem)
          dX(3,:,i,j,k)=dX(3,:,i,j,k) + D_Ngeo_out(k,l)*XgeoElem(:,i,j,l,iElem)
        END DO !l=0,Ngeo_out
      END DO !i=0,Ngeo_out
    END DO !j=0,Ngeo_out
  END DO !k=0,Ngeo_out
  CALL ChangeBasis3D(3,NGeo_out,Nanalyze,Vdm_analyze,dX(1,:,:,:,:),dXa(1,:,:,:,:))
  CALL ChangeBasis3D(3,NGeo_out,Nanalyze,Vdm_analyze,dX(2,:,:,:,:),dXa(2,:,:,:,:))
  CALL ChangeBasis3D(3,NGeo_out,Nanalyze,Vdm_analyze,dX(3,:,:,:,:),dXa(3,:,:,:,:))
  DO k=0,Nanalyze
    DO j=0,Nanalyze
      DO i=0,Nanalyze
        detJac(i,j,k)= dXa(1,1,i,j,k)*(dXa(2,2,i,j,k)*dXa(3,3,i,j,k) - dXa(3,2,i,j,k)*dXa(2,3,i,j,k)) + &
                       dXa(2,1,i,j,k)*(dXa(3,2,i,j,k)*dXa(1,3,i,j,k) - dXa(1,2,i,j,k)*dXa(3,3,i,j,k)) + &
                       dXa(3,1,i,j,k)*(dXa(1,2,i,j,k)*dXa(2,3,i,j,k) - dXa(2,2,i,j,k)*dXa(1,3,i,j,k))
      END DO !i
    END DO !j
  END DO !k
  maxJac=MAXVAL(ABS(detJac))
  minJac=MINVAL(detJac)
  scaledJac(iElem)=minJac/maxJac
END DO !iElem

! Error Section
scaledJacTol=1e-1!1.0E-6

IF(ANY(scaledJac.LE.scaledJacTol))THEN
  OPEN(UNIT=100,FILE='Jacobian_Error.dat',STATUS='UNKNOWN',ACTION='WRITE')
  WRITE(100,*) 'TITLE="Corrupt Elems Found, i.e. the Jacobian is negative" '
  WRITE(100,*)
  WRITE(100,'(A)')'VARIABLES="xBary","yBary","zBary","scaledJac"'
  WRITE(100,*)
  DO iElem=1,nElems
    IF(scaledJac(iElem).LT.scaledJactol) THEN
      XBary(1)=SUM(XgeoElem(1,:,:,:,iElem))
      XBary(2)=SUM(XgeoElem(2,:,:,:,iElem))
      XBary(3)=SUM(XgeoElem(3,:,:,:,iElem))
      XBary=XBary/REAL((Ngeo_out+1)**3)
      WRITE(100,'(4(4X,E12.5))') Xbary,scaledJac(iElem)
    END IF
  END DO !iQaud
  CLOSE(UNIT=100)
  WRITE(*,*) '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
  WRITE(*,*) '!!! WARNING! Elements with negative Jacobian found, see Jacobian_Error.dat for details.'
  WRITE(*,*) '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
END IF
scaledJacStat(:)=0

DO iElem=1,nElems
  i=CEILING(MAX(0.,scaledJac(iElem)*10))
  scaledJacStat(i)=scaledJacStat(i)+1 
END DO
WRITE(Unit_StdOut,'(A)') ' Number of element with scaled Jacobians ranging between:'
WRITE(Unit_StdOut,'(A)') '   <  0.0  <  0.1  <  0.2  <  0.3  <  0.4  <  0.5  <  0.6  <  0.7  <  0.8  <  0.9  <  1.0 '
DO i=0,10
  WRITE(Unit_StdOut,'(I6,X,A1)',ADVANCE='NO')scaledJacStat(i),'|'
END DO
WRITE(Unit_StdOut,'(A1)')' '
END SUBROUTINE CheckJac

END MODULE MODH_Analyze
