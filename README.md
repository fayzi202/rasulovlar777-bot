# RASULOVLAR777 Qurilish Mollari Do'koni Sotuv Agent Bot (Abdurashid)

Ushbu Telegram bot "RASULOVLAR777" qurilish mollari do'koni uchun sotuv agenti bo'lib xizmat qiladi. Bot sun'iy intellekt (Gemini 2.5 Flash) yordamida mijozlar bilan insondek, samimiy muloqot qiladi va mahsulotlar sotuvini amalga oshiradi.

## Imkoniyatlari

- **Abdurashid Persona**: Bot har doim do'konda ishlaydigan Abdurashid ismli sotuvchi xodim sifatida insondek muloqot qiladi.
- **Qisqa Javoblar**: Doimo qisqa va aniq (1-2 jumla) javob beradi.
- **Botmisan So'roviga**: "Yo'q, man Abdurashidman shu dokonda ishlayman" deb javob beradi.
- **Instagram**: "instagram bormi" deb so'ralganda to'g'ridan-to'g'ri `rasulovlar777` deb javob beradi.
- **Aloqa**: Bog'lanish yoki telefon raqam so'ralsa, `50-777-12-12` raqamini taqdim etadi.
- **Rasmiy Sayt**: Mijoz tushunmasa yoki qiyinchilikka duch kelsa, sayt havolasini yuboradi: `https://rasulovlar777.netlify.app/`.
- **Mahsulotlar Katalogi**: Do'kondagi mahsulotlar ro'yxati (`products.json`) asosida narxlarni aytib beradi va tavsiya qiladi.

## Ishga tushirish (Windows PowerShell)

Botni ishga tushirish uchun kompyuterga Node.js yoki Python o'rnatish shart emas. U Windows tizimidagi standart **PowerShell** orqali ishlaydi.

1. Loyihani yuklab oling.
2. Loyiha papkasida `.env` nomli fayl yarating va quyidagi ma'lumotlarni yozing:
   ```env
   TELEGRAM_BOT_TOKEN=Sizning_Telegram_Bot_Tokeningiz
   GEMINI_API_KEY=Sizning_Gemini_API_Kalitingiz
   ```
3. PowerShell terminalini ochib, loyiha papkasiga o'ting va quyidagi buyruqni ishga tushiring:
   ```powershell
   powershell -ExecutionPolicy Bypass -File bot.ps1
   ```

## Texnologiyalar
- **PowerShell** (Skript va Telegram API ulanishi)
- **Google Gemini 2.5 Flash API** (Muloqot va aqlli sotuv mantiqi)
- **Telegram Bot API** (Mijozlar bilan aloqa)
