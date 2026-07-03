import { Router } from 'express';

export const assistantRouter = Router();

const SYSTEM = `Ты — MaMa AI, тёплый и заботливый ассистент для беременных и молодых мам.
Отвечай кратко, по-доброму, на русском языке. Помогай с вопросами о беременности,
родах и развитии малыша. НЕ ставь диагнозы; при тревожных симптомах (сильная боль,
кровотечение, высокая температура, резкое снижение шевелений) советуй обратиться к врачу
или вызвать скорую. В конце ответа добавляй короткий дисклеймер, что это не замена
консультации врача.`;

interface InMsg {
  role?: string;
  text?: string;
}

/** Локальный фолбэк на правилах (когда нет ANTHROPIC_API_KEY). */
function localReply(q: string): string {
  const t = (q ?? '').toLowerCase();
  let body: string;
  if (t.includes('тошнот') || t.includes('токсикоз'))
    body = 'Тошнота в первом триместре — частое явление. Помогают дробное питание, сухарик утром и достаточно воды. Если рвота частая — сообщите врачу.';
  else if (t.includes('шевел') || t.includes('толч'))
    body = 'Считать шевеления удобно во второй половине дня: норма — не менее 10 эпизодов за 2 часа. Заметное снижение активности — повод связаться с врачом.';
  else if (t.includes('вес') || t.includes('прибав'))
    body = 'Рекомендуемая прибавка зависит от исходного ИМТ (для нормального — примерно 11.5–16 кг). Отслеживайте её в сервисе «Монитор веса».';
  else if (t.includes('схватк') || t.includes('роды'))
    body = 'Ориентир «пора в роддом» — правило 5-1-1: схватки каждые ~5 минут, по ~1 минуте, в течение ~1 часа.';
  else if (t.includes('пита') || t.includes('еда') || t.includes('есть'))
    body = 'Питайтесь разнообразно: овощи, фрукты, белок, цельные злаки. Избегайте сырого мяса/рыбы и алкоголя.';
  else
    body = 'Спасибо за вопрос! Уточните тему — например, «тошнота», «шевеления», «вес», «схватки» или «питание».';
  return body + '\n\nℹ️ Это справочная поддержка, не замена консультации врача.';
}

// POST /assistant/chat — реальный Claude (если есть ключ), иначе локальный ответ.
assistantRouter.post('/chat', async (req, res) => {
  const incoming: InMsg[] = req.body?.messages ?? [];
  const lastUser = [...incoming].reverse().find((m) => m.role === 'user')?.text ?? '';

  if (!process.env.ANTHROPIC_API_KEY) {
    return res.json({ reply: localReply(lastUser), source: 'local' });
  }

  try {
    // Динамический импорт: пакет грузится только при наличии ключа.
    const { default: Anthropic } = await import('@anthropic-ai/sdk');
    const client = new Anthropic();

    let messages = incoming
      .filter((m) => (m.text ?? '').trim().length > 0)
      .map((m) => ({
        role: m.role === 'assistant' ? ('assistant' as const) : ('user' as const),
        content: m.text as string,
      }));
    while (messages.length && messages[0].role !== 'user') messages.shift();
    if (!messages.length) messages = [{ role: 'user', content: lastUser || 'Здравствуйте' }];

    const response = await client.messages.create({
      model: 'claude-opus-4-8',
      max_tokens: 1024,
      system: SYSTEM,
      messages,
    });
    const parts: string[] = [];
    for (const block of response.content) {
      if (block.type === 'text') parts.push(block.text);
    }
    return res.json({ reply: parts.join('\n'), source: 'claude' });
  } catch (err) {
    console.error('[assistant] Claude error', err);
    return res.json({ reply: localReply(lastUser), source: 'local-error' });
  }
});
