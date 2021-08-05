使用Named_Pipe来传输，达到绕过cs 1mb的限制

[Named Pipe Server Using Completion Routines](https://docs.microsoft.com/en-us/windows/win32/ipc/named-pipe-server-using-completion-routines)

![](https://github.com/dust-life/test/blob/main/test1.png)
![](https://github.com/dust-life/test/blob/main/test.png)

因为可能会存在cna一键化不稳定的情况，可能会导致传输数据有问题，建议dllspawn和upload_raw分开执行
