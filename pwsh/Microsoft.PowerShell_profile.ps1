Set-Alias -Name touch -Value New-Item
Set-Alias -Name which -Value Get-Command

Set-Alias -Name vim -Value nvim

# init python venv with `venv`
Function new_venv {python -m venv .venv}
Set-Alias -Name venv -Value new_venv
# activate python venv with `activate`
Function activate_venv {.venv\Scripts\Activate.ps1}
Set-Alias -Name activate -Value activate_venv

# oh-my-posh theme
oh-my-posh init pwsh --config 'C:\Users\user\Documents\PowerShell\theme.omp.json' | Invoke-Expression
