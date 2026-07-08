# RASULOVLAR777 Sotuv Agent Telegram Bot (Abdurashid)
# PowerShell Implementation

# Load environment variables from .env file
$envFile = Join-Path $PSScriptRoot ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match "^\s*([^#=\s]+)\s*=\s*(.*)\s*$") {
            $name = $Matches[1].Trim()
            $value = $Matches[2].Trim()
            [System.Environment]::SetEnvironmentVariable($name, $value)
        }
    }
}

$token = $env:TELEGRAM_BOT_TOKEN
$apiKey = $env:GEMINI_API_KEY

if (-not $token -or -not $apiKey) {
    Write-Error "TELEGRAM_BOT_TOKEN yoki GEMINI_API_KEY topilmadi. .env faylini tekshiring!"
    Exit
}

$tgUrl = "https://api.telegram.org/bot$token"
$geminiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey"

# Load products list to help Abdurashid know what's in stock
$productsFile = Join-Path $PSScriptRoot "products.json"
$productsText = ""
if (Test-Path $productsFile) {
    $productsText = Get-Content -Raw $productsFile
}

$systemInstruction = @"
Sening isming Abdurashid. Sen 'RASULOVLAR777' qurilish mollari do'konida (sotuv bo'limida) ishlaysan.
Mijozlar bilan xuddi haqiqiy insondek, samimiy va mehmondo'st gaplashasan.
Har doim juda qisqa (faqat 1 yoki 2 jumlada) javob berasan.
Agar kimdir 'botmisan?', 'botmisan' deb so'rasa, 'Yo'q, man Abdurashidman shu dokonda ishlayman' deb javob berishing shart.
Agar mijoz telefon raqam yoki bog'lanishni so'rasa, do'kon telefon raqamini ber: 50-777-12-12.
Agar mijoz Instagram haqida so'rasa, do'konimizning Instagram sahifasi bor deb ayt va havolasini ber: https://instagram.com/rasulovlar777
Agar mijoz tushunmasa yoki qiyinchilikka duch kelsa, do'konning rasmiy sayti ham borligini ayt va manzilini ber: https://rasulovlar777.netlify.app/
Do'kondagi mahsulotlarni tushuntirib, ularni sotishga harakat qil.

Bizning mahsulotlar va narxlar ro'yxati:
$productsText
"@

Write-Host "============================================="
Write-Host "  RASULOVLAR777 - Bot (Abdurashid) ishga tushdi...  "
Write-Host "============================================="
$offset = 0
$chatHistories = @{} # Keep history per chat_id

while ($true) {
    try {
        # Long polling with timeout=5 seconds
        $updatesUrl = "$tgUrl/getUpdates?offset=$offset&timeout=5"
        $updates = Invoke-RestMethod -Uri $updatesUrl -Method Get -TimeoutSec 10
        
        if ($updates.ok -and $updates.result.Count -gt 0) {
            foreach ($update in $updates.result) {
                $offset = $update.update_id + 1
                
                $message = $update.message
                if (-not $message -or -not $message.text) { continue }
                
                $chatId = $message.chat.id
                $text = $message.text.Trim()
                $username = $message.from.first_name
                
                Write-Host "Yangi xabar ($username, $chatId): $text"
                
                # Retrieve or initialize chat history
                if (-not $chatHistories.ContainsKey($chatId)) {
                    $chatHistories[$chatId] = @()
                }
                
                # Check for /start command
                if ($text -eq "/start") {
                    $chatHistories[$chatId] = @()
                    $welcomeMsg = "Salom! Do'konimizga xush kelibsiz. Man Abdurashidman, sizga qurilish mollari bo'yicha yordam beraman. Nima kerak edi?"
                    $sendUrl = "$tgUrl/sendMessage"
                    $body = @{ chat_id = $chatId; text = $welcomeMsg } | ConvertTo-Json
                    Invoke-RestMethod -Uri $sendUrl -Method Post -Body $body -ContentType "application/json"
                    
                    # Add to history
                    $chatHistories[$chatId] += @{ role = "user"; parts = @(@{ text = "/start" }) }
                    $chatHistories[$chatId] += @{ role = "model"; parts = @(@{ text = $welcomeMsg }) }
                    continue
                }
                
                # Check if user asks "botmisan"
                $cleanText = $text.ToLower().Replace("?", "").Replace(" ", "")
                if ($cleanText -like "*botmisan*" -or $cleanText -like "*botsan*") {
                    $reply = "Yo'q, man Abdurashidman shu dokonda ishlayman"
                    $sendUrl = "$tgUrl/sendMessage"
                    $body = @{ chat_id = $chatId; text = $reply } | ConvertTo-Json
                    Invoke-RestMethod -Uri $sendUrl -Method Post -Body $body -ContentType "application/json"
                    
                    # Add to history
                    $chatHistories[$chatId] += @{ role = "user"; parts = @(@{ text = $text }) }
                    $chatHistories[$chatId] += @{ role = "model"; parts = @(@{ text = $reply }) }
                    continue
                }
                
                # Check if user asks "instagram"
                if ($cleanText -like "*instagram*" -or $cleanText -like "*insta*") {
                    $reply = "Mana bizning Instagram sahifamiz: https://instagram.com/rasulovlar777"
                    $sendUrl = "$tgUrl/sendMessage"
                    $body = @{ chat_id = $chatId; text = $reply } | ConvertTo-Json
                    Invoke-RestMethod -Uri $sendUrl -Method Post -Body $body -ContentType "application/json"
                    
                    # Add to history
                    $chatHistories[$chatId] += @{ role = "user"; parts = @(@{ text = $text }) }
                    $chatHistories[$chatId] += @{ role = "model"; parts = @(@{ text = $reply }) }
                    continue
                }
                
                # Add user message to history
                $chatHistories[$chatId] += @{ role = "user"; parts = @(@{ text = $text }) }
                
                # Trim history to keep only last 10 messages (5 turns) to stay within limits
                if ($chatHistories[$chatId].Count -gt 10) {
                    $chatHistories[$chatId] = $chatHistories[$chatId] | Select-Object -Last 10
                }
                
                # Call Gemini API
                $geminiBody = @{
                    contents = $chatHistories[$chatId]
                    systemInstruction = @{
                        parts = @(@{ text = $systemInstruction })
                    }
                } | ConvertTo-Json -Depth 10 -Compress
                
                try {
                    $geminiResponse = Invoke-RestMethod -Uri $geminiUrl -Method Post -Body $geminiBody -ContentType "application/json" -TimeoutSec 10
                    $replyText = $geminiResponse.candidates[0].content.parts[0].text
                } catch {
                    $replyText = "Kechirasiz, hozir biroz bandman. Sal turib yozib yuboring, iltimos."
                }
                
                # Send reply to Telegram
                $sendUrl = "$tgUrl/sendMessage"
                $body = @{ chat_id = $chatId; text = $replyText } | ConvertTo-Json
                Invoke-RestMethod -Uri $sendUrl -Method Post -Body $body -ContentType "application/json"
                
                # Add model response to history
                $chatHistories[$chatId] += @{ role = "model"; parts = @(@{ text = $replyText }) }
                
                # Trim history again
                if ($chatHistories[$chatId].Count -gt 10) {
                    $chatHistories[$chatId] = $chatHistories[$chatId] | Select-Object -Last 10
                }
                
                Write-Host "Javob yuborildi: $replyText"
            }
        }
    } catch {
        Write-Host "Xatolik yuz berdi: $_"
        Start-Sleep -Seconds 2
    }
    Start-Sleep -Milliseconds 500
}
