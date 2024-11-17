<script>
    import { getContext, onMount, onDestroy, tick } from 'svelte';
    

    const {
        x = 10,
        y = 10,
        r = 2,
        opacity = 1.0,
        stroke = undefined,
        strokeWidth = 1,
        fill = 'black',
        contextName = 'canvas',
    } = $props();

    const { register, deregister, invalidate } = getContext(contextName);

    function draw(ctx) {
		ctx.translate(x, y);
            ctx.globalAlpha = 0.8;
            ctx.fillStyle = fill;
            ctx.beginPath();
            ctx.arc(0, 0, r, 0, 2 * Math.PI, false);
            ctx.fill();
	}

	onMount(() => {
		register(draw);
		invalidate();
	});

	onDestroy(() => {
		deregister(draw);
	});

	$effect(() => {
		opacity, stroke, strokeWidth, fill;
        invalidate();
  });
</script>
