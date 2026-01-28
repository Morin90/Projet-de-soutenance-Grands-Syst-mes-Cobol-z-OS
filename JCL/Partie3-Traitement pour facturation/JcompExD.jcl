//API6EXT JOB (ACCT#),'JULIEN',MSGCLASS=H,REGION=4M,CLASS=A,
//    MSGLEVEL=(1,1),NOTIFY=&SYSUID,COND=(4,LT),TIME=(0,5)
//*=================================================================*
//* PROGRAMME : EXTRACTD                                            *
//* OBJET     : EXTRACTION DES DONNEES DE LA BASE DB2               *
//*              POUR GENERATION DES FACTURES                       *
//*=================================================================*
//PROCLIB  JCLLIB ORDER=SDJ.FORM.PROCLIB
//*
//         SET SYSUID=API6,
//             NOMPGM=EXTRACTD
//*
//APPROC   EXEC COMPDB2
//STEPDB2.SYSLIB   DD DSN=&SYSUID..COB.CPY,DISP=SHR
//STEPDB2.SYSIN    DD DSN=&SYSUID..COB.PROJET(&NOMPGM),DISP=SHR
//STEPDB2.DBRMLIB  DD DSN=&SYSUID..COB.DBRM(&NOMPGM),DISP=SHR
//STEPCOB.SYSLIB   DD DSN=&SYSUID..COB.CPY,DISP=SHR
//                 DD DSN=API6.COB.CPY,DISP=SHR
//STEPLNK.SYSLMOD  DD DSN=&SYSUID..COB.LOAD(&NOMPGM),DISP=SHR
//*=================================================================*
//*  ETAPE DE BIND DU PLAN DB2                                      *
//*=================================================================*
//BIND     EXEC PGM=IKJEFT01,COND=(4,LT)
//DBRMLIB  DD  DSN=&SYSUID..COB.DBRM,DISP=SHR
//SYSTSPRT DD  SYSOUT=*,OUTLIM=25000
//SYSTSIN  DD  *
   DSN SYSTEM (DSN1)
   BIND PLAN      (EXTRACTD) -
        QUALIFIER (API6)    -
        ACTION    (REPLACE) -
        MEMBER    (EXTRACTD) -
        VALIDATE  (BIND)    -
        ISOLATION (CS)      -
        ACQUIRE   (USE)     -
        RELEASE   (COMMIT)  -
        EXPLAIN   (NO)
/*
//*=================================================================*
//*  ETAPE DE NETTOYAGE DU FICHIER DE SORTIE                        *
//*=================================================================*
//DELETE  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE API6.PROJET.EXTRACT.DATA PURGE
  SET MAXCC = 0
/*
//*=================================================================*
//*  EXECUTION DU PROGRAMME COBOL/DB2                               *
//*=================================================================*
//STEPRUN  EXEC PGM=IKJEFT01,COND=(4,LT)
//STEPLIB  DD  DSN=&SYSUID..COB.LOAD,DISP=SHR
//DDED   DD  DSN=API6.PROJET.EXTRACT.DATA,DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(CYL,(1,1),RLSE),
//             DCB=(RECFM=FB,LRECL=276,BLKSIZE=2760)
//SYSOUT   DD  SYSOUT=*,OUTLIM=5000
//SYSTSPRT DD  SYSOUT=*,OUTLIM=2500
//SYSTSIN  DD  *
   DSN SYSTEM (DSN1)
   RUN PROGRAM(EXTRACTD) PLAN (EXTRACTD)
   END
/*
//*=================================================================*
//*  FIN DU JOB                                                     *
//*=================================================================*
