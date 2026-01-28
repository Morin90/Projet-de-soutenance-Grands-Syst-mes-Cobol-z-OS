       IDENTIFICATION DIVISION.
       PROGRAM-ID. EXTRACTD.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT F-DATA ASSIGN TO DDED
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FSTATUS.

       DATA DIVISION.
       FILE SECTION.
       FD F-DATA
           RECORDING MODE F
           DATA RECORD IS DATA-REC.

       01 DATA-REC.
           05 DATA-ONO              PIC 9(3).
           05 DATA-SNO              PIC 9(2).
           05 DATA-CNO              PIC 9(4).
           05 DATA-ODATE            PIC X(10).
           05 DATA-PNO              PIC X(3).
           05 DATA-QUANTITY         PIC 9(2).
           05 DATA-PRICE            PIC 9(3)V99.
           05 DATA-DESCRIPTION      PIC X(30).
           05 DATA-LNAME            PIC X(20).
           05 DATA-FNAME            PIC X(20).
           05 DATA-COMPANY          PIC X(30).
           05 DATA-ADDRESS          PIC X(100).
           05 DATA-CITY             PIC X(20).
           05 DATA-STATE            PIC X(2).
           05 DATA-ZIP              PIC X(5).
           05 DATA-DNAME            PIC X(20).

       WORKING-STORAGE SECTION.

           EXEC SQL
               INCLUDE SQLCA
           END-EXEC.

           EXEC SQL
               INCLUDE DCPROD
            END-EXEC.

           EXEC SQL
               INCLUDE DCORDER
           END-EXEC.

           EXEC SQL
               INCLUDE DCCUSTO
           END-EXEC.

           EXEC SQL
               INCLUDE DCITEMS
           END-EXEC.

           EXEC SQL
               INCLUDE DCEMPLO
           END-EXEC.

           EXEC SQL
               INCLUDE DCDEPTS
           END-EXEC.

       01  WS-FSTATUS      PIC XX.
       01  WS-SQLCODE      PIC S9(9) COMP.

      *-----------------------------------------------------------*
      * VARIABLES ALPHANUM RIQUES POUR CONVERSION NUM RIQUES    *
      *--------------------------------------------------------*

       PROCEDURE DIVISION.

           PERFORM 1000-DEBUT.
           PERFORM 2000-TRAITEMENT.
           PERFORM 3000-FIN.
           GOBACK.

      *=============================================================*
      *  INITIALISATION DU PROGRAMME                                *
      *=============================================================*

       1000-DEBUT.

           DISPLAY '*** EXTRACTION DES DONNEES ***'.

           OPEN OUTPUT F-DATA.
           IF WS-FSTATUS NOT = '00'
               DISPLAY 'ERREUR OPEN F-DATA, STATUS=' WS-FSTATUS
               STOP RUN
           END-IF.
           EXEC SQL
               DECLARE C-DATA CURSOR FOR
                   SELECT
                       O.O_NO,
                       O.S_NO,
                       O.C_NO,
                       O.O_DATE,
                       I.P_NO,
                       I.QUANTITY,
                       I.PRICE,
                       P.DESCRIPTION,
                       E.LNAME,
                       E.FNAME,
                       D.DNAME,
                       C.COMPANY,
                       C.ADDRESS,
                       C.CITY,
                       C.STATE,
                       C.ZIP
                   FROM ORDERS O
                       JOIN CUSTOMERS C ON O.C_NO = C.C_NO
                       JOIN EMPLOYEES E ON O.S_NO = E.E_NO
                       JOIN DEPTS     D ON E.DEPT = D.DEPT
                       JOIN ITEMS     I ON O.O_NO = I.O_NO
                       JOIN PRODUCTS  P ON I.P_NO = P.P_NO
                   ORDER BY O.O_NO
           END-EXEC.

           EXEC SQL
               OPEN C-DATA
           END-EXEC.

      *=============================================================*
      *  TRAITEMENT PRINCIPAL                                       *
      *=============================================================*

       2000-TRAITEMENT.
           MOVE 0 TO WS-SQLCODE.
           PERFORM UNTIL WS-SQLCODE = 100

               EXEC SQL
                   FETCH C-DATA INTO
                        :OD-O-NO,
                        :OD-S-NO,
                        :OD-C-NO,
                        :OD-O-DATE,
                        :IT-P-NO,
                        :IT-QUANTITY,
                        :IT-PRICE,
                        :PS-DESCRIPTION,
                        :E-LNAME,
                        :E-FNAME,
                        :D-DNAME,
                        :CU-COMPANY,
                        :CU-ADDRESS,
                        :CU-CITY,
                        :CU-STATE,
                        :CU-ZIP
               END-EXEC

               MOVE SQLCODE TO WS-SQLCODE
               DISPLAY 'SQLCODE FETCH = ' WS-SQLCODE
               IF WS-SQLCODE = 0

                    DISPLAY '--- DONNEES RECUES ---'
                    DISPLAY 'OD-O-NO       : ' OD-O-NO
                    DISPLAY 'OD-S-NO       : ' OD-S-NO
                    DISPLAY 'OD-C-NO       : ' OD-C-NO
                    DISPLAY 'OD-O-DATE     : ' OD-O-DATE
                    DISPLAY 'IT-P-NO       : ' IT-P-NO
                    DISPLAY 'IT-QUANTITY   : ' IT-QUANTITY
                    DISPLAY 'IT-PRICE      : ' IT-PRICE
                    DISPLAY 'PS-DESCRIPTION: ' PS-DESCRIPTION
                    DISPLAY 'E-LNAME   : ' E-LNAME
                    DISPLAY 'E-FNAME   : ' E-FNAME
                    DISPLAY 'CU-CO : ' CU-COMPANY
                    DISPLAY 'CU-ADD: ' CU-ADDRESS
                    DISPLAY 'CU-CITY : ' CU-CITY
                    DISPLAY 'CU-STATE      : ' CU-STATE
                    DISPLAY 'CU-ZIP        : ' CU-ZIP
                    DISPLAY 'D-DNAME  : ' D-DNAME-TEXT(1:D-DNAME-LEN)

                 PERFORM 2200-CHARGER-DATA
                 WRITE DATA-REC
               END-IF
           END-PERFORM.

      *=============================================================*
      *  CHARGEMENT DU RECORD FICHIER                               *
      *=============================================================*

       2200-CHARGER-DATA.

           MOVE SPACES TO DATA-REC

           MOVE OD-O-NO                             TO DATA-ONO.
           MOVE OD-S-NO                             TO DATA-SNO.
           MOVE OD-C-NO                             TO DATA-CNO.
           MOVE OD-O-DATE                           TO DATA-ODATE.
           MOVE IT-P-NO                             TO DATA-PNO.
           MOVE IT-QUANTITY                         TO DATA-QUANTITY.
           MOVE IT-PRICE                            TO DATA-PRICE.
           MOVE PS-DESCRIPTION-TEXT(1:PS-DESCRIPTION-LEN)
                                                   TO DATA-DESCRIPTION.
           MOVE E-LNAME-TEXT(1:E-LNAME-LEN)         TO DATA-LNAME.
           MOVE E-FNAME-TEXT(1:E-FNAME-LEN)         TO DATA-FNAME.
           MOVE CU-COMPANY-TEXT(1:CU-COMPANY-LEN)   TO DATA-COMPANY.
           MOVE CU-ADDRESS-TEXT(1:CU-ADDRESS-LEN)   TO DATA-ADDRESS.
           MOVE CU-CITY-TEXT(1:CU-CITY-LEN)         TO DATA-CITY.
           MOVE CU-STATE                            TO DATA-STATE.
           MOVE CU-ZIP                              TO DATA-ZIP.
           MOVE D-DNAME-TEXT(1:D-DNAME-LEN)         TO DATA-DNAME.

      *=============================================================*
      *  FERMETURE ET FIN DU PROGRAMME                              *
      *=============================================================*
       3000-FIN.

           EXEC SQL
               CLOSE C-DATA
           END-EXEC.

           IF SQLCODE NOT = 0
               DISPLAY '!: ERREUR CLOSE CURSOR . SQLCODE = ' SQLCODE
           END-IF.
           CLOSE F-DATA.

           IF WS-FSTATUS  NOT = "00"
              DISPLAY 'ERROR CLOSE F-DATA, FILE-STATUS=' WS-FSTATUS
           ELSE
              DISPLAY 'FICHIER F-DATA FERME AVEC SUCCES.'
           END-IF.
           DISPLAY '*** FIN DU PROGRAMME EXTRACTD ***'.
           DISPLAY 'SQLCODE FINAL : ' SQLCODE.
           GOBACK.
