//API6GENF JOB (ACCT#),'JULIEN',MSGCLASS=H,REGION=4M,CLASS=A,
//    MSGLEVEL=(1,1),NOTIFY=&SYSUID,COND=(4,LT),TIME=(0,5)
//*=================================================================*
//* PROGRAMME : GENFACTU                                            *
//* OBJET     : GENERATION DES FACTURES A PARTIR DU FICHIER EXTRACT *
//*              AVEC APPEL AU SOUS-PROGRAMME DATETXT               *
//*=================================================================*
//     SET SYSUID=API6,NOMPGM=GENFACTU
//*=================================================================*
//* ETAPE DE COMPILATION & LIEN DU PROGRAMME COBOL                  *
//*=================================================================*
//COMPIL EXEC IGYWCL,PARM.COBOL=(ADV,OBJECT,LIB,TEST,APOST)
//COBOL.SYSIN    DD DSN=&SYSUID..COB.PROJET(&NOMPGM),DISP=SHR
//COBOL.SYSLIB   DD DSN=CEE.SCEESAMP,DISP=SHR
//                DD DSN=&SYSUID..COB.CPY,DISP=SHR
//LKED.SYSLMOD   DD DSN=&SYSUID..COB.LOAD,DISP=SHR
//LKED.SYSLIB    DD DSN=&SYSUID..COB.LOAD,DISP=SHR
//LKED.SYSIN     DD *
  INCLUDE SYSLIB('DATETXT')
  NAME GENFACTU(R)
/*
//*=================================================================*
//* ETAPE DE NETTOYAGE DU FICHIER DE SORTIE                         *
//*=================================================================*
//DELETE  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE API6.PROJET.FACTURE.DATA PURGE
  SET MAXCC = 0
/*
//*=================================================================*
//* ETAPE DEXECUTION DU PROGRAMME COBOL                            *
//*=================================================================*
//STEPRUN EXEC PGM=GENFACTU,COND=(4,LT)
//STEPLIB DD DSN=&SYSUID..COB.LOAD,DISP=SHR
//*-----------------------------------------------------------------*
//* FICHIER DENTR E : DONN ES EXTRACT ES PAR EXTRACTD
//*-----------------------------------------------------------------*
//DDED    DD DSN=API6.PROJET.EXTRACT.DATA,DISP=SHR
//*-----------------------------------------------------------------*
//* FICHIER DE SORTIE : FACTURES G N R ES
//*-----------------------------------------------------------------*
//DDIM    DD DSN=API6.PROJET.FACTURE.DATA,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(CYL,(1,1),RLSE),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=800)
//*-----------------------------------------------------------------*
//* SORTIES ET LOGS
//*-----------------------------------------------------------------*
//SYSOUT  DD SYSOUT=*,OUTLIM=5000
//SYSPRINT DD SYSOUT=*,OUTLIM=2500
//SYSIN  DD *
020
/*
//*
//*=================================================================*
//* FIN DU JOB                                                      *
//*=================================================================*
