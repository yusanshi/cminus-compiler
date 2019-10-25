define i32 @main() {
  ; define variables
  %a = alloca i32
  %i = alloca i32
  store i32 0, i32* %i
  store i32 10, i32* %a
  br label %check

  ; while (i < 10) {
check:
  %i-load = load i32, i32* %i
  %cmp = icmp slt i32 %i-load, 10
  br i1 %cmp, label %do, label %done
do:
  ; i = i + 1
  %i-add = add i32 %i-load, 1
  store i32 %i-add, i32* %i
  ; a = a + i
  %a-load = load i32, i32* %a
  %a-add = add i32 %i-add, %a-load
  store i32 %a-add, i32* %a
  br label %check
done:
  ; }  // while
  ; return a
  %ret = load i32, i32* %a
  ret i32 %ret
}
