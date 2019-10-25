define i32 @callee(i32 %a) {
  %ret = add i32 %a, %a   ; do the calculation
  ret i32 %ret            ; return it
}

define i32 @main() {
  %ret = call i32 @callee(i32 10)   ; call the function
  ret i32 %ret                      ; return the result
}
