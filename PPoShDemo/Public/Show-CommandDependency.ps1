function Show-CommandDependency {
    <#
      .SYNOPSIS
      Function that uses graphviz to create a graph of function dependancies.
  
      .DESCRIPTION
      Requires GraphViz and PSGrapsh modules to create a grapshical representation of references in functions.
  
      .PARAMETER Path
      Path with folders with functions to search.
  
      .PARAMETER Folders
      Which folders should be included in recursive search for functions
  
      .PARAMETER DestinationFilePath
      FileName where grapsh should be generated.
  
      .PARAMETER HideGraph
      If set will not show graph after it's generated.
  
      .EXAMPLE
      Show-CommandDependency.ps1 -Path Value -Folders Value -DestinationFilePath Value -HideGraph
      Describe what this call does
    #>
  
  
  
    [CmdletBinding()]
    Param(
      [Parameter(Mandatory = $true, HelpMessage = 'Source Path (module) were functions are stored with functions')]
      [ValidateNotNullOrEmpty()]
      [ValidateScript({Test-Path -Path $_ -PathType Container})]
      [string]
      $Path,
  
      [Parameter(Mandatory = $false, HelpMessage = 'Folders to include for search')]
      [ValidateNotNullOrEmpty()]
      [string[]]
      $Folders = @('Public', 'Private', 'Internal'),
  
      [Parameter(Mandatory = $false, HelpMessage = 'Destination Path for graph')]
      [ValidateNotNullOrEmpty()]
      [string]
      $DestinationFilePath,
  
      [Parameter(Mandatory = $false, HelpMessage = 'some help')]
      [switch]
      $HideGraph
    )
  
    process { 
      $exportParams = @{
        ShowGraph = $true
      }
  
      if ($PSBoundParameters.ContainsKey('HideGraph')) {
        $exportParams.ShowGraph = $false
      }
  
      if ($PSBoundParameters.ContainsKey('DestinationFilePath')) {
        $exportParams.DestinationPath = $DestinationFilePath
      }
  
      graph CommandFlow {
  
              
        $scripts = @{}
        $folderstoTest = @()
  
        if ($Folders) { 
          foreach ($folder in $Folders) { 
            $testFolder = Join-Path -Path $Path -ChildPath $folder
            if (Test-Path -Path $testFolder) { 
              $folderstoTest += $testFolder
            }
          } 
        }  
        Get-ChildItem -Path $folderstoTest -recurse -include '*.ps1' |
        ForEach-Object -Process {
          $scripts[$PSItem.BaseName] = $PSItem.FullName
        }
  
        $scriptNames = $scripts.Keys | Sort-Object
        ForEach ($script in $scriptNames) {
  
          node $script
          $contents = Get-Content -Path $scripts[$script] -ErrorAction Stop
          $errors = $null
          $commands = ([System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors) |
          Where-Object -FilterScript {$PSItem.Type -eq 'Command'}).Content
          ForEach ($command in $commands) {
            If ($scripts[$command]) {
              Edge  $script -To $command
            }
          }
        }
      } | Export-PSGraph @exportParams
    }
  }