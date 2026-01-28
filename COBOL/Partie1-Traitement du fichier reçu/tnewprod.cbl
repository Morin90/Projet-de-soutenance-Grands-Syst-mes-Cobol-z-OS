       IDENTIFICATION DIVISION.
       PROGRAM-ID. TNEWPROD.
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
       INPUT-OUTPUT SECTION.

       FILE-CONTROL.
           SELECT F-NEWPRODS ASSIGN TO DDNP
               FILE STATUS IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD F-NEWPRODS
           RECORDING MODE F.
       01 F-NEWPRODS-REC     PIC X(45).

       WORKING-STORAGE SECTION.
       01 WS-FILE-STATUS     PIC 99.
       01 WS-NEWPROD-REC     PIC X(45).
       01 WS-NUMPROD         PIC X(3).
       01 WS-DESCRIPT        PIC X(20).
       01 WS-PRIX            PIC X(5).
       01 WS-DEVISE          PIC X(2).
       01 WS-PRIX-NUM        PIC 9(3)V99.
       01 WS-PRIX-CONVERT    PIC 9(3)V99.
       01 WS-PRIX-AFF        PIC Z(3)9,99.
       01 WS-SQLCODE-AFF     PIC ++++++++9.
       01 WS-RETURN-CODE     PIC 9(2) VALUE 0.
       01 WS-SOUSPROG        PIC X(8) VALUE 'SCONVDEV'.
       01 EOF-FLAG           PIC X VALUE 'F'.
           88 FIN-FICHIER     VALUE 'V'.
           88 NON-FIN-FICHIER VALUE 'F'.

      *-----------------------------------------------------*
      * UTILISATION DE SQLCA / ZONE DE COMMUNICATION SQL  *
      * AMENE LES VARIABLES SQLCODE ET SQLSTATE         *
      *-----------------------------------------------*

           EXEC SQL
               INCLUDE SQLCA
           END-EXEC.


      *-------------------------------------------------------*
      * ZONE D'UTILISATION DU DCLGN DE LA TABLE PRODUCTS    *
      *---------------------------------------------------*

           EXEC SQL
               INCLUDE DCPROD
           END-EXEC.

       PROCEDURE DIVISION.
           PERFORM 1000-DEBUT.
           SET NON-FIN-FICHIER TO TRUE
           READ F-NEWPRODS
            AT END SET FIN-FICHIER TO TRUE
           END-READ

           PERFORM UNTIL FIN-FICHIER
           PERFORM 2000-TRAITEMENT

           READ F-NEWPRODS
            AT END SET FIN-FICHIER TO TRUE
           END-READ
           END-PERFORM
           .
           PERFORM 3000-FIN.
           GOBACK.

       1000-DEBUT.
           OPEN INPUT F-NEWPRODS
           MOVE 0 TO WS-FILE-STATUS
           EXEC SQL
                SET CURRENT SQLID = 'API14'
           END-EXEC
           .

       2000-TRAITEMENT.

           MOVE F-NEWPRODS-REC TO WS-NEWPROD-REC

      *--------------------------------------------------*
      * SEPARATION DES CHAMPS GRACE AU DELIMITER ";"   *
      *----------------------------------------------*

           UNSTRING F-NEWPRODS-REC
               DELIMITED BY ';'
               INTO WS-NUMPROD,
                    WS-DESCRIPT,
                    WS-PRIX,
                    WS-DEVISE
           END-UNSTRING

      *----------------------------------------------------------*
      * FONCTION POUR METTRE EN MAJUSCULE LA PREMIERE LETTRE   *
      * -----------------------------------------------------*

           MOVE FUNCTION LOWER-CASE(WS-DESCRIPT) TO WS-DESCRIPT
           IF WS-DESCRIPT NOT = SPACES
               MOVE FUNCTION UPPER-CASE(WS-DESCRIPT(1:1))
                    TO WS-DESCRIPT(1:1)
           END-IF
           INSPECT WS-PRIX REPLACING ALL '.' BY ','
           COMPUTE WS-PRIX-NUM = FUNCTION NUMVAL (WS-PRIX)
           DISPLAY 'PRIX NUM = ' WS-PRIX-NUM


      *-------------------------------------------------*
      * APPEL DU SOUS-PROGRAMME POUR LA CONERSION     *
      * --------------------------------------------*


           CALL WS-SOUSPROG USING WS-DEVISE
                                    WS-PRIX-NUM
                                        WS-PRIX-CONVERT
                                           WS-RETURN-CODE

           IF WS-RETURN-CODE = 99
               DISPLAY 'ERREUR CONVERSION DEVISE : ' WS-DEVISE
           END-IF

      *-----------------------------------------------------*
      * METTRE LE RESULTAT DANS UNE PICTURE D'EDITION     *
      *-------------------------------------------------*

           MOVE WS-PRIX-CONVERT TO WS-PRIX-AFF

           DISPLAY 'POUR LE PRODUIT N : ' WS-NUMPROD
                   ' ' WS-DESCRIPT
                   ' LE PRIX EST DE : ' WS-PRIX-AFF
                   ' ' WS-DEVISE
           MOVE WS-NUMPROD         TO PS-P-NO
           MOVE LENGTH OF WS-DESCRIPT TO PS-DESCRIPTION-LEN
           MOVE WS-DESCRIPT        TO PS-DESCRIPTION-TEXT
           MOVE WS-PRIX-CONVERT    TO PS-PRICE


               EXEC SQL
                   INSERT INTO API14.PRODUCTS (P_NO, DESCRIPTION, PRICE)
                    VALUES (:PS-P-NO, :PS-DESCRIPTION, :PS-PRICE)
               END-EXEC

      *----------------*
      * TEST SQLCODE  *
      *--------------*

           IF SQLCODE = 0
            CONTINUE
           END-IF

           IF SQLCODE NOT = 0
             DISPLAY 'ERREUR INSERTION PRODUIT ' WS-NUMPROD
               EVALUATE TRUE
                  WHEN SQLCODE = -803
                       DISPLAY 'VOUS AVEZ DES DOUBLONS' WS-NUMPROD
                  WHEN SQLCODE > 0
                       DISPLAY 'VOUS AVEZ UN WARNING ' WS-NUMPROD
                  WHEN OTHER
                       DISPLAY 'VOUS AVEZ UNE ERREUR ' WS-NUMPROD
             MOVE SQLCODE TO WS-SQLCODE-AFF
             DISPLAY 'SQLCODE :' WS-SQLCODE-AFF
           END-IF.


       3000-FIN.

           EXEC SQL
               COMMIT
           END-EXEC

      *----------------------------------*
      *  TESTER SQLCODE APRES COMMIT   *
      *------------------------------*

           EVALUATE TRUE
               WHEN SQLCODE = 0
                   DISPLAY 'COMMIT EFFECTUE AVEC SUCCES.'
               WHEN SQLCODE > 0
                   DISPLAY 'WARNING APRES COMMIT, SQLCODE = ' SQLCODE
               WHEN OTHER
                   DISPLAY 'ERREUR APRES COMMIT, SQLCODE = ' SQLCODE
           END-EVALUATE


           CLOSE F-NEWPRODS
           .
