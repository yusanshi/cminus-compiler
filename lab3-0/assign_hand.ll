; int main(){
;   int a;
;   a = 1;
;   return a;
; }

; copy from PPT :)
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; define function main() which has no parameters and return i32
define i32 @main() {
entry:
  %a.memory = alloca i32, align 4 ; allocate memory for variable a
  ; store 1 to pointer (address) of variable a. 
  ; namely assign 1 to a. 
  store i32 1, i32* %a.memory, align 4
  %0 = load i32, i32* %a.memory, align 4 ; load from pointer of a to unnamed temporary
  ret i32 %0 ; return it
}