# Lab 1
<details>
<summary>Environment</summary>

    $ uname -a
    Linux manjaro 4.19.69-1-MANJARO #1 SMP PREEMPT Thu Aug 29 08:51:46 UTC 2019 x86_64 GNU/Linux

    $ lsb_release -a
    LSB Version:    n/a
    Distributor ID: ManjaroLinux
    Description:    Manjaro Linux
    Release:        18.1.0
    Codename:       Juhraya

    $ flex --version
    flex 2.6.4

    $ gcc --version
    gcc (GCC) 9.1.0

</details>

## Design
Speaking of flex rules design, all of them are quite easy except for `COMMENT`. For keywords, operators and end of line, matching the string literal is enough, and don't forget `pos_start` and `pos_end`, which I use a macro `BUMP_POS(n)` to change. The regex for blanks, numbers and identifiers are very trivial.

Designing the regex of `COMMENT` took me a large portion of lab time. Here I will do a simple explanation of the regex.


     regular char (not '/' or '*')    prevent '/' after '*'
                  |                           |
                  v                           v
         \/\*  ( [^*/]   |   [^*]\/+   |   \*+[^/] )*   \*+\/
          ^                     ^                         ^
          |                     |                         |
    starting sign    prevent '*' before '/'          ending sign

## Problems encountered
### `\/`

### comment thing
