Set-ExecutionPolicy RemoteSigned -Scope Process -Force; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iwr -uri https://github.com/levelsoftware/examples/raw/main/Diagnostics/desktopctl.exe -outfile c:\temp\desktopctl.exe
C:\temp\desktopctl.exe
