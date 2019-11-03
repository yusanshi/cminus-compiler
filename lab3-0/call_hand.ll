; int callee(int a){
;   return 2 * a;
; }
; int main(){
;   return callee(10);
; }

; copy from PPT :)
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; define function callee() which takes an i32 value 
; as parameter and return an i32 value
define i32 @callee(i32 %a) {
entry:
  ; multipy %a with 2 and save to %0, nsw means “No Signed Wrap”, 
  ; the result value of the mul is a poison value if signed overflow occurs.
  %0 = mul nsw i32 %a, 2
  ret i32 %0 ; return it
}

; define function main() which has no parameters 
; and return an i32 value
define i32 @main()  {
entry:
  %0 = call i32 @callee(i32 10) ; call callee(), passing parameter: an i32 10.
  ret i32 %0
}

