/*%NOCOMMENT====================* REXX *==============================*/
/*PURPOSE:  RACFADM - List Digital Rings                              */
/*--------------------------------------------------------------------*/
/* FLG  YYMMDD  USERID   DESCRIPTION                                  */
/* ---  ------  -------  -------------------------------------------- */
/* @A0  260117  TRIDJK   Created REXX                                 */
/*====================================================================*/
PANELD1     = "RACFDISP"   /* Display report with colors   */
PANELM2     = "RACFMSG2"   /* Display RACF command and RC  */
ddname      = 'RACFA'random(0,999) /* Unique DDNAME        */
parse source . . REXXPGM .         /* Obtain REXX pgm name */
REXXPGM     = LEFT(REXXPGM,8)
NULL        = ''

ADDRESS ISPEXEC
  "CONTROL ERRORS RETURN"
  "VGET (SETGDISP SETMADMN SETMSHOW SETMTRAC) PROFILE"

  If (SETMTRAC <> 'NO') then do
     Say "*"COPIES("-",70)"*"
     Say "*"Center("Begin Program = "REXXPGM,70)"*"
     Say "*"COPIES("-",70)"*"
     if (SETMTRAC <> 'PROGRAMS') THEN
        interpret "Trace "SUBSTR(SETMTRAC,1,1)
     end

/*--------------------------------------------------------------------*/
/*  List Digital Rings                                                */
/*--------------------------------------------------------------------*/
  cmd = "search filter(**) class(user)"
  x = outtrap("cmd.")
  Address TSO cmd
  cmd_rc = rc
  x = outtrap("off")
  if (SETMSHOW <> 'NO') then
     call SHOWCMD

  x = outtrap("ring.")
  do i = 4 to cmd.0
    user = cmd.i
    cmd = "racdcert listring(*) id("user")"
    Address TSO cmd
    cmd_rc = rc
    if (SETMSHOW <> 'NO') then
       call SHOWCMD
    end
    x = outtrap("off")

  call Get_Rings

  do j = 1 to cmdrec.0
     cmdrec.j = substr(cmdrec.j,1,80)
  end
  Address tso "alloc f("ddname") new reuse",
              "lrecl(80) blksize(0) recfm(f b)",
              "unit(vio) space(1 5) cylinders"
  Address tso "execio * diskw "ddname" (stem cmdrec. finis"
  drop cmdrec.

  Address ispexec
  "lminit dataid(cmddatid) ddname("ddname")"
  "view dataid("cmddatid") panel("paneld1")"
  Address tso "free fi("ddname")"

  If (SETMTRAC <> 'NO') then do
     Say "*"COPIES("-",70)"*"
     Say "*"Center("End Program = "REXXPGM,70)"*"
     Say "*"COPIES("-",70)"*"
  end
EXIT
/*--------------------------------------------------------------------*/
/*  Get Rings                                                         */
/*--------------------------------------------------------------------*/
Get_Rings:
  cmdrec. = ""
  save_ring = ""
  y = 0
  y = y + 1
  cmdrec.y = 'Note: Use LC edit macro with cursor on label line',
             'to list certificate'

  do x = 1 to ring.0
     ring.x = left(strip(ring.x),80)
     /* Bypass these LISTRING records */
     if left(ring.x,1) = ' ' |,        /* Blank line     */
        left(ring.x,1) = '-' |,        /* Separator line */
        left(ring.x,4) = 'Cert' |,     /* Header line    */
        left(ring.x,4) = 'Ring' |,     /* Header line    */
        left(ring.x,8) = 'The user' |, /* User not in RACF */
        left(ring.x,5) = 'User ' |,    /* No rings nomsgid */
        left(ring.x,4) = 'IRRD' then   /* No rings msgid */
       iterate
     if left(ring.x,7) = 'Digital' then do
       parse var ring.x . . . . . ring_user
       ring_user = strip(ring_user)
       ring_user = strip(ring_user,'T',':')
       ring_user = left(ring_user,8)
       iterate
       end
     if left(ring.x,1) = '>' then do
       parse var ring.x '>' ring_name
       ring_name = strip(ring_name)
       ring_name = strip(ring_name,'T','<')
       iterate
       end
     if left(ring.x,1) <> ' ' then do
       cert_name  = substr(ring.x,1,32)
       cert_owner = substr(ring.x,36,12)
       cert_usage = substr(ring.x,51,8)
       cert_deflt = substr(ring.x,64,3)
       if save_ring <> ring_user||ring_name then do
         y = y + 1
         cmdrec.y = ' '
         y = y + 1
         cmdrec.y = 'User: 'ring_user '  Ring: 'ring_name
         end
       y = y + 1
       cmdrec.y = 'LN='cert_name 'OWN='cert_owner,
                  'USE='cert_usage 'DFLT='left(cert_deflt,1)
       save_ring = ring_user||ring_name
       end
   end
  cmdrec.0 = y
RETURN
/*--------------------------------------------------------------------*/
/*  Display RACF command and return code                              */
/*--------------------------------------------------------------------*/
SHOWCMD:
  IF (SETMSHOW = "BOTH") | (SETMSHOW = "DISPLAY") THEN DO
     PARSE VAR CMD MSG1 60 MSG2 121 MSG3
     MSG4 = "Return code = "cmd_rc
     "ADDPOP ROW(6) COLUMN(4)"
     "DISPLAY PANEL("PANELM2")"
     "REMPOP"
  END
  IF (SETMSHOW = "BOTH") | (SETMSHOW = "LOG") THEN DO
     zerrsm = "RACFADM "REXXPGM" RC="cmd_rc
     zerrlm = cmd
     'log msg(isrz003)'
  END
RETURN
