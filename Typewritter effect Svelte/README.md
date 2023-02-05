## Typewritter component for Svelte

Esta es la versión del componente de escritura en Svelte realizado por [Johnny Magrippis (Techy Cat)](https://github.com/jmagrippis/techy-cat/blob/main/src/routes/(app)/demos/typing-animation/TypingAnimation.svelte) y que yo he usado en **[mi web](https://adrimaqueda.com)**

Ejemplo:
![typing example](https://media.giphy.com/media/vFKqnCdLPNOKc/giphy.gif)


En **`typewritter.svelte`** está comentado todo el código que he cambiado y en **`index.svelte`** un ejemplo de uso


El código está adaptado para añadir dos funcionalidades:
- Que al hacer **click** volviera a empezar la animación
- **Terminar la animación** en la última frase y no dejar un loop constante

Puedes testear una versión de este componente en este **[REPL](https://svelte.dev/repl/b33b21bf4f974d8b8a3a130ef2cd27de?version=3.55.1)** (El código es ligeramente diferente porque la web no acepta Typescript)