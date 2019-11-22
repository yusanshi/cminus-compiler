# 团队工作记录
## 学习过程

## 讨论 1
- 时间：2019-11-08 下午
- 地点：西区图书馆
- 参与者：wrc, yl

### 代码风格
- 变量名 `snake_case`
- 使用 `clang-format` 自动格式化
- 不要格式化助教的代码
- 引用属性使用 `this->`

### Git
- Commit message
    - 首字母大写
    - 不要写 `Update filename`（具体一点）
- Log
    - 记得 `commit` 之前 `pull`，要是忘记了（假设只需回退一个 commit）：
    ```bash
    git --no-pager log -1  # 记住 hash
    git reset --hard HEAD^
    git pull
    git cherry-pick <hash>
    ```
- 不要动不需要动的文件，`git commit` 之前注意一下

### 问题
1. module, context 在哪里？

    `this->module`, `this->context`

2. unique_ptr

    使用 `std::unique_ptr::get` 获得指针

## 讨论 2
- 时间：2019-11-15 下午
- 地点：西区图书馆
- 参与者：wrc, yl

1. 把 `syntax_fun_declaration` 和 `syntax_var_declaration` 写完了；
2. 研究了一下 `Scope` 的用法
    1. 进入一个 compound statement 时 `enter`，退出时 `exit`；
    2. 声明变量时将它的 `id` 和 `Value *` `push` 进 scope；
    3. 寻找 `id` 时使用 `find`。因为 `find` 方法自内而外寻找，所以可以找到正确的 `Value *`。
3. 由于函数间的依赖关系到真正开始写的时候才会比较清楚，所以决定不具体分工，两个人分时作业。


## 其他讨论
- 时间：2019-11-16 -- 2019-11-22
- 地点：云上/教室等
- 参与者：wrc, yl

1. 全局变量的作用：`visit` 函数传参数、返回值（必须要用全局变量因为无法修改 `visit` 函数的签名）；
2. `if` 语句对应的 basic block 顺序问题；
    - 调整 `BasicBlock::Create` 的顺序（solved in `42bc749`）。
3. 如何编译在 `if.end` 后没有 statement 的程序；
    - 使用全局变量 `last_return` 跟踪一个 statement 的最后一句是否一定返回，如果 if 语句两个分支的最后一句都已经返回就不再 `br` 到 `if.end` 并不将 `if.end` 插入当前函数。

## 讨论 3
- 时间：2019-11-23 下午
- 地点：西区图书馆
- 参与者：wrc, yl

1. 解决了数组做为函数参数可能导致的问题；
2. 完成收集测试样例；
3. 完成报告的框架。
