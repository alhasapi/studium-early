# Windows installation

Install Luanti from [luanti.org](https://www.luanti.org/), close it, then open PowerShell in the Studium directory and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
```

The installer checks `%APPDATA%\Luanti\mods` and `%APPDATA%\Minetest\mods`. Start Luanti, select a world, and run `/edu_menu`.
