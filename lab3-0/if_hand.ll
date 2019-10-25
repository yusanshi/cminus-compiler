define i32 @main() {
  %cond = icmp sgt i32 2, 1              ; compare the two numbers
  br i1 %cond, label %great, label %not  ; branching
great:         ; cond is true
  ret i32 1
not:           ; cond is false
  ret i32 0
}
