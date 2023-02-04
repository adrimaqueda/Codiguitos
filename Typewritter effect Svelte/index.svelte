<script lang="ts">
	
    import Typewriter from './typewriter.svelte'
    
    const sentences = ["primera frase", "segunda frase", "tercera frase", "cuarta frase", "quinta frase"]
            
    let currentlySelectedSentenceIndex:any
    let typedToIndex:any
    
    type Phase = 'typing'
    let phase: Phase = 'typing'
    
    // restart function
    function reset() {
        currentlySelectedSentenceIndex = 0;
        typedToIndex = 0;
        phase = 'typing'
    }
    
    
</script>
    
<!-- On click, restart the animation -->
<div on:click={() => reset()} on:keydown={() => reset()}>
           
    <Typewriter 
        {sentences} 
        bind:currentlySelectedSentenceIndex 
        bind:typedToIndex 
        bind:phase
    />
          
</div>
      
