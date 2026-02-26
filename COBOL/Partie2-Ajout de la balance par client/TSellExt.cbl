        IDENTIFICATION DIVISION.
        PROGRAM-ID. TSELLEXT.
        ENVIRONMENT DIVISION.
        CONFIGURATION SECTION.
        SPECIAL-NAMES.
            DECIMAL-POINT IS COMMA.
        INPUT-OUTPUT SECTION.
      *===========================================================*
      * PROGRAMME : TSELLEXT                     DATE = 10/10/25  *
      * OBJET: RÉCUPÉRER LES VENTES EXTÉRIEURES                   *
      *           (VENTES EU ET AS)                               *
      * SELON LES PRÉREQUIS DU CAHIER DES CHARGES :               *
      * INCRÉMENTATION DU CHIFFRE D'AFFAIRE (BALANCE)             *
      * DE CHAQUE CLIENT EN FONCTION DES VENTES À L'ÉTRANGER      *
      *                                                           *
      * AUTEUR = Z******, JULIEN (API14, API6)                    *
      *===========================================================*

       FILE-CONTROL.
           SELECT F-VENTEAS ASSIGN TO DDAS
               FILE STATUS IS WS-FILE-STATUSAS.

           SELECT F-VENTEEU ASSIGN TO DDEU
               FILE STATUS IS WS-FILE-STATUSEU.

       DATA DIVISION.
       FILE SECTION.

       FD F-VENTEEU
           DATA RECORD IS VENTE-EU-REC
           RECORDING MODE F.
       01 VENTE-EU-REC.
           05 V-O-NO-EU      PIC 9(3).
           05 V-O-DATE-EU    PIC X(10).
           05 V-S-NO-EU      PIC 9(2).
           05 V-C-NO-EU      PIC 9(4).
           05 V-P-NO-EU      PIC X(3).
           05 V-PRICE-F-EU   PIC X(5).
           05 V-QUANTITY-EU  PIC X(2).
           05 V-RESERVE-EU   PIC X(6).

       FD F-VENTEAS
           DATA RECORD IS VENTE-AS-REC
           RECORDING MODE F.
       01 VENTE-AS-REC.
           05 V-O-NO-AS      PIC 9(3).
           05 V-O-DATE-AS    PIC X(10).
           05 V-S-NO-AS      PIC 9(2).
           05 V-C-NO-AS      PIC 9(4).
           05 V-P-NO-AS      PIC X(3).
           05 V-PRICE-F-AS   PIC X(5).
           05 V-QUANTITY-AS  PIC X(2).
           05 V-RESERVE-AS   PIC X(6).

       WORKING-STORAGE SECTION.

       01 WS-FILE-STATUSEU  PIC 99.
       01 WS-FILE-STATUSAS  PIC 99.
       01 WS-SQLCODE-AFF    PIC ++++++++9.

      * VARIABLES DE CONTRôLE
       01 EOF-EU        PIC X VALUE 'N'.
       01 EOF-AS        PIC X VALUE 'N'.
       01 WS-LAST-ONO   PIC 9(3) VALUE 0.
       01 WS-ERREUR-SQL PIC X VALUE 'N'.

      * VARIABLES DE CALCUL
       01 WS-MONTANT     PIC S9(9)V99 COMP-3 VALUE 0.
       01 WS-PRICE-D     PIC S9(7)V99 COMP-3 VALUE 0.
       01 WS-QUANTITY-D  PIC S9(5)    COMP-3 VALUE 0.

      * VARIABLES RELATIVE AU DATES
       01 WS-DAY         PIC X(2).
       01 WS-MONTH       PIC X(2).
       01 WS-YEAR        PIC X(4).
       01 WS-DATE-SQL    PIC X(10).

      * SQLCA - COMMUNICATION SQL
           EXEC SQL
               INCLUDE SQLCA
           END-EXEC.

      * DCLGENS
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
               INCLUDE DCSUPPL
           END-EXEC.
           EXEC SQL
               INCLUDE DCITEMS
           END-EXEC.

       PROCEDURE DIVISION.
           PERFORM 1000-DEBUT.
           PERFORM 2000-TRAITEMENT-EU
           PERFORM 2100-TRAITEMENT-AS
           PERFORM 3000-FIN.
           GOBACK.

       1000-DEBUT.
           EXEC SQL
               WHENEVER SQLERROR CONTINUE
           END-EXEC
           EXEC SQL
               SET CURRENT SQLID = 'API6'
           END-EXEC
           .

       2000-TRAITEMENT-EU.
            MOVE ZERO TO WS-LAST-ONO
           OPEN INPUT F-VENTEEU
             PERFORM UNTIL EOF-EU = 'Y' OR WS-ERREUR-SQL = 'Y'
              READ F-VENTEEU
                AT END
                 MOVE 'Y' TO EOF-EU
                 NOT AT END
                  PERFORM 2200-TRAITER-LIGNE-EU
                  PERFORM 2500-UPDATE-CUSTOMER
                END-READ
             END-PERFORM
             IF WS-LAST-ONO NOT = 0
              DISPLAY 'COMMIT FINAL DERNIER ORDRE EU : ' WS-LAST-ONO
               EXEC SQL
                 COMMIT
               END-EXEC
             END-IF
           CLOSE F-VENTEEU
            .

       2100-TRAITEMENT-AS.
           MOVE ZERO TO WS-LAST-ONO
           OPEN INPUT F-VENTEAS
            PERFORM UNTIL EOF-AS = 'Y' OR WS-ERREUR-SQL = 'Y'
             READ F-VENTEAS
               AT END
                MOVE 'Y' TO EOF-AS
               NOT AT END
                PERFORM 2250-TRAITER-LIGNE-AS
                PERFORM 2500-UPDATE-CUSTOMER
             END-READ
            END-PERFORM
           CLOSE F-VENTEAS
           .
       2200-TRAITER-LIGNE-EU.
           MOVE V-P-NO-EU TO PS-P-NO
            IF V-PRICE-F-EU = SPACES
           EXEC SQL
             SELECT PRICE
               INTO :WS-PRICE-D
               FROM PRODUCTS
               WHERE P_NO = :PS-P-NO
           END-EXEC
           IF SQLCODE = 0
           CONTINUE
           ELSE
                DISPLAY 'ERREUR SQL PRODUIT ' PS-P-NO ' CODE= ' SQLCODE
                MOVE 0 TO WS-PRICE-D
           END-IF
            ELSE
              COMPUTE WS-PRICE-D = FUNCTION NUMVAL(V-PRICE-F-EU) / 100
              DISPLAY 'PRIX EXISTANT : ' WS-PRICE-D
            END-IF
      *     QUANTITEES
            IF V-QUANTITY-EU = SPACES
               MOVE 0 TO WS-QUANTITY-D
            ELSE
               COMPUTE WS-QUANTITY-D = FUNCTION NUMVAL(V-QUANTITY-EU)
            END-IF
      *     MONTANT
            COMPUTE WS-MONTANT = WS-PRICE-D * WS-QUANTITY-D

            DISPLAY 'PRIX FINAL : ' WS-PRICE-D
            DISPLAY 'QTE NUM   : ' WS-QUANTITY-D
            DISPLAY 'MONTANT   : ' WS-MONTANT

            MOVE V-O-NO-EU     TO OD-O-NO
            MOVE V-O-DATE-EU   TO OD-O-DATE
            MOVE V-S-NO-EU     TO OD-S-NO
            MOVE V-P-NO-EU     TO IT-P-NO
            MOVE V-O-NO-EU     TO IT-O-NO
            MOVE WS-PRICE-D    TO IT-PRICE
            MOVE WS-QUANTITY-D TO IT-QUANTITY
      *     MAJ BALANCE CLIENT
            MOVE V-C-NO-EU     TO OD-C-NO

            IF WS-LAST-ONO NOT = V-O-NO-EU
             IF WS-LAST-ONO NOT = ZERO
              DISPLAY 'COMMIT DE LORDRE PRECEDENT : ' WS-LAST-ONO
              EXEC SQL
                COMMIT
              END-EXEC
             END-IF
              MOVE V-O-NO-EU TO WS-LAST-ONO
             ELSE
               DISPLAY 'ORDRE DEJA PRESENT : ' WS-LAST-ONO
             END-IF

            PERFORM 2300-INSERER-ORDER
            PERFORM 2400-INSERER-ITEM
            .


        2250-TRAITER-LIGNE-AS.
           MOVE 0 TO WS-PRICE-D
           MOVE 'N' TO WS-ERREUR-SQL
           MOVE 0 TO WS-LAST-ONO
           MOVE V-P-NO-AS TO PS-P-NO

      *    PRIX
           IF V-PRICE-F-AS = SPACES

           EXEC SQL
             SELECT PRICE
             INTO :WS-PRICE-D
             FROM PRODUCTS
             WHERE P_NO = :PS-P-NO
           END-EXEC
               IF SQLCODE = 0
                CONTINUE
               ELSE
                DISPLAY 'ERREUR SQL PRODUIT ' PS-P-NO ' CODE= ' SQLCODE
                MOVE 0 TO WS-PRICE-D
                END-IF
           ELSE
             COMPUTE WS-PRICE-D = FUNCTION NUMVAL(V-PRICE-F-AS) / 100
              DISPLAY 'PRIX EXISTANT : ' WS-PRICE-D
           END-IF
      *    QUANTITéES
           IF V-QUANTITY-AS = SPACES
                MOVE 0 TO WS-QUANTITY-D
            ELSE
                COMPUTE WS-QUANTITY-D = FUNCTION NUMVAL(V-QUANTITY-AS)
            END-IF
      *     MONTANT
            COMPUTE WS-MONTANT = WS-PRICE-D * WS-QUANTITY-D

            DISPLAY 'PRIX FINAL : ' WS-PRICE-D
            DISPLAY 'QTE NUM   : ' WS-QUANTITY-D
            DISPLAY 'MONTANT   : ' WS-MONTANT

            MOVE V-O-NO-AS       TO OD-O-NO
            MOVE V-O-DATE-AS     TO OD-O-DATE
            MOVE V-S-NO-AS       TO OD-S-NO
            MOVE V-P-NO-AS       TO IT-P-NO
            MOVE V-O-NO-AS       TO IT-O-NO
            MOVE WS-PRICE-D      TO IT-PRICE
            MOVE WS-QUANTITY-D   TO IT-QUANTITY
      *     MISE A JOUR BALANCE CLIENT
            MOVE V-C-NO-AS       TO OD-C-NO

            IF WS-LAST-ONO NOT = V-O-NO-AS
             IF WS-LAST-ONO NOT = ZERO
              DISPLAY 'COMMIT DE LORDRE PRECEDENT : ' WS-LAST-ONO
              EXEC SQL
                COMMIT
              END-EXEC
             END-IF
              MOVE V-O-NO-AS TO WS-LAST-ONO
             ELSE
               DISPLAY 'ORDRE DEJA PRESENT : ' WS-LAST-ONO
             END-IF

            PERFORM 2300-INSERER-ORDER
            PERFORM 2400-INSERER-ITEM
            .

       2300-INSERER-ORDER.
           DISPLAY 'INSERT OD ' OD-O-NO ' ' IT-P-NO ' ' IT-PRICE ' '
                    IT-QUANTITY
           DISPLAY 'DEBUG DATE AS : [' OD-O-DATE ']'
      *    FORMATAGE DES DATES
           UNSTRING OD-O-DATE DELIMITED BY '/'
              INTO WS-DAY,
                   WS-MONTH,
                   WS-YEAR
           END-UNSTRING

           STRING WS-YEAR '-' WS-MONTH '-' WS-DAY
             DELIMITED BY SIZE INTO WS-DATE-SQL
           END-STRING

           MOVE WS-DATE-SQL TO OD-O-DATE.

            EXEC SQL
               INSERT INTO ORDERS (O_NO, C_NO, O_DATE, S_NO)
               VALUES (:OD-O-NO, :OD-C-NO, :OD-O-DATE, :OD-S-NO)
            END-EXEC
           IF SQLCODE = -803
               DISPLAY 'ORDRE DEJA PRESENT : ' OD-O-NO
           ELSE
              IF SQLCODE NOT = 0
                  MOVE 'Y' TO WS-ERREUR-SQL
                  PERFORM 3100-GESTION-ERREUR
              END-IF
           END-IF
            .
       2400-INSERER-ITEM.
           DISPLAY 'INSERT IT ' IT-O-NO ' ' IT-P-NO ' ' IT-PRICE ' '
                          IT-QUANTITY
           EXEC SQL
              INSERT INTO ITEMS (O_NO, P_NO, QUANTITY, PRICE)
              VALUES (:IT-O-NO, :IT-P-NO, :IT-QUANTITY, :IT-PRICE)
           END-EXEC
           IF SQLCODE NOT = 0
               MOVE 'Y' TO WS-ERREUR-SQL
               PERFORM 3100-GESTION-ERREUR
           END-IF
           .
       2500-UPDATE-CUSTOMER.
           EXEC SQL
               UPDATE CUSTOMERS
                SET BALANCE = BALANCE + :WS-MONTANT
                WHERE C_NO = :OD-C-NO
           END-EXEC
           IF SQLCODE NOT = 0
               MOVE 'Y' TO WS-ERREUR-SQL
               PERFORM 3100-GESTION-ERREUR
           END-IF
           .
       3000-FIN.
           EXEC SQL
               COMMIT
           END-EXEC
           DISPLAY '*** TRAITEMENT TERMINE ***'
           STOP RUN
           .

       3100-GESTION-ERREUR.
           IF SQLCODE NOT = 0
            MOVE SQLCODE TO WS-SQLCODE-AFF
            DISPLAY 'ERREUR SQL PRODUIT' PS-P-NO ' CODE ' WS-SQLCODE-AFF
               EVALUATE TRUE
                   WHEN SQLCODE = +100
                       DISPLAY 'PRODUIT NON TROUVÉ DANS PRODUCTS'
                   WHEN SQLCODE = -803
                       DISPLAY 'DOUBLON PRODUIT ' PS-P-NO
                   WHEN SQLCODE > 0
                       DISPLAY 'WARNING SUR LE PRODUIT ' PS-P-NO
                   WHEN OTHER
                       DISPLAY 'ERREUR INCONNUE SUR LE PRODUIT ' PS-P-NO
               END-EVALUATE
               MOVE 0 TO WS-PRICE-D
               DISPLAY 'SQLSTATE = ' SQLSTATE
           EXEC SQL
              ROLLBACK
           END-EXEC
                MOVE 'Y' TO EOF-EU
                MOVE 'Y' TO EOF-AS
                END-IF
                 .
