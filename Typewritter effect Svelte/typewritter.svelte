<!-- Código adaptado del componente de Techy Cat: https://github.com/jmagrippis/techy-cat/blob/main/src/routes/(app)/demos/typing-animation/TypingAnimation.svelte -->

<script lang="ts">
	import {randomInteger} from './randomInteger'
	import {onMount} from 'svelte'

	// ajustes de velocidad
	const TYPING_SPEED_MS = 60
	const TYPING_VARIANCE = 30
	const PAUSE_TIME_MS = 1000
	const DELETE_SPEED_MS = 45

	export let sentences: string[]

	// exporto la variable para poder volver a empezar la animación al hacer click
	export let currentlySelectedSentenceIndex = 0
	$: currentSentence = sentences[currentlySelectedSentenceIndex]
	
	// exporto la variable para poder volver a empezar la animación al hacer click
	export let typedToIndex = 0
	let currentTimeout: null | NodeJS.Timeout = null
	$: typedSentence = currentSentence.slice(0, typedToIndex)

	const handleTypingPhase = () => {
		currentTimeout = setTimeout(() => {
			if (typedToIndex + 1 <= currentSentence.length) {
				typedToIndex++
				handleTypingPhase()
			} else {
				phase = 'stop' // change phase from pausing to stop
			}
		}, randomInteger(TYPING_SPEED_MS - TYPING_VARIANCE, TYPING_SPEED_MS + TYPING_VARIANCE))
	}

	// añado una fase de final para comprobar si hay más frases para escribir o si no, y cortar el loop 
    const handleStop = () => {
        currentTimeout = setTimeout(() => {
			currentlySelectedSentenceIndex + 1 === sentences.length ? phase = 'stop' : phase = 'pausing'
		}, 0)
    }

	const handlePausingPhase = () => {
		currentTimeout = setTimeout(() => {
			phase = 'deleting'
		}, PAUSE_TIME_MS)
	}

	const handleDeletingPhase = () => {
		currentTimeout = setTimeout(() => {
			// elimino parte del código que había aquí para ejecutar el loop y que a mí no me hacía falta
			const nextSelectedSentenceIndex = currentlySelectedSentenceIndex + 1
			const nextSentence = sentences[nextSelectedSentenceIndex]
			const haveDeletedEnough =
				typedToIndex === 0 || nextSentence.indexOf(typedSentence) === 0
			if (!haveDeletedEnough) {
				typedToIndex--
				handleDeletingPhase()
			} else {
				currentlySelectedSentenceIndex = nextSelectedSentenceIndex
				phase = 'typing'
			}
		}, DELETE_SPEED_MS)
	}

	// añado la fase para terminar
	type Phase = 'typing' | 'stop' | 'pausing' | 'deleting'
	export let phase: Phase = 'typing'
	
    const phaseHandler = (currentPhase: Phase) => {
		switch (currentPhase) {
			case 'typing':
				handleTypingPhase()
				break
            case 'stop':
				handleStop()
				break
			case 'pausing':
				handlePausingPhase()
				break
			case 'deleting':
				handleDeletingPhase()
				break
		}
	}

    $: phaseHandler(phase)

	// añado el tick final, pero solo si aún quedan frases que escribir
	$: tick = phase === 'stop' ? '' : '|'
	
    onMount(() => {
		return () => {
			if (currentTimeout) {
				clearTimeout(currentTimeout)
			}
		}
	})

</script>

{typedSentence} <span style="display: inline-block;position:relative;top:1px">{tick}</span>
