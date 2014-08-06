#include "hopest_f.h"

MODULE MOD_Refine
!===================================================================================================================================
! Add comments please!
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! Private Part ---------------------------------------------------------------------------------------------------------------------

! Public Part ----------------------------------------------------------------------------------------------------------------------
INTERFACE RefineMesh
  MODULE PROCEDURE RefineMesh
END INTERFACE

PUBLIC::RefineMesh
!===================================================================================================================================

CONTAINS


SUBROUTINE RefineMesh()
!===================================================================================================================================
! Subroutine to read the mesh from a mesh data file
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Refine_Vars
USE MOD_Refine_Binding,ONLY: p4_refine_mesh
USE MOD_Mesh_Vars,     ONLY: nElems
USE MOD_P4EST_Vars,    ONLY: p4est,mesh
USE MOD_Readintools,   ONLY: GETINT
USE, INTRINSIC :: ISO_C_BINDING
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
TYPE(C_FUNPTR)              :: refineFunc
!===================================================================================================================================
SWRITE(UNIT_stdOut,'(A)')'BUILD P4EST MESH AND REFINE ...'
SWRITE(UNIT_StdOut,'(132("-"))')

refineLevel=GETINT('refineLevel','1')
refineType =GETINT('refineType','1') ! default conform refinement

ALLOCATE(RefineList(nElems))
RefineList=0

! Transform input mesh to adapted mesh
! Do refinement and save p4est refine
SELECT CASE(refineType)
CASE(1)  ! conform refinement of the whole mesh
  refineFunc=C_FUNLOC(RefineAll)
CASE(2)  ! Boundary Element refinement
  refineBCIndex=GETINT('refineBCIndex','1')
  CALL InitRefineBoundaryElems()
  refineFunc=C_FUNLOC(RefineByList)
CASE(3)
  CALL InitRefineGeom()
  refineFunc=C_FUNLOC(RefineByGeom)
CASE(11)
  refineFunc=C_FUNLOC(RefineFirst)
CASE DEFAULT
  STOP 'refineType is not defined'
END SELECT

CALL p4_refine_mesh(p4est,refineFunc,refineLevel,& !IN
                    mesh)                          !OUT
SDEALLOCATE(RefineList)
END SUBROUTINE RefineMesh


SUBROUTINE InitRefineBoundaryElems()
!===================================================================================================================================
! init the refinment list
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Refine_Vars, ONLY: TreeToQuadRefine,refineBCIndex
USE MOD_Mesh_Vars,  ONLY: Elems,nElems
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                     :: iElem,iSide
!===================================================================================================================================
! These are the refinement functions which are called by p4est
ALLOCATE(TreeToQuadRefine(1:8,1:nElems))
TreeToQuadRefine=0
DO iElem=1,nElems
  DO iSide=1,6
    IF (Elems(iElem)%ep%Side(iSide)%sp%BCIndex.EQ.refineBCIndex) THEN
      SELECT CASE (iSide)
        CASE (1) 
          TreeToQuadRefine(1:4,iElem)=1
        CASE (2) 
          TreeToQuadRefine(1,iElem)=1
          TreeToQuadRefine(2,iElem)=1
          TreeToQuadRefine(5,iElem)=1
          TreeToQuadRefine(6,iElem)=1
        CASE (3) 
          TreeToQuadRefine(2,iElem)=1
          TreeToQuadRefine(4,iElem)=1
          TreeToQuadRefine(6,iElem)=1
          TreeToQuadRefine(8,iElem)=1
        CASE (4) 
          TreeToQuadRefine(3,iElem)=1
          TreeToQuadRefine(4,iElem)=1
          TreeToQuadRefine(7,iElem)=1
          TreeToQuadRefine(8,iElem)=1
        CASE (5) 
          TreeToQuadRefine(1,iElem)=1
          TreeToQuadRefine(3,iElem)=1
          TreeToQuadRefine(5,iElem)=1
          TreeToQuadRefine(7,iElem)=1
        CASE (6) 
          TreeToQuadRefine(5:8,iElem)=1
      END SELECT
    END IF
  END DO
END DO

END SUBROUTINE InitRefineBoundaryElems


SUBROUTINE InitRefineGeom()
!===================================================================================================================================
! init the geometric refinment
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Refine_Vars, ONLY: refineGeomType,sphereCenter,sphereRadius,boxBoundary 
USE MOD_Readintools,ONLY:GETREALARRAY,GETINT,GETREAL
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                     :: iElem
REAL                     :: XBary(3)
!===================================================================================================================================
! These are the refinement functions which are called by p4est
refineGeomType =GETINT('refineGeomType') ! 
SELECT CASE(refineGeomType)
  CASE(1) ! Sphere
    sphereCenter =GETREALARRAY('sphereCenter',3)
    sphereRadius =GETREAL('sphereRadius')
  CASE(2) ! Box 
    boxBoundary=GETREALARRAY('boxBoundary',6)
  CASE DEFAULT
    STOP 'no refineGeomType defined'
END SELECT

END SUBROUTINE InitRefineGeom

FUNCTION RefineAll(x,y,z,tree,level) BIND(C)
!===================================================================================================================================
! Subroutine to refine the the mesh
!===================================================================================================================================
! MODULES
USE, INTRINSIC :: ISO_C_BINDING
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER(KIND=C_INT32_T),INTENT(IN),VALUE :: x,y,z
INTEGER(KIND=C_INT32_T),INTENT(IN),VALUE :: tree
INTEGER(KIND=C_INT8_T ),INTENT(IN),VALUE :: level
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
INTEGER(KIND=C_INT) :: refineAll
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
refineAll=1
END FUNCTION RefineAll

FUNCTION RefineByList(x,y,z,tree,level,childID) BIND(C)
!===================================================================================================================================
! Subroutine to refine the the mesh
!===================================================================================================================================
! MODULES
USE, INTRINSIC :: ISO_C_BINDING
USE MOD_Refine_Vars, ONLY: TreeToQuadRefine
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER(KIND=C_INT32_T),INTENT(IN),VALUE :: x,y,z
INTEGER(KIND=C_INT32_T),INTENT(IN),VALUE :: tree
INTEGER(KIND=C_INT8_T ),INTENT(IN),VALUE :: level
INTEGER(KIND=C_INT ),INTENT(IN),VALUE :: childID
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
INTEGER(KIND=C_INT)                      :: refineByList
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
IF (level.EQ.0) RefineByList=SUM(TreeToQuadRefine(:,tree))
IF (level.GE.1) RefineByList=TreeToQuadRefine(childID+1,tree)
END FUNCTION RefineByList


FUNCTION RefineByGeom(x,y,z,tree,level,childID) BIND(C)
!===================================================================================================================================
! Subroutine to refine the the mesh
!===================================================================================================================================
! MODULES
USE, INTRINSIC :: ISO_C_BINDING
USE MOD_Refine_Vars, ONLY: RefineList,refineBoundary,refineGeomType
USE MOD_Refine_Vars, ONLY: sphereCenter,sphereRadius,boxBoundary
USE MOD_Mesh_Vars,   ONLY: XGeo,Ngeo
USE MOD_Mesh_Vars,   ONLY: wBary_Ngeo,xi_Ngeo
USE MOD_P4EST_Vars,  ONLY: Quadcoords 
USE MOD_Basis,       ONLY: LagrangeInterpolationPolys 
USE MOD_ChangeBasis, ONLY: ChangeBasis3D_XYZ
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER(KIND=C_INT32_T),INTENT(IN),VALUE :: x,y,z
INTEGER(KIND=C_INT32_T),INTENT(IN),VALUE :: tree
INTEGER(KIND=C_INT8_T ),INTENT(IN),VALUE :: level
INTEGER(KIND=C_INT ),INTENT(IN),VALUE    :: childID
REAL                                     :: xi0(3)
REAL                                     :: xiBary(3)
REAL                                     :: dxi,length
REAL,DIMENSION(0:Ngeo,0:Ngeo)            :: Vdm_xi,Vdm_eta,Vdm_zeta
REAL                                     :: XQuadCoord(3),ElemLength(3),ElemFirstCorner(3),VectorToBaryQuad(3)
REAL                                     :: XCorner(3), XBaryQuad(3),lengthQuad,test,IntSize,sIntSize
REAL                                     :: XGeoQuad(3,0:NGeo,0:NGeo,0:NGeo)
REAL                                     :: l_xi(0:NGeo),l_eta(0:NGeo),l_zeta(0:NGeo),l_etazeta
INTEGER                                  :: i,j,k
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
INTEGER(KIND=C_INT) :: refineByGeom
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
refineByGeom = 0

IntSize=2.**19 !TODO: use sIntSize from mesh_vars. not initialized at this stage yet
sIntSize=1./IntSize

! transform p4est first corner coordinates (integer from 0... intsize) to [-1,1] reference element of its tree
xi0(1)=-1.+2.*REAL(x)*sIntSize
xi0(2)=-1.+2.*REAL(y)*sIntSize
xi0(3)=-1.+2.*REAL(z)*sIntSize
! length of the quadrant in reference coordinates of its tree [-1,1]
length=2./REAL(2**level)
! Build Vandermonde matrices for each parameter range in xi, eta,zeta
DO i=0,Ngeo
  dxi=0.5*(xi_Ngeo(i)+1.)*Length
  CALL LagrangeInterpolationPolys(xi0(1) + dxi,Ngeo,xi_Ngeo,wBary_Ngeo,Vdm_xi(i,:)) 
  CALL LagrangeInterpolationPolys(xi0(2) + dxi,Ngeo,xi_Ngeo,wBary_Ngeo,Vdm_eta(i,:)) 
  CALL LagrangeInterpolationPolys(xi0(3) + dxi,Ngeo,xi_Ngeo,wBary_Ngeo,Vdm_zeta(i,:)) 
END DO
!interpolate tree HO mapping to quadrant HO mapping
CALL ChangeBasis3D_XYZ(3,Ngeo,Ngeo,Vdm_xi,Vdm_eta,Vdm_zeta,XGeo(:,:,:,:,tree),XgeoQuad(:,:,:,:))


! Barycenter
xiBary(:)=0.
! Build Vandermonde matrices for each parameter range in xi, eta,zeta
CALL LagrangeInterpolationPolys(xiBary(1),Ngeo,xi_Ngeo,wBary_Ngeo,l_xi(:)) 
CALL LagrangeInterpolationPolys(xiBary(2),Ngeo,xi_Ngeo,wBary_Ngeo,l_eta(:)) 
CALL LagrangeInterpolationPolys(xiBary(3),Ngeo,xi_Ngeo,wBary_Ngeo,l_zeta(:)) 
!interpolate tree HO mapping to quadrant HO mapping
XBaryQuad(:)=0.
  DO k=0,NGeo
    DO j=0,NGeo
      l_etazeta=l_eta(j)*l_zeta(k)
      DO i=0,NGeo
        XBaryQuad(:)=XBaryQuad(:)+XgeoQuad(:,i,j,k)*l_xi(i)*l_etazeta
      END DO
    END DO
  END DO
SELECT CASE (refineGeomType)
CASE(1)   ! SPHERE
  ! check corner nodes
  DO k=0,1
    DO j=0,1
      DO i=0,1
        XCorner(:)=XgeoQuad(:,i*NGeo,j*NGeo,k*NGeo)
        test=SQRT((XCorner(1)-sphereCenter(1))**2+(XCorner(2)-sphereCenter(2))**2+(XCorner(3)-sphereCenter(3))**2)
        IF (test.LE.sphereRadius) THEN
          refineByGeom = 1
          RETURN
        END IF
      END DO ! i
    END DO ! j 
  END DO ! k
  ! check barycenter
  test=SQRT((XBaryQuad(1)-sphereCenter(1))**2+(XBaryQuad(2)-sphereCenter(2))**2+(XBaryQuad(3)-sphereCenter(3))**2)
  IF (test.LE.sphereRadius) THEN
    refineByGeom = 1
  ELSE
    refineByGeom = 0
  END IF
  
CASE(2)   ! BOX
  ! check corner nodes
  DO k=0,1
    DO j=0,1
      DO i=0,1
        XCorner(:)=XgeoQuad(:,i*NGeo,j*NGeo,k*NGeo)
        IF (XCorner(1) .GE. boxBoundary(1) .AND. XCorner(1) .LE. boxBoundary(2) .AND. & 
            XCorner(2) .GE. boxBoundary(3) .AND. XCorner(2) .LE. boxBoundary(4) .AND. &
            XCorner(3) .GE. boxBoundary(5) .AND. XCorner(3) .LE. boxBoundary(6)) THEN
          refineByGeom = 1
          RETURN
        END IF
      END DO ! i
    END DO ! j 
  END DO ! k
  ! refineBoundary(xmin,xmax,ymin,ymax,zmin,zmax)
  IF (XBaryQuad(1) .GE. boxBoundary(1) .AND. XBaryQuad(1) .LE. boxBoundary(2) .AND. & 
      XBaryQuad(2) .GE. boxBoundary(3) .AND. XBaryQuad(2) .LE. boxBoundary(4) .AND. &
      XBaryQuad(3) .GE. boxBoundary(5) .AND. XBaryQuad(3) .LE. boxBoundary(6)) THEN
    refineByGeom = 1
  END IF
END SELECT
END FUNCTION RefineByGeom


FUNCTION RefineFirst(x,y,z,tree,level) BIND(C)
!===================================================================================================================================
! Subroutine to refine the the mesh
!===================================================================================================================================
! MODULES
USE, INTRINSIC :: ISO_C_BINDING
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER(KIND=C_INT32_T),INTENT(IN),VALUE :: x,y,z
INTEGER(KIND=C_INT32_T),INTENT(IN),VALUE :: tree
INTEGER(KIND=C_INT8_T ),INTENT(IN),VALUE :: level
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
INTEGER(KIND=C_INT)                      :: refineFirst
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
IF(tree.EQ.1)THEN
  refineFirst=1
ELSE
  refineFirst=0
END IF
END FUNCTION RefineFirst

END MODULE MOD_Refine