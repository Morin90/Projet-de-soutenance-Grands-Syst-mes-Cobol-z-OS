       IDENTIFICATION DIVISION.
       PROGRAM-ID. DATETXT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01  WS-YEAR           PIC 9(4).
       01  WS-MONTH          PIC 99.
       01  WS-DAY            PIC 99.
       01  WS-MONTH-NAME     PIC X(9) VALUE SPACES.
       01  WS-DAY-NAME       PIC X(10) VALUE SPACES.
       01  WS-DAY-IDX        PIC 9 VALUE 1.
      *----------------------------------------*
      * TABLE DES MOIS (SéPARéS PAR UN '-')  *
      *------------------------------------*

       01  WS-MONTH-LIST     PIC X(108)
           VALUE
            "JANUARY-FEBRUARY-MARCH-APRIL-MAY-JUNE-JULY-AUGUST-
      -     "SEPTEMBER-OCTOBER-NOVEMBER-DECEMBER".

       01  WS-MONTH-TABLE.
           05 WS-MONTH-VALUE OCCURS 12 TIMES.
              10 WS-MONTH-TXT PIC X(9).

      *--------------------------------------------*
      * TABLE DES JOURS (SéPARéS PAR UN '-')     *
      *----------------------------------------*

       01  WS-DAY-LIST       PIC X(70)
           VALUE
            "SUNDAY-MONDAY-TUESDAY-WEDNESDAY-THURSDAY-FRIDAY-
      -     "SATURDAY".
       01  WS-DAY-TABLE.
           05 WS-DAY-VALUE OCCURS 7 TIMES.
              10 WS-DAY-TXT PIC X(10).
       LINKAGE SECTION.
       01  LK-DATE-IN        PIC X(10).
       01  LK-DATE-TXT       PIC X(50).

       PROCEDURE DIVISION USING LK-DATE-IN LK-DATE-TXT.

       1000-DATE-CONVERT.

      *--- CONSTRUCTION DE LA TABLE DES MOIS ---

           UNSTRING WS-MONTH-LIST
               DELIMITED BY '-'
               INTO WS-MONTH-VALUE (1)
                    WS-MONTH-VALUE (2)
                    WS-MONTH-VALUE (3)
                    WS-MONTH-VALUE (4)
                    WS-MONTH-VALUE (5)
                    WS-MONTH-VALUE (6)
                    WS-MONTH-VALUE (7)
                    WS-MONTH-VALUE (8)
                    WS-MONTH-VALUE (9)
                    WS-MONTH-VALUE (10)
                    WS-MONTH-VALUE (11)
                    WS-MONTH-VALUE (12)
           END-UNSTRING.

      *--- CONSTRUCTION DE LA TABLE DES JOURS ---

           UNSTRING WS-DAY-LIST
               DELIMITED BY '-'
               INTO WS-DAY-VALUE (1)
                    WS-DAY-VALUE (2)
                    WS-DAY-VALUE (3)
                    WS-DAY-VALUE (4)
                    WS-DAY-VALUE (5)
                    WS-DAY-VALUE (6)
                    WS-DAY-VALUE (7)
           END-UNSTRING.

      *--- DéCOMPOSITION DE LA DATE D ENTRéE ---
           UNSTRING LK-DATE-IN DELIMITED BY '-'
               INTO WS-YEAR WS-MONTH WS-DAY.

      *--- RéCUPéRATION DU MOIS ET DU JOUR ---
           MOVE WS-MONTH-VALUE (WS-MONTH) TO WS-MONTH-NAME

           COMPUTE WS-DAY-IDX = FUNCTION MOD(WS-DAY, 7) + 1
            MOVE WS-DAY-TXT (WS-DAY-IDX) TO WS-DAY-NAME


      *--- CONSTRUCTION DE LA DATE EN TOUTES LETTRES ---
           STRING WS-DAY-NAME DELIMITED BY SIZE
                  ', ' WS-MONTH-NAME DELIMITED BY SIZE
                  ' ' WS-DAY DELIMITED BY SIZE
                  ', ' WS-YEAR DELIMITED BY SIZE
                  INTO LK-DATE-TXT
           END-STRING.

           GOBACK.
