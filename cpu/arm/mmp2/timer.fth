: +!@     ( value offset base -- )  + tuck io! io@ drop  ;
: timer!  ( value offset -- )  timer-pa +!@  ;
: init-timers  ( -- )
   h# 13  h# 24 clock-unit-pa + io!
   0  h# 84 timer-pa + io!      \ TMR_CER  - count enable
   begin  h# 84 timer-pa + io@  7 and  0=  until
   h# 24  h# 00 timer-pa +!@   \ TMR_CCR  - clock control
   h# 200 0 do loop
   0  h# 88 timer!       \ count mode - periodic
   0  h# 4c timer!       \ preload value timer 0
   0  h# 50 timer!       \ preload value timer 1
   0  h# 54 timer!       \ preload value timer 2
   0  h# 58 timer!       \ free run timer 0
   0  h# 5c timer!       \ free run timer 1
   0  h# 60 timer!       \ free run timer 2
   7  h# 74 timer!       \ interrupt clear timer 0
   h# 100  h# 4 timer!   \ Force match
   h# 100  h# 8 timer!   \ Force match
   h# 100  h# c timer!   \ Force match
   h# 200 0 do loop
   7 h# 84 timer!
;

\ The first ldr usually returns stale data; the second one returns good data.
\ Empirically, draining the write buffer does not help.
\ Read-until-match doesn't work with the fast clock because it never matches.
code timer0@  ( -- n )  \ 6.5 MHz
   psh  tos,sp
   set  r1,`h# 014000 +io #`
   mov  r0,#1
   str  r0,[r1,#0xa4]
   ldr  tos,[r1,#0xa4]
   ldr  tos,[r1,#0xa4]
c;

\ For the slower timers, we use the read-until-match technique.
\ Apparently the freeze register doesn't update until the next
\ clock tick, so using it doesn't work well for the slow clocks.
code timer1@  ( -- n )  \ 32.768 kHz
   psh  tos,sp
   set  r1,`h# 014000 +io #`
   ldr  tos,[r1,#0x2c]
   begin
      mov  r0,tos
      ldr  tos,[r1,#0x2c]
      cmps tos,r0
   = until
c;

code timer2@  ( -- n )  \ 1 kHz
   psh  tos,sp
   set  r1,`h# 014000 +io #`
   ldr  tos,[r1,#0x30]
   begin
      mov  r0,tos
      ldr  tos,[r1,#0x30]
      cmps tos,r0
   = until
c;

: timer0-status@  ( -- n )  h# 014034 io@  ;
: timer1-status@  ( -- n )  h# 014038 io@  ;
: timer2-status@  ( -- n )  h# 01403c io@  ;

: timer0-ier@  ( -- n )  h# 014040 io@  ;
: timer1-ier@  ( -- n )  h# 014044 io@  ;
: timer2-ier@  ( -- n )  h# 014048 io@  ;

: timer0-icr!  ( n -- )  h# 014074 io!  ;
: timer1-icr!  ( n -- )  h# 014078 io!  ;
: timer2-icr!  ( n -- )  h# 01407c io!  ;

: timer0-ier!  ( n -- )  h# 014040 io!  ;
: timer1-ier!  ( n -- )  h# 014044 io!  ;
: timer2-ier!  ( n -- )  h# 014048 io!  ;

: timer0-match0!  ( n -- )  h# 014004 io!  ;  : timer0-match0@  ( -- n )  h# 014004 io@  ;
: timer0-match1!  ( n -- )  h# 014008 io!  ;  : timer0-match1@  ( -- n )  h# 014008 io@  ;
: timer0-match2!  ( n -- )  h# 01400c io!  ;  : timer0-match2@  ( -- n )  h# 01400c io@  ;

: timer1-match0!  ( n -- )  h# 014010 io!  ;  : timer1-match0@  ( -- n )  h# 014010 io@  ;
: timer1-match1!  ( n -- )  h# 014014 io!  ;  : timer1-match1@  ( -- n )  h# 014014 io@  ;
: timer1-match2!  ( n -- )  h# 014018 io!  ;  : timer1-match2@  ( -- n )  h# 014018 io@  ;

: timer2-match0!  ( n -- )  h# 01401c io!  ;  : timer2-match0@  ( -- n )  h# 01401c io@  ;
: timer2-match1!  ( n -- )  h# 014020 io!  ;  : timer2-match1@  ( -- n )  h# 014020 io@  ;
: timer2-match2!  ( n -- )  h# 014024 io!  ;  : timer2-match2@  ( -- n )  h# 014024 io@  ;

' timer2@ to get-msecs
: (ms)  ( delay-ms -- )
   get-msecs +  begin     ( limit )
      pause               ( limit )
      dup get-msecs -     ( limit delta )
   0< until               ( limit )
   drop
;
' (ms) to ms

: (us)  ( delay-us -- )
   d# 13 2 */  timer0@ +  ( limit )
   begin                  ( limit )
      dup timer0@ -       ( limit delta )
   0< until               ( limit )
   drop
;
' (us) to us

\ Timing tools
variable timestamp
: t-update ;
: t(  ( -- )  timer0@ timestamp ! ;
: ))t  ( -- ticks )  timer0@  timestamp @  -  ;
: ))t-usecs  ( -- usecs )  ))t 2 d# 13 */  ;
: )t  ( -- )
   ))t-usecs  ( microseconds )
   push-decimal
   <#  u# u# u#  [char] , hold  u# u#s u#>  type  ."  us "
   pop-base
;
: t-msec(  ( -- )  timer2@ timestamp ! ;
: ))t-msec  ( -- msecs )  timer2@  timestamp @  -  ;
: )t-msec  ( -- )
   ))t-msec
   push-decimal
   <# u# u#s u#>  type  ." ms "
   pop-base
;

: t-sec(  ( -- )  t-msec(  ;
: ))t-sec  ( -- secs )  ))t-msec d# 1000 /  ;
: )t-sec  ( -- )
   ))t-sec
   push-decimal
   <# u# u#s u#>  type  ." s "
   pop-base
;

: .hms  ( seconds -- )
   d# 60 /mod   d# 60 /mod    ( sec min hrs )
   push-decimal
   <# u# u#s u#> type ." :" <# u# u# u#> type ." :" <# u# u# u#>  type
   pop-base
;
: t-hms(  ( -- )  t-sec(  ;
: )t-hms
   ))t-sec  ( seconds )
   .hms
;

: reschedule-tick  ( -- )
   timer2@ ms/tick + timer2-match0!
   1 timer2-icr!
;
: tick-interrupt  ( level -- )
   drop
   reschedule-tick
   check-alarm
;
: (set-tick-limit)  ( interval -- )
   to ms/tick
   reschedule-tick
   timer2-ier@ 1 or timer2-ier!
   ['] tick-interrupt d# 15 interrupt-handler!  \ d# 15 is the IRQ# for timer0 in the first timer block
   d# 15 enable-interrupt
;
' (set-tick-limit) to set-tick-limit

: timers-off  ( -- )
   0 timer0-ier!  0 timer1-ier!  0 timer2-ier!  \ Disable timer interrupts
   7 timer0-icr!  7 timer1-icr!  7 timer2-icr!  \ Clear pending interrupts
;

: can-idle?  ( -- flag )
   interrupts-enabled?  if
      d# 15 interrupt-enabled?
   else
      false
   then
;
code wfi   ( -- )  wfi   c;

defer do-lid
: lid-off ( -- )  ['] noop to do-lid  ;
lid-off

: safe-idle  ( -- )
   can-idle?  if  wfi  then
   do-lid
;
' safe-idle to stdin-idle

0 0  " d4014000" " /" begin-package
   " timer" name
   " mrvl,mmp-timer" +compatible
   my-address my-space  h# 100 reg
   d# 13 " interrupts" integer-property
   " /apbc" encode-phandle 9 encode-int encode+ " clocks" property
end-package
