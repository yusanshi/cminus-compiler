define i32 @main() {
  %a = alloca i32           ; allocate memory for `a`
  store i32 1, i32* %a      ; store value 1 to `a`
  %ret = load i32, i32* %a  ; get the value of `a`
  ret i32 %ret              ; return it
}
