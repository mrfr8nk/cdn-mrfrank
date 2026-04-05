import { detectIntent } from "../utils/intentDetector.js";
import { isOnCooldown } from "../utils/cooldown.js";
import { trackUser, getAllUsers, getTextFromMessage } from "../utils/helpers.js";
import { chat, analyzeImage, summarizeText, setLastResponse, getLastResponse } from "../services/aiService.js";
import { generatePDF } from "../services/pdfService.js";
import { downloadImage } from "../services/imageService.js";
import { downloadDocument, extractTextFromBuffer } from "../services/documentService.js";
import { logger, logActivity } from "../utils/logger.js";
import fs from "fs";
import path from "path";

const ADMIN_NUMBER = "263719647303";

function getMenu() {
  return `╔══════════════════════╗
║    🎓 *FUNDO AI*     ║
╚══════════════════════╝

Your friendly educational assistant!

📚 *What I Can Do:*

💬 *Chat* — Just type anything! I'll help you learn.
📷 *Image Analysis* — Send me an image and I'll explain it.
📄 *Document Analysis* — Send a document for a summary.
✍️ *Content Generation* — Ask me to write essays, notes, or assignments.
📑 *PDF Export* — Say "convert to pdf" to save my last response as PDF.
📝 *Summarize* — Say "summarize this" after sending content.

🎯 *Tips:*
• Just type naturally — no commands needed!
• Ask about any subject: math, science, history, etc.
• Request heritage-based projects (HBC curriculum)

━━━━━━━━━━━━━━━━━━━━━
_Created by Darrell Mucheri_
_Powered by Fundo AI_ 🤖`;
}

function getAdminPanel(users) {
  const userList = Object.values(users);
  const totalMessages = userList.reduce((sum, u) => sum + (u.messageCount || 0), 0);
  const activeRecently = userList.filter((u) => {
    if (!u.lastActive) return false;
    return Date.now() - new Date(u.lastActive).getTime() < 24 * 60 * 60 * 1000;
  }).length;

  return `╔══════════════════════╗
║   🔐 *ADMIN PANEL*   ║
╚══════════════════════╝

📊 *Bot Statistics:*

👥 Total Users: *${userList.length}*
💬 Total Messages: *${totalMessages}*
🟢 Active (24h): *${activeRecently}*

🕐 Server Time: ${new Date().toLocaleString()}

━━━━━━━━━━━━━━━━━━━━━
*Admin Commands:*
• stats — View statistics
• users — List users
• broadcast <message> — Send to all users

_Fundo AI Admin - Created by Darrell Mucheri_`;
}

export async function handleMessage(sock, msg) {
  const jid = msg.key.remoteJid;
  if (!jid) return;

  // Cooldown check
  if (isOnCooldown(jid)) {
    await sock.sendMessage(jid, {
      text: "⏳ Please wait a moment before sending another message!",
    });
    return;
  }

  // Track user
  trackUser(jid);

  const text = getTextFromMessage(msg);
  const hasImage = !!msg.message?.imageMessage;
  const hasDocument = !!msg.message?.documentMessage;

  logActivity("message", { from: jid, text: text?.substring(0, 100), hasImage, hasDocument });

  // Handle image messages
  if (hasImage) {
    await sock.sendPresenceUpdate("composing", jid);
    try {
      const buffer = await downloadImage(msg);
      const caption = msg.message.imageMessage.caption || "";
      const response = await analyzeImage(jid, buffer, caption);
      setLastResponse(jid, response);
      await sock.sendMessage(jid, { text: response });
    } catch (err) {
      logger.error("Image handling error: " + err.message);
      await sock.sendMessage(jid, { text: "⚠️ I couldn't process that image. Please try again." });
    }
    return;
  }

  // Handle document messages
  if (hasDocument) {
    await sock.sendPresenceUpdate("composing", jid);
    try {
      const buffer = await downloadDocument(msg);
      const extracted = extractTextFromBuffer(buffer);
      if (extracted) {
        const summary = await summarizeText(extracted);
        setLastResponse(jid, summary);
        await sock.sendMessage(jid, { text: `📄 *Document Summary:*\n\n${summary}` });
      } else {
        await sock.sendMessage(jid, { text: "⚠️ I couldn't read this document format. Try sending a text-based file." });
      }
    } catch (err) {
      logger.error("Document handling error: " + err.message);
      await sock.sendMessage(jid, { text: "⚠️ I couldn't process that document. Please try again." });
    }
    return;
  }

  if (!text) return;

  // Detect intent
  const { intent, isAdmin, extra } = detectIntent(text, jid);

  await sock.sendPresenceUpdate("composing", jid);

  switch (intent) {
    case "menu": {
      await sock.sendMessage(jid, { text: getMenu() });
      break;
    }

    case "convert_pdf": {
      const lastResp = getLastResponse(jid);
      if (!lastResp) {
        await sock.sendMessage(jid, { text: "📑 I don't have a previous response to convert. Ask me something first!" });
        break;
      }
      try {
        const filePath = await generatePDF(lastResp, "Fundo AI Response");
        await sock.sendMessage(jid, {
          document: fs.readFileSync(filePath),
          mimetype: "application/pdf",
          fileName: "Fundo_AI_Response.pdf",
          caption: "📑 Here's your PDF!\n_Fundo AI - Created by Darrell Mucheri_",
        });
        fs.unlinkSync(filePath);
      } catch (err) {
        logger.error("PDF generation error: " + err.message);
        await sock.sendMessage(jid, { text: "⚠️ Failed to generate PDF. Please try again." });
      }
      break;
    }

    case "summarize": {
      const lastResp2 = getLastResponse(jid);
      if (!lastResp2) {
        await sock.sendMessage(jid, { text: "📝 Send me some content first, then ask me to summarize!" });
        break;
      }
      const summary = await summarizeText(lastResp2);
      setLastResponse(jid, summary);
      await sock.sendMessage(jid, { text: `📝 *Summary:*\n\n${summary}` });
      break;
    }

    case "explain_image": {
      await sock.sendMessage(jid, { text: "📷 Please send me an image and I'll analyze it for you!" });
      break;
    }

    // Admin commands
    case "admin_panel": {
      const users = getAllUsers();
      await sock.sendMessage(jid, { text: getAdminPanel(users) });
      break;
    }

    case "stats": {
      const users2 = getAllUsers();
      const ul = Object.values(users2);
      const totalMsgs = ul.reduce((s, u) => s + (u.messageCount || 0), 0);
      await sock.sendMessage(jid, {
        text: `📊 *Stats:*\n👥 Users: ${ul.length}\n💬 Messages: ${totalMsgs}`,
      });
      break;
    }

    case "users": {
      const users3 = getAllUsers();
      const list = Object.values(users3);
      const userText = list.length === 0
        ? "No users yet."
        : list.slice(0, 20).map((u, i) => `${i + 1}. ${u.phone} (${u.messageCount} msgs)`).join("\n");
      await sock.sendMessage(jid, {
        text: `👥 *Users (${list.length} total):*\n\n${userText}`,
      });
      break;
    }

    case "broadcast": {
      if (!extra) {
        await sock.sendMessage(jid, { text: "📢 Usage: broadcast <your message>" });
        break;
      }
      const allUsers = getAllUsers();
      const jids = Object.keys(allUsers).map((p) => p + "@s.whatsapp.net");
      let sent = 0;
      for (const target of jids) {
        try {
          await sock.sendMessage(target, { text: `📢 *Broadcast from Fundo AI:*\n\n${extra}` });
          sent++;
        } catch {}
      }
      await sock.sendMessage(jid, { text: `✅ Broadcast sent to ${sent}/${jids.length} users.` });
      break;
    }

    case "chat":
    default: {
      const response = await chat(jid, text);
      setLastResponse(jid, response);
      await sock.sendMessage(jid, { text: response });
      break;
    }
  }
}
