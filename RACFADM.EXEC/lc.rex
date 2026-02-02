/* --------------------  rexx procedure  -------------------- *
 | Name:      LC                                              |
 |                                                            |
 | Function:  The LC edit macro is used to issue a            |
 |            RACDCERT LIST(LABEL('labelname')) ID(userid)    |
 |            for the label at the cursor position.           |
 |                                                            |
 |                                                            |
 | Use:       LC  cursor-->label name                         |
 |                                                            |
 | Author:    Janko Kalinic                                   |
 |            The ISPF Cabal - Vive la revolution             |
 |            the.pds.command@gmail.com                       |
 |                                                            |
 | History:  (most recent on top)                             |
 |            01/22/26 - Process CERTAUTH/SITE certificates   |
 |            12/18/24 - Creation                             |
 |                                                            |
 * ---------------------------------------------------------- */
Address ISREdit
"isredit macro"

Address ISREDIT "(ln) = LINE .ZCSR"
if substr(ln,37,4) = 'OWN=' then
  id = strip(substr(ln,41,12))
lab = strip(substr(ln,4,32))

if substr(ln,37,3) = 'ST=' then do
  Address ISREDIT "find 'User:' prev"
  Address ISREDIT "(user) = LINE .ZCSR"
  id = "id("strip(substr(user,7,8))")"
  end

x = outtrap('cmd.')
Address TSO "racdcert list(label('"lab"'))" id
x = outtrap('off')
TRACE
call view_info
exit

/*--------------------------------------------------------------------*/
/*  View information                                                  */
/*--------------------------------------------------------------------*/
view_info:
  ddname = 'racfa'random(0,999)
  address tso "alloc f("ddname") new reuse",
              "lrecl(80) blksize(0) recfm(f b)",
              "unit(vio) space(1 5) cylinders"
  address tso "execio * diskw "ddname" (stem cmd. finis"
  drop rec.
  address ispexec
  "lminit dataid(cmddatid) ddname("ddname")"
  "view dataid("cmddatid")"
  address tso "free fi("ddname")"
return
