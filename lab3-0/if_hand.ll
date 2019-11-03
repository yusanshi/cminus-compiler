; int main(){
;   if(2 > 1)
;     return 1;
;   return 0;
; }

; copy from PPT :)
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; define function main() which has no parameters and return i32
define i32 @main() {
entry:
  ; compare 2 with 1. because 2 is greater than 1,
  ; this will set %cmp to true
  %cmp = icmp sgt i32 2, 1
  ; jump based on the value of %cmp
  br i1 %cmp, label %true, label %end
true:
  ret i32 1 ; return 1
  ; although this is unnecessory,
  ; but I didn't leave it out for logical correctness.
  br label %end
end:
  ret i32 0 ; return 0 in the end
}