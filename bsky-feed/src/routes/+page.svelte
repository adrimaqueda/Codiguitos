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
        cid: string;
        // text: string;
        timestamp: string;
    }> = $state([]);
    let connected = false;
    let eventSource: EventSource | null = null;

    let postsReaden = $state(0);
    let maxPosts = 500;

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
        const eventSource = new EventSource('/api/jetstream');
        
        eventSource.onmessage = (event) => {
            let data;
            try {
                data = JSON.parse(event.data);
            } catch (e) {
                console.error('Error parsing SSE data:', e);
                return;
            }
            
            if (data.type === 'connected') {
                console.log('Conexión establecida');
                connected = true;
            } else if (data.type === 'new-post') {
                // Add the new post to the end of the array
                posts.push({
                    cid: data.cid,
                    // text: data.text,
                    timestamp: new Date(data.timestamp).toLocaleString()
                });

                // If the array exceeds the max size, remove the oldest posts
                if (posts.length > maxPosts) {
                    posts.shift(); // Remove the first (oldest) post
                }

                postsReaden += 1;
            }
        };
    }
</script>


<div>
    <div>
        <h2 class="font-bold">Posts desde que has abierto la página: {postsReaden}</h2>
    </div>
</div>
<div bind:clientWidth={screenWidth}>

    <Canvas width={screenWidth} height=600 >
        {#each posts as post (post.cid)}
            <Circle x={Math.random() * screenWidth} y={Math.random() * 600}/>
        {/each}
    </Canvas>

</div>