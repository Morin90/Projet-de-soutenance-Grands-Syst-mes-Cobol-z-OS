       IDENTIFICATION DIVISION.
       PROGRAM-ID. GENFACTU.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT F-EXTRACT ASSIGN TO DDED
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FSTATUS-EXTRACT.
           SELECT F-IMPRESSION ASSIGN TO DDIM
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FSTATUS-IMPRESSION.
       DATA DIVISION.
       FILE SECTION.

      * --- FICHIER D'ENTRéE ISSU D'EXTRACTD --- *

       FD  F-EXTRACT
           RECORDING MODE F
           DATA RECORD IS EXTRACT-REC.

       01  EXTRACT-REC.
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

      * --- FICHIER DE SORTIE : FACTURE TEXTE --- *
       FD  F-IMPRESSION
           RECORDING MODE F
           DATA RECORD IS IMPRESS-REC.

       01  IMPRESS-REC.
           05 IMPRESS-LINE PIC X(80).

       WORKING-STORAGE SECTION.

       01  WS-FSTATUS-EXTRACT     PIC XX.
       01  WS-FSTATUS-IMPRESSION  PIC XX.

       01  WS-TVA              PIC 9V99       VALUE 0.20.
       01  WS-TOTAL-LIGNE      PIC 9(7)V99    VALUE 0.
       01  WS-TOTAL-COMMANDE   PIC 9(7)V99    VALUE 0.
       01  WS-MONTANT-TVA      PIC 9(7)V99    VALUE 0.
       01  WS-MONTANT-TOTAL    PIC 9(7)V99    VALUE 0.

       01  WS-CMD-CURRENT      PIC 9(3) VALUE 0.
       01  WS-CPT-FACTURE      PIC 9(4) VALUE 0.
       01  WS-LINE             PIC X(80).
       01  WS-DATE-TXT         PIC X(50).

      * --- ZONES éDITéES POUR AFFICHAGE DES MONTANTS --- *
       01  WS-PRICE-DISP       PIC Z(6).99.
       01  WS-TOTAL-DISP       PIC Z(9).99.
       01  WS-TVA-DISP         PIC ZZ9.99.
       01  WS-TVA-TXT          PIC X(5).
       01  WS-TVA-DISP-TXT     PIC Z9.99.
       01  WS-SOUS-TOTAL-DISP  PIC Z(9).99.
       01  WS-TOTAL-GEN-DISP   PIC Z(9).99.
       01  WS-SPACES-45        PIC X(45)   VALUE ALL ' '.
       01  WS-SPACES-15        PIC X(15)   VALUE ALL ' '.
       01  WS-SPACES-6         PIC X(6)    VALUE ALL ' '.
       01  WS-SPACES-4         PIC X(4)    VALUE ALL ' '.
       01  WS-SPACES-14        PIC X(14)   VALUE ALL ' '.
       01  WS-SPACES-8         PIC X(8)    VALUE ALL ' '.
       01  WS-SPACES-12        PIC X(12)   VALUE ALL ' '.
       01  WS-STARS-80         PIC X(80)   VALUE ALL '*'.
       01  WS-SPACES-1         PIC X(1)    VALUE ALL ' '.
       01  WS-DOLLAR           PIC X(1)    VALUE '$'.

      * --- ZONES VARIABLES POUR LA COMMISSION D UN EMPLOYE --- *
       01  WS-TAUX-COMMISSION     PIC 9V99    VALUE 0.10.
       01  WS-MONTANT-COMMISSION  PIC 9(7)V99 VALUE 0.
       01  WS-COMMISSION-DISP     PIC Z(9).99.
       01  WS-TAUX-COMMISSION-TXT PIC X(05).
       01  WS-TAUX-COMMISSION-DISP   PIC Z9.99.

      * --- ZONES éDITéS DE VARIABLES CHAR --- *
       01  WS-NOM-ED           PIC X(8).
       01  WS-PRENOM-ED        PIC X(7).
       01  WS-ADRESS           PIC X(16).
       01  WS-DEP-NOM          PIC X(11).
       01  WS-VILLE-ED         PIC X(11).

      * --- PARAMèTRE POUR LE SOUS-PROGRAMME DATETXT --- *
       01  WS-DATE-IN          PIC X(10).
       01  WS-DATE-OUT         PIC X(50).

       PROCEDURE DIVISION.

           PERFORM 1000-DEBUT.
           PERFORM 2000-TRAITEMENT.
           PERFORM 3000-FIN.
           GOBACK.

      * ==============================================================*
      *  1000 - INITIALISATION                                      *
      * ==========================================================*
       1000-DEBUT.
           DISPLAY '*** DEBUT GENERATION FACTURES ***'.
           DISPLAY 'ENTREZ LE TAUX DE TVA (EX: 020 POUR 20%) : '.
           ACCEPT WS-TVA.

           OPEN INPUT F-EXTRACT.
           OPEN OUTPUT F-IMPRESSION.

           IF WS-FSTATUS-EXTRACT NOT = '00'
               DISPLAY 'ERREUR OPEN F-EXT, STATUS=' WS-FSTATUS-EXTRACT
               STOP RUN
           END-IF.

      * ===============================================================*
      *  2000 - TRAITEMENT PRINCIPAL                                 *
      * ===========================================================*

       2000-TRAITEMENT.

           MOVE 0 TO WS-CPT-FACTURE
                    WS-CMD-CURRENT
                    WS-TOTAL-COMMANDE.

           PERFORM UNTIL WS-FSTATUS-EXTRACT = '10'
               READ F-EXTRACT
                   AT END
                       MOVE '10' TO WS-FSTATUS-EXTRACT
                   NOT AT END
                       IF DATA-ONO NOT = WS-CMD-CURRENT
                           IF WS-CMD-CURRENT NOT = 0
                               PERFORM 2400-CLOTURER-FACTURE
                           END-IF
                           ADD 1 TO WS-CPT-FACTURE
                           MOVE DATA-ONO TO WS-CMD-CURRENT
                           PERFORM 2100-OUVRIR-FACTURE
                       END-IF

                       PERFORM 2200-ECRIRE-LIGNE-FACTURE
               END-READ
           END-PERFORM.

           IF WS-CMD-CURRENT NOT = 0
               PERFORM 2400-CLOTURER-FACTURE
           END-IF.

      * ================================================================*
      *  2100 - OUVERTURE NOUVELLE FACTURE                            *
      * ============================================================*

       2100-OUVRIR-FACTURE.

           MOVE 0 TO WS-TOTAL-COMMANDE.

           IF WS-CPT-FACTURE > 1
               MOVE X'0C' TO WS-LINE
               WRITE IMPRESS-REC FROM WS-LINE
           END-IF.

      *---------------------------------------------------------*
      * ENCADRé EN HAUT à DROITE AVEC LE NOM ET L'ADRESSE     *
      *-----------------------------------------------------*

           MOVE ALL '-' TO WS-LINE.
           WRITE IMPRESS-REC FROM WS-LINE.

           MOVE SPACES TO WS-LINE.
           STRING WS-SPACES-45 DATA-COMPANY DELIMITED BY SIZE
                 INTO WS-LINE
           END-STRING.
           WRITE IMPRESS-REC FROM WS-LINE.

           MOVE SPACES TO WS-LINE.
           STRING WS-SPACES-45 DATA-ADDRESS DELIMITED BY SIZE
                 INTO WS-LINE
           END-STRING.
           WRITE IMPRESS-REC FROM WS-LINE.

           MOVE DATA-CITY TO WS-VILLE-ED
           MOVE SPACES TO WS-LINE.
           STRING WS-SPACES-45 WS-VILLE-ED ', ' DATA-ZIP
                 DELIMITED BY SIZE INTO WS-LINE
           END-STRING.
           WRITE IMPRESS-REC FROM WS-LINE.

           MOVE SPACES TO WS-LINE.
           STRING WS-SPACES-45 DATA-STATE
                 DELIMITED BY SIZE INTO WS-LINE
           END-STRING.
           WRITE IMPRESS-REC FROM WS-LINE.

           MOVE ALL '-' TO WS-LINE.
           WRITE IMPRESS-REC FROM WS-LINE.

           MOVE SPACES TO WS-LINE.
           WRITE IMPRESS-REC FROM WS-LINE.

      * --- DATE ET INFO COMMANDE --- *
           MOVE DATA-ODATE TO WS-DATE-IN.
           CALL 'DATETXT' USING WS-DATE-IN WS-DATE-OUT.
           MOVE WS-DATE-OUT TO WS-DATE-TXT.

           STRING 'NEW YORK, ' WS-DATE-TXT DELIMITED BY SIZE
                  INTO WS-LINE
           END-STRING.
           WRITE IMPRESS-REC FROM WS-LINE.

           MOVE SPACES TO WS-LINE.
           WRITE IMPRESS-REC FROM WS-LINE.

           STRING 'ORDER NO: ' DATA-ONO
                  DELIMITED BY SIZE INTO WS-LINE
           END-STRING.
           WRITE IMPRESS-REC FROM WS-LINE.


           STRING 'DATE: ' DATA-ODATE
                  DELIMITED BY SIZE INTO WS-LINE
           END-STRING.
           WRITE IMPRESS-REC FROM WS-LINE.

           MOVE SPACES TO WS-LINE.

           WRITE IMPRESS-REC FROM WS-LINE.

           MOVE DATA-DNAME TO WS-DEP-NOM
           MOVE DATA-LNAME TO WS-NOM-ED
           MOVE DATA-FNAME TO WS-PRENOM-ED

           STRING 'YOUR CONTACT WITHIN THE DEPARTEMENT '
                     WS-DEP-NOM ' : ' WS-NOM-ED ', ' WS-PRENOM-ED
                  DELIMITED BY SIZE INTO WS-LINE
           END-STRING.
           WRITE IMPRESS-REC FROM WS-LINE.

           MOVE SPACES TO WS-LINE.
           WRITE IMPRESS-REC FROM WS-LINE.

      * --- EN-TêTE DU TABLEAU --- *
           MOVE ALL '-' TO WS-LINE.
           WRITE IMPRESS-REC FROM WS-LINE.

           STRING
              'P_NO  DESCRIPTION' DELIMITED BY SIZE
              '                  QTY' DELIMITED BY SIZE
              '    PRICE' DELIMITED BY SIZE
              '       TOTAL' DELIMITED BY SIZE
              INTO WS-LINE
           END-STRING.
           WRITE IMPRESS-REC FROM WS-LINE.

           MOVE ALL '-' TO WS-LINE.
           WRITE IMPRESS-REC FROM WS-LINE.

      * ===================== LIGNE ARTICLE ======================== *

       2200-ECRIRE-LIGNE-FACTURE.
           COMPUTE WS-TOTAL-LIGNE = DATA-PRICE * DATA-QUANTITY.
           ADD WS-TOTAL-LIGNE TO WS-TOTAL-COMMANDE.

           MOVE DATA-PRICE TO WS-PRICE-DISP.
           MOVE WS-TOTAL-LIGNE TO WS-TOTAL-DISP.

           STRING DATA-PNO SPACES
                  DATA-DESCRIPTION SPACES
                  DATA-QUANTITY SPACES
                  WS-PRICE-DISP SPACES
                  WS-TOTAL-DISP WS-DOLLAR
                  DELIMITED BY SIZE INTO WS-LINE
           END-STRING.
           WRITE IMPRESS-REC FROM WS-LINE.

      * ===================== CLOTURE FACTURE ====================== *

       2400-CLOTURER-FACTURE.

           MOVE ALL '-' TO WS-LINE.
           WRITE IMPRESS-REC FROM WS-LINE.

           COMPUTE WS-MONTANT-TVA = WS-TOTAL-COMMANDE * WS-TVA.
           COMPUTE WS-MONTANT-TOTAL = WS-TOTAL-COMMANDE
                                         + WS-MONTANT-TVA.

           COMPUTE WS-MONTANT-COMMISSION = WS-TOTAL-COMMANDE
                                               * WS-TAUX-COMMISSION.

           MOVE WS-TOTAL-COMMANDE TO WS-SOUS-TOTAL-DISP.
           MOVE WS-MONTANT-TVA    TO WS-TVA-DISP.
           MOVE WS-MONTANT-COMMISSION TO WS-COMMISSION-DISP.
           MOVE WS-TAUX-COMMISSION TO WS-TAUX-COMMISSION-DISP.
           MOVE WS-TAUX-COMMISSION-DISP TO WS-TAUX-COMMISSION-TXT.

      * --- CONVERSION DU TAUX TVA NUMéRIQUE VERS TEXTE ---*

           MOVE WS-TVA TO WS-TVA-DISP-TXT.
           MOVE WS-TVA-DISP-TXT TO WS-TVA-TXT.

           MOVE WS-MONTANT-TOTAL  TO WS-TOTAL-GEN-DISP.

      *------------------------------*
      * --- LIGNE "SOUS-TOTAL"     *
      *--------------------------*

           MOVE SPACES TO WS-LINE.
           STRING WS-SPACES-14 WS-SPACES-12 'SOUS-TOTAL :  '
                  WS-SPACES-8 WS-SOUS-TOTAL-DISP WS-DOLLAR
                  DELIMITED BY SIZE
                  INTO WS-LINE
           END-STRING.
           WRITE IMPRESS-REC FROM WS-LINE.

      *-----------------------------------------*
      * --- LIGNE "TVA (TAUX) : MONTANT"      *
      *-------------------------------------*
           MOVE SPACES TO WS-LINE.

           MOVE SPACES TO WS-LINE.
           STRING
              WS-SPACES-14 WS-SPACES-12 'TVA ( 20% ) : '
              WS-SPACES-14 WS-TVA-DISP WS-DOLLAR
              DELIMITED BY SIZE
              INTO WS-LINE
           END-STRING.
           WRITE IMPRESS-REC FROM WS-LINE.
      *----------------------------*
      * --- LIGNE COMMISSION     *
      *------------------------*
           MOVE SPACES TO WS-LINE.
           STRING
             WS-SPACES-14 WS-SPACES-12
             'COMMISSION ( 10% ) : '
             WS-SPACES-1 WS-COMMISSION-DISP WS-DOLLAR
             DELIMITED BY SIZE
             INTO WS-LINE
           END-STRING.
           WRITE IMPRESS-REC FROM WS-LINE.

      *---------------------------------*
      * --- LIGNE "TOTAL GENERAL"     *
      *-----------------------------*

           MOVE SPACES TO WS-LINE.
           STRING WS-SPACES-14 WS-SPACES-12 'TOTAL : '
                  WS-SPACES-14 WS-TOTAL-GEN-DISP WS-DOLLAR
                  DELIMITED BY SIZE
                  INTO WS-LINE
           END-STRING.
           WRITE IMPRESS-REC FROM WS-LINE.

           MOVE WS-STARS-80
                TO WS-LINE.
           WRITE IMPRESS-REC FROM WS-LINE.

           DISPLAY 'FACTURE GENEREE POUR COMMANDE : ' DATA-ONO.

      * ===================== FIN DU PROGRAMME ==================== *

       3000-FIN.
           CLOSE F-EXTRACT F-IMPRESSION.
           DISPLAY '*** FIN GENERATION FACTURES ***'.
           GOBACK.
