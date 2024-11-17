// src/routes/api/jetstream/+server.ts
import { Jetstream } from '@skyware/jetstream';
import { json } from '@sveltejs/kit';
import { error } from '@sveltejs/kit';

const clients = new Set<ReadableStreamController>();
const jetstream = new Jetstream();

function sendToAllClients(data: any) {
    // console.log('Enviando a clientes:', data);
    clients.forEach(client => {
        client.enqueue(`data: ${JSON.stringify(data)}\n\n`);
    });
}

// Verificar que Jetstream se inicializa correctamente
console.log('Inicializando Jetstream...');

// Agregamos un manejador para conectar explícitamente
// jetstream.connect().then(() => {
//     console.log('Jetstream conectado exitosamente');
// }).catch(err => {
//     console.error('Error al conectar Jetstream:', err);
// });

jetstream.start()

jetstream.onCreate("app.bsky.feed.post", (event) => {
    // console.log('Nuevo post recibido:', event);
    const postData = {
        type: 'new-post',
        text: event.commit.record.text,
        timestamp: event.commit.record.createdAt
    };
    sendToAllClients(postData);
});

// También podemos agregar un manejador de errores global
jetstream.on('error', (error) => {
    console.error('Error en Jetstream:', error);
});

export async function GET() {
    console.log('Nueva conexión SSE establecida');
    const stream = new ReadableStream({
        start(controller) {
            clients.add(controller);
            console.log('Cliente conectado. Total clientes:', clients.size);
            controller.enqueue('data: {"type":"connected"}\n\n');
        },
        cancel() {
            clients.delete(controller);
            console.log('Cliente desconectado. Total clientes:', clients.size);
        }
    });

    return new Response(stream, {
        headers: {
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive'
        }
    });
}