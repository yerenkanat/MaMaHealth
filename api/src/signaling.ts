import type { Server } from 'node:http';
import jwt from 'jsonwebtoken';
import { WebSocket, WebSocketServer } from 'ws';

interface Client {
  ws: WebSocket;
  userId: string;
  room: string;
}

/**
 * WebRTC-сигналинг для видеоконсультаций врач↔пациент.
 * Подключение: ws://host/ws/signal?token=<JWT>&room=<pairId>
 * Сервер ретранслирует offer/answer/ICE-кандидаты остальным участникам комнаты.
 */
export function attachSignaling(server: Server): WebSocketServer {
  const wss = new WebSocketServer({ server, path: '/ws/signal' });
  const rooms = new Map<string, Set<Client>>();

  wss.on('connection', (ws, req) => {
    const url = new URL(req.url ?? '', 'http://localhost');
    const token = url.searchParams.get('token') ?? '';
    const room = url.searchParams.get('room') ?? '';

    let userId: string;
    try {
      const payload = jwt.verify(token, process.env.JWT_SECRET as string) as {
        sub: string;
      };
      userId = payload.sub;
    } catch {
      ws.close(4001, 'unauthorized');
      return;
    }
    if (!room) {
      ws.close(4002, 'no_room');
      return;
    }

    const client: Client = { ws, userId, room };
    if (!rooms.has(room)) rooms.set(room, new Set());
    rooms.get(room)!.add(client);

    ws.on('message', (data) => {
      const peers = rooms.get(room);
      if (!peers) return;
      for (const peer of peers) {
        if (peer.ws !== ws && peer.ws.readyState === WebSocket.OPEN) {
          peer.ws.send(data.toString());
        }
      }
    });

    ws.on('close', () => {
      const peers = rooms.get(room);
      peers?.delete(client);
      if (peers && peers.size === 0) rooms.delete(room);
    });
  });

  console.log('[signaling] WebRTC signaling on /ws/signal');
  return wss;
}
