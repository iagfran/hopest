#include "hopest_f.h"

MODULE MOD_Mesh
!===================================================================================================================================
! Contains subroutines to build (curviilinear) meshes and provide metrics, etc.
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
PRIVATE
!-----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES (PUBLIC)
!-----------------------------------------------------------------------------------------------------------------------------------
! Public Part ----------------------------------------------------------------------------------------------------------------------

INTERFACE InitMesh
  MODULE PROCEDURE InitMesh
END INTERFACE

INTERFACE FinalizeMesh
  MODULE PROCEDURE FinalizeMesh
END INTERFACE

PUBLIC::InitMesh
PUBLIC::FinalizeMesh
!===================================================================================================================================

CONTAINS

SUBROUTINE InitMesh()
!===================================================================================================================================
! Read Parameter from inputfile 
!===================================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Mesh_Vars
USE MOD_Output_Vars, ONLY:Projectname
!-----------------------------------------------------------------------------------------------------------------------------------
USE MOD_Mesh_ReadIn,        ONLY:readMesh
USE MOD_MeshFromP4EST,      ONLY:BuildMeshFromP4EST
USE MOD_Output_HDF5,        ONLY:writeMeshToHDF5
USE MOD_ReadInTools,        ONLY:GETINT,GETSTR
IMPLICIT NONE
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
!===================================================================================================================================
IF(MeshInitIsDone)&
  CALL abort(__STAMP__,&
  'InitMesh not ready to be called or already called.')

SWRITE(UNIT_StdOut,'(132("-"))')
SWRITE(UNIT_stdOut,'(A)') ' INIT MESH...'

! prepare pointer structure (get nElems, etc.)
MeshFile = GETSTR('MeshFile')
ProjectName=Meshfile(1:INDEX(Meshfile,'_mesh.h5')-1)
CALL readMesh(MeshFile) !set nElems

refineLevel=GETINT('refineLevel','2')
refineElem =GETINT('refineElem','-1')   ! -1 all, >0 specific element

CALL BuildMeshFromP4EST()

!output new mesh
CALL writeMeshToHDF5(TRIM(ProjectName)//'_mesh_p4est.h5')
! dealloacte pointers
SWRITE(UNIT_stdOut,'(A)') "NOW CALLING deleteMeshPointer..."
CALL deleteMeshPointer()

!IF(GETLOGICAL('debugmesh','.FALSE.')) CALL WriteDebugMesh()

MeshInitIsDone=.TRUE.
SWRITE(UNIT_stdOut,'(A)')' INIT MESH DONE!'
SWRITE(UNIT_StdOut,'(132("-"))')
END SUBROUTINE InitMesh


SUBROUTINE FinalizeMesh()
!============================================================================================================================
! Deallocate all global interpolation variables.
!============================================================================================================================
! MODULES
USE MOD_Globals
USE MOD_Mesh_Vars
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------
!input parameters
!----------------------------------------------------------------------------------------------------------------------------
!output parameters
!----------------------------------------------------------------------------------------------------------------------------
!local variables
!============================================================================================================================
! Deallocate global variables, needs to go somewhere else later
SDEALLOCATE(Xi_NGeo)
SDEALLOCATE(BoundaryName)
SDEALLOCATE(BoundaryType)
MeshInitIsDone = .FALSE.
END SUBROUTINE FinalizeMesh

END MODULE MOD_Mesh
