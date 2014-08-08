#include "hopest_f.h"

MODULE MODH_Output
!===================================================================================================================================
! Add comments please!
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
!-----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES 
!-----------------------------------------------------------------------------------------------------------------------------------
! Private Part ---------------------------------------------------------------------------------------------------------------------
! Public Part ----------------------------------------------------------------------------------------------------------------------

INTERFACE InitOutput
  MODULE PROCEDURE InitOutput
END INTERFACE

INTERFACE FinalizeOutput
  MODULE PROCEDURE FinalizeOutput
END INTERFACE

PUBLIC:: InitOutput,FinalizeOutput
!===================================================================================================================================

CONTAINS

SUBROUTINE InitOutput()
!===================================================================================================================================
! Initialize all output (and analyze) variables.
!===================================================================================================================================
! MODULES
USE MODH_Globals
USE MODH_Preproc
USE MODH_Output_Vars
USE MODH_ReadInTools       ,ONLY:GETSTR,GETLOGICAL,GETINT
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                        :: OpenStat
CHARACTER(LEN=8)               :: StrDate
CHARACTER(LEN=10)              :: StrTime
CHARACTER(LEN=255)             :: LogFile
!===================================================================================================================================
IF(OutputInitIsDone)THEN
  CALL abort(__STAMP__,&
       'InitOutput not ready to be called or already called.')
END IF
SWRITE(UNIT_StdOut,'(132("-"))')
SWRITE(UNIT_stdOut,'(A)') ' INIT OUTPUT...'

! Name for all output files
ProjectName=GETSTR('ProjectName')

OutputInitIsDone =.TRUE.
SWRITE(UNIT_stdOut,'(A)')' INIT OUTPUT DONE!'
SWRITE(UNIT_StdOut,'(132("-"))')
END SUBROUTINE InitOutput


SUBROUTINE FinalizeOutput()
!===================================================================================================================================
! Deallocate global variables
!===================================================================================================================================
! MODULES
USE MODH_Output_Vars,ONLY:OutputInitIsDone
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
!===================================================================================================================================
OutputInitIsDone = .FALSE.
END SUBROUTINE FinalizeOutput

END MODULE MODH_Output
