# This script is used to import SAP license keys into SAP Java server using Telnet commands

# $Usage : .\sap_java_license_install.ps1

Write-Host " "

$pasnr = Read-Host "Enter the PAS (Dialog) instance number (e.g. 00). Press Enter Key if the default value is 00" -Default "00"
$username = Read-Host "Enter the Java NWA user (e.g., administrator)" -Default "administrator"
$password = Read-Host "Enter the password of Java NWA user (e.g., Password@123)"
$licenseFile = Read-Host "Enter the path and name of the license file generated from SAP support portal (e.g., f:\usr\sap\TST.txt)"

if ($pasnr -eq "") { $pasnr = "00" }
if ($username -eq "") { $username = "administrator" }

Write-Host " "

$hostname = "localhost"
$port = "5${pasnr}08"

try {
    # Establish a telnet connection to the SAP Java server
    $telnet = New-Object System.Net.Sockets.TcpClient($hostname, $port)
    $stream = $telnet.GetStream()
    $buffer = New-Object byte[] 1024

    function Write-Command {
        param (
            [string]$command
        )
        $data = [System.Text.Encoding]::ASCII.GetBytes("$command`r`n")
        $stream.Write($data, 0, $data.Length)
        Start-Sleep -Milliseconds 1000 # Small delay to ensure command is processed
        $response = Read-Response
        Write-Output $response
    }

    function Read-Response {
        $response = ""
        while ($stream.DataAvailable) {
            $readBytes = $stream.Read($buffer, 0, $buffer.Length)
            if ($readBytes -gt 0) {
                $response += [System.Text.Encoding]::ASCII.GetString($buffer, 0, $readBytes)
            }
        }
        return $response
    }

    # Login as the administrator
    Write-Command $username
    Write-Command $password

    # Ensure the login was successful
    $loginResponse = Read-Response
    Write-Output "Login Response: $loginResponse"

    if ($loginResponse -notmatch "User authentication failed") {
        # Execute the necessary commands
        Write-Command "jump 0"
        Write-Command "add licensing"
        Write-Command "INSTALL_LICENSE -file $licenseFile"
      
        # Verify the installed license
      
        $licenseResponse = Write-Command "LIST_LICENSES"
        Write-Output "License List Response: $licenseResponse"
        Write-Output "License installed successfully"
    } else {
        Write-Output "Login failed. Please check your credentials."
    }
} catch {
    Write-Error "An error occurred: $_"
} finally {
    # Close the telnet connection
    if ($stream) { $stream.Close() }
    if ($telnet) { $telnet.Close() }
    Write-Output "Connection closed."
}