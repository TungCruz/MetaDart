$ErrorActionPreference = 'Stop'
$env:GOOGLE_APPLICATION_CREDENTIALS = 'C:\Users\PC\.firebase-secrets\metacinema-admin.json'
$env:ASPNETCORE_URLS = 'http://0.0.0.0:5055'

dotnet run --project "$PSScriptRoot\backend\MetaCinema.AdminApi\MetaCinema.AdminApi.csproj"
