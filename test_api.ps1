# Test API script for driver registration endpoint

$uri = "https://masark-sa.com/api/driver-register"

$headers = @{
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

$body = @{
    first_name = "Test"
    last_name = ""
    username = "testdriver456"
    email = "testdriver456@example.com"
    user_type = "driver"
    contact_number = "5551234567"
    country_code = "+1"
    password = "password123"
    player_id = "test_player_id"
    user_detail = @{
        car_model = ""
        car_color = ""
        car_plate_number = ""
        car_production_year = ""
    }
    service_id = 1
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -ErrorAction Stop
    Write-Output "SUCCESS: API call successful"
    $response | ConvertTo-Json -Depth 5
}
catch {
    Write-Output "ERROR: API call failed"
    Write-Output "Status Code: $($_.Exception.Response.StatusCode.value__)"
    
    $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
    $errorContent = $streamReader.ReadToEnd()
    $streamReader.Close()
    
    Write-Output "Error Details:"
    Write-Output $errorContent
} 