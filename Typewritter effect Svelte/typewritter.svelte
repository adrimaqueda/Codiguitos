<!-- Code adapted from Techy Cat component: https://github.com/jmagrippis/techy-cat/blob/main/src/routes/(app)/demos/typing-animation/TypingAnimation.svelte -->

<script lang="ts">
	import {randomInteger} from './randomInteger'
	import {onMount} from 'svelte'

	// typing velocity options
	const TYPING_SPEED_MS = 60
	const TYPING_VARIANCE = 30
	const PAUSE_TIME_MS = 1000
	const DELETE_SPEED_MS = 45

	export let sentences: string[]

	// we export the variable to repeat on click
	export let currentlySelectedSentenceIndex = 0
	$: currentSentence = sentences[currentlySelectedSentenceIndex]
	
	// we export the variable to repeat on click
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

	// add stop phase that check if there is more phrases to write or not and stop on the last one
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
			// delete some code because we don`t want it to repeat
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

	// add stop phase
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

	// add tick
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
