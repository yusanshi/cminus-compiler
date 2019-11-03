; int main(){
;   int a;
;   int i;
;   a = 10;
;   i = 0;
;   while(i < 10){
;     i = i + 1;
;     a = a + i;
;   }
;   return a;
; }

; copy from PPT :)
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; define function main() which has no parameters and return i32
define i32 @main() {
entry:
  %a.memory = alloca i32, align 4 ; allocate memory for variable a
  %i.memory = alloca i32, align 4 ; allocate memory for variable i
  store i32 10, i32* %a.memory, align 4 ; assign 10 to a. 
  store i32 0, i32* %i.memory, align 4 ; assign 0 to i. 
  br label %while.judge ; begin "while" loop

while.judge:
  %0 = load i32, i32* %i.memory, align 4 ; load i to %0
  %cmp = icmp slt i32 %0, 10 ; compare i with 10
  br i1 %cmp, label %while.continue, label %while.end ; Jump!

while.continue:
  ; condition is ture. do what the body instructs
  %1 = load i32, i32* %i.memory, align 4 ; load i to %1
  %2 = add nsw i32 %1, 1 ; i++
  store i32 %2, i32* %i.memory, align 4 ; save new value to i
  %3 = load i32, i32* %a.memory, align 4 ; load a to %3
  ; Question: should I use %2 above directly or reload i to a unnamed temporary
  %4 = add nsw i32 %2, %3 ; a += i
  store i32 %4, i32* %a.memory, align 4 ; save new value to a
  br label %while.judge ; check condition

while.end:
  ; do nothing if %cmp is false

  ; in the end, return a
  %5 = load i32, i32* %a.memory, align 4 ; load a to %5
  ret i32 %5 ; return it
}