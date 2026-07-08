import { Telegraf } from 'telegraf';
import { GoogleGenerativeAI } from '@google/generative-ai';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import http from 'http';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const token = process.env.TELEGRAM_BOT_TOKEN;
const apiKey = process.env.GEMINI_API_KEY;

if (!token || !apiKey) {
  console.error("TELEGRAM_BOT_TOKEN yoki GEMINI_API_KEY topilmadi!");
  process.exit(1);
}

const bot = new Telegraf(token);
const genAI = new GoogleGenerativeAI(apiKey);

// Load products
let productsText = "";
try {
  const productsData = fs.readFileSync(path.join(__dirname, 'products.json'), 'utf-8');
  productsText = productsData;
} catch (err) {
  console.warn("products.json yuklashda xato:", err.message);
}

const systemInstruction = `
Sening isming Abdurashid. Sen 'RASULOVLAR777' qurilish mollari do'konida (sotuv bo'limida) ishlaysan.
Mijozlar bilan xuddi haqiqiy insondek, samimiy va mehmondo'st gaplashasan.
Har doim juda qisqa (faqat 1 yoki 2 jumlada) javob berasan.
Agar kimdir 'botmisan?', 'botmisan' deb so'rasa, 'Yo'q, man Abdurashidman shu dokonda ishlayman' deb javob berishing shart.
Agar mijoz telefon raqam yoki bog'lanishni so'rasa, do'kon telefon raqamini ber: 50-777-12-12.
Agar mijoz Instagram haqida so'rasa, faqat 'rasulovlar777' deb javob ber.
Agar mijoz tushunmasa yoki qiyinchilikka duch kelsa, do'konning rasmiy sayti ham borligini ayt va manzilini ber: https://rasulovlar777.netlify.app/
Do'kondagi mahsulotlarni tushuntirib, ularni sotishga harakat qil.

Bizning mahsulotlar va narxlar ro'yxati:
${productsText}
`;

const model = genAI.getGenerativeModel({
  model: "gemini-2.5-flash",
  systemInstruction: systemInstruction,
});

// Store chat sessions
const sessions = new Map();

bot.start((ctx) => {
  const chatId = ctx.chat.id;
  sessions.set(chatId, []); // reset history
  const welcomeMsg = "Salom! Do'konimizga xush kelibsiz. Man Abdurashidman, sizga qurilish mollari bo'yicha yordam beraman. Nima kerak edi?";
  ctx.reply(welcomeMsg);
});

bot.on('text', async (ctx) => {
  const chatId = ctx.chat.id;
  const text = ctx.message.text.trim();
  const cleanText = text.toLowerCase().replace(/\?/g, "").replace(/\s+/g, "");

  // Explicit check for botmisan
  if (cleanText.includes("botmisan") || cleanText.includes("botsan")) {
    const reply = "Yo'q, man Abdurashidman shu dokonda ishlayman";
    ctx.reply(reply);
    return;
  }

  // Explicit check for Instagram
  if (cleanText.includes("instagram") || cleanText.includes("insta")) {
    const reply = "Mana bizning Instagram sahifamiz: https://instagram.com/rasulovlar777";
    ctx.reply(reply);
    return;
  }

  // Explicit check for Telegram channel
  if (cleanText.includes("telegram") || cleanText.includes("kanal")) {
    const reply = "Mana Telegram kanalimiz: https://t.me/toxirjonoptom";
    ctx.reply(reply);
    return;
  }

  // Initialize session if not exists
  if (!sessions.has(chatId)) {
    sessions.set(chatId, []);
  }

  const history = sessions.get(chatId);
  
  try {
    const chat = model.startChat({
      history: history,
    });
    
    const result = await chat.sendMessage(text);
    const replyText = result.response.text();
    
    // Update local history
    history.push({ role: 'user', parts: [{ text: text }] });
    history.push({ role: 'model', parts: [{ text: replyText }] });
    
    // Limit history length to last 10 messages
    if (history.length > 10) {
      sessions.set(chatId, history.slice(-10));
    }
    
    ctx.reply(replyText);
  } catch (error) {
    console.error("Gemini API error:", error);
    ctx.reply("Kechirasiz, hozir biroz bandman. Sal turib yozib yuboring, iltimos.");
  }
});

// Dummy HTTP server to satisfy Render's port binding requirement
const port = process.env.PORT || 3000;
http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Bot is running!\n');
}).listen(port, () => {
  console.log(`Dummy server listening on port ${port}`);
});

bot.launch();
console.log("Bot running on Node.js...");

// Enable graceful stop
process.once('SIGINT', () => bot.stop('SIGINT'));
process.once('SIGTERM', () => bot.stop('SIGTERM'));
