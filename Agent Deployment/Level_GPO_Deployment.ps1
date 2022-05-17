#################################################
#
# Paste your Level installer command at "## PASTE LEVEL INSTALL STRING BELOW ##"
# This script checks that the target machine is a Windows Domain Controller, and then 
# creates a GPO backup file on the system drive at \temp\Level-Temp\.  A new GPO called
# "Install Level Agent" is created and linked at the root of the domain.  The contents
# of the GPO backup are imported into the new object, and the contents of the backup 
# is a single script that will run on all domain-joined computers at logon and logoff.
# If Level is not installed, the Level install command will be run. 
#
# This script should only be run once on a single domain controller per Active 
# Directory environment!
#
#################################################

# Check for Active Directory and halt if not present
$service = Get-Service -Name ntds -ErrorAction SilentlyContinue
if($null -eq $service)
{
    Write-Error "This computer is not a domain controller.  Please run this script on a domain controller."
} else {
# Create the Level logon script in "\SYSVOL\domain\scripts\Install_Level_Agent.ps1"
$Net_Share_Path = $env:systemroot + '\SYSVOL\domain\scripts\Install_Level_Agent.ps1'
Set-Content $Net_Share_Path @'
# Check if the Level service is already present 
$service = Get-Service -Name Level -ErrorAction SilentlyContinue
$hostname = hostname
New-EventLog -LogName Application -Source "Level"
if($service -eq $null) {
    # Level is not installed. Paste your install script from the Level app below so it can be installed
    ########### PASTE LEVEL INSTALL STRING BELOW ##############
Paste Level install command here
    ########### PASTE LEVEL INSTALL STRING ABOVE ##############

    Write-EventLog -LogName "Application" -Source "Level" -EventID 100 -EntryType Information -Message "Level was successfully installed.  Please check the agent page at https://app.level.io and look for the agent called $hostname"
} else {
    # Level is already installed, halt.
    Write-EventLog -LogName "Application" -Source "Level" -EventID 101 -EntryType Information -Message "The Level install GPO ran successfully, but Level is already installed.  Look for the agent called $hostname"
}
'@

# Create the group policy backup folders and files prior to importing 
    $GPO_path = $env:systemdrive + '\temp\Level-Temp\{6FCFE453-2E93-48CE-825A-A3EF59ABA1B2}\DomainSysvol\GPO\Machine\Scripts'
    New-Item $GPO_path -ItemType Directory
    
# Create Backup.xml
    $Backup_xml_path = $env:systemdrive + '\temp\Level-Temp\{6FCFE453-2E93-48CE-825A-A3EF59ABA1B2}\Backup.xml'
    Set-Content $Backup_xml_path @'
<?xml version="1.0" encoding="utf-8"?>
<GroupPolicyBackupScheme bkp:version="2.0" bkp:type="GroupPolicyBackupTemplate" xmlns:bkp="http://www.microsoft.com/GroupPolicy/GPOOperations" xmlns="http://www.microsoft.com/GroupPolicy/GPOOperations">
    <GroupPolicyObject><FilePaths/><GroupPolicyCoreSettings><ID><![CDATA[{1041B92A-930A-46F9-8942-CA7AB9080D33}]]></ID><Domain></Domain><SecurityDescriptor></SecurityDescriptor><DisplayName><![CDATA[Install Level Agent]]></DisplayName><Options></Options><UserVersionNumber></UserVersionNumber><MachineVersionNumber></MachineVersionNumber><MachineExtensionGuids><![CDATA[[{42B5FAAE-6536-11D2-AE5A-0000F87571E3}{40B6664F-4972-11D1-A7CA-0000F87571E3}]]]></MachineExtensionGuids><UserExtensionGuids/><WMIFilter/></GroupPolicyCoreSettings>
        <GroupPolicyExtension bkp:ID="{42B5FAAE-6536-11d2-AE5A-0000F87571E3}" bkp:DescName="Scripts">
            <FSObjectFile bkp:Path="%GPO_MACH_FSPATH%\Scripts\PSscripts.ini" bkp:Location="DomainSysvol\GPO\Machine\Scripts\PSscripts.ini"/>
        </GroupPolicyExtension>
    </GroupPolicyObject>
</GroupPolicyBackupScheme>
'@

# Create bkupInfo.xml
    $bkupInfo_xml_path = $env:systemdrive + '\temp\Level-Temp\{6FCFE453-2E93-48CE-825A-A3EF59ABA1B2}\bkupInfo.xml'
    Set-Content $bkupInfo_xml_path @'
    <BackupInst xmlns="http://www.microsoft.com/GroupPolicy/GPOOperations/Manifest"><GPOGuid><![CDATA[{1041B92A-930A-46F9-8942-CA7AB9080D33}]]></GPOGuid><GPODomain><![CDATA[level.local]]></GPODomain><GPODomainGuid><![CDATA[{5ce50db9-5895-43f4-ab58-fb8f5811a29b}]]></GPODomainGuid><GPODomainController><![CDATA[Server.level.local]]></GPODomainController><BackupTime><![CDATA[2022-05-14T21:28:22]]></BackupTime><ID><![CDATA[{6FCFE453-2E93-48CE-825A-A3EF59ABA1B2}]]></ID><Comment><![CDATA[]]></Comment><GPODisplayName><![CDATA[Install Level Agent]]></GPODisplayName></BackupInst>
'@

# Create PSscripts.ini
$DomainName = Get-ADDomain | Select-Object -ExpandProperty Forest
$PSscripts_ini_path = $env:systemdrive + '\temp\Level-Temp\{6FCFE453-2E93-48CE-825A-A3EF59ABA1B2}\DomainSysvol\GPO\Machine\Scripts\PSscripts.ini'
    Set-Content $PSscripts_ini_path @"

[Startup]
0CmdLine=\\$DomainName\SysVol\$DomainName\scripts\Install_Level_Agent.ps1
0Parameters=Set-ExecutionPolicy Bypass
[Shutdown]
0CmdLine=\\$DomainName\SysVol\$DomainName\scripts\Install_Level_Agent.ps1
0Parameters=Set-ExecutionPolicy Bypass
"@

# Create a new GPO "Install Level Agent" and link it to the root of the domain
$DistinguishedName = Get-ADDomain | Select-Object -ExpandProperty DistinguishedName
New-GPO -Name "Install Level Agent" | New-GPLink -Target $DistinguishedName

# Import the GPO settings from the backup files (above) into the new GPO
$GPO_Backup_Location = $env:systemdrive + '\temp\Level-Temp\'
Import-GPO -BackupGpoName "Install Level Agent" -Path $GPO_Backup_Location -TargetName "Install Level Agent"
}