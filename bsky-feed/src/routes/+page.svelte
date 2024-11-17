<script lang="ts">
    // https://skyware.js.org/guides/jetstream/introduction/getting-started/
    // https://docs.bsky.app/blog/jetstream
    // https://skyware.js.org/docs/bot/types/PostData/#text
    // https://paste.lol/jglypt/jetstreamfilter
    // https://bsky.app/profile/jglypt.net/post/3l7tx5qeam32c
    
    import { onMount, onDestroy } from 'svelte';
    import { browser } from '$app/environment';
	import Canvas from '$lib/canvas.svelte';
	import Circle from '$lib/circle.svelte';

    let posts: Array<{
        text: string;
        author: string;
        timestamp: string;
    }> = $state([]);
    let connected = false;
    let eventSource: EventSource | null = null;

    let screenWidth = $state(300)

    onMount(() => {
        if (browser) {
            console.log('Montando componente, iniciando conexión...');
            connectSSE();
        }
    });

    onDestroy(() => {
        if (eventSource) {
            console.log('Desmontando componente, cerrando conexión...');
            eventSource.close();
        }
    });

    function connectSSE() {
        console.log('Iniciando conexión SSE...');
        eventSource = new EventSource('/api/jetstream');
        
        eventSource.onmessage = (event) => {
            const data = JSON.parse(event.data);
            
            if (data.type === 'connected') {
                console.log('Conexión establecida');
                connected = true;
            } else if (data.type === 'new-post') {
                // console.log('Nuevo post recibido:', data);
                posts = [...posts, {
                    text: data.text,
                    author: data.author,
                    timestamp: new Date(data.timestamp).toLocaleString()
                }];
            }
        };

        // eventSource.onerror = (error) => {
        //     console.error('SSE Error:', error);
        //     connected = false;
        //     if (eventSource) {
        //         eventSource.close();
        //         eventSource = null;
        //     }
        //     // Intentar reconectar después de 5 segundos
        //     setTimeout(connectSSE, 5000);
        // };

        eventSource.onopen = () => {
            console.log('Conexión SSE abierta');
        };
    }

    let posiciones = [];

    let ultimas1000 = $derived.by(() => {
        posts.forEach((d, index) => {
        if (!posiciones[index]) {
            posiciones[index] = {
                x: Math.random() * screenWidth,
                y: Math.random() * 600,
            };
        }
    });

    const startIndex = Math.max(0, posts.length - 1000);

    return posts.slice(startIndex).map((_, i) => posiciones[startIndex + i]);
    })
</script>


<div class="container mx-auto p-4">
    <div class="space-y-4">
        <h2 class="text-xl font-bold">Posts Recientes: {posts.length}</h2>
    </div>
</div>
<div bind:clientWidth={screenWidth}>

    <Canvas width={screenWidth} height=600 >
        {#each ultimas1000 as post}
            <Circle x={post.x} y={post.y}/>
        {/each}
    </Canvas>

</div>