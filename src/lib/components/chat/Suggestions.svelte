<script lang="ts">
	import Bolt from '$lib/components/icons/Bolt.svelte';
	import { onMount, getContext, createEventDispatcher } from 'svelte';

	const i18n = getContext('i18n');
	const dispatch = createEventDispatcher();

	export let suggestionPrompts = [];
	export let className = '';

	let prompts = [];

	$: prompts = (suggestionPrompts ?? [])
		.reduce((acc, current) => [...acc, ...[current]], [])
		.sort(() => Math.random() - 0.5);
</script>

{#if prompts.length > 0}
	<div id="suggestions-header" 
	class="mb-1 flex gap-1 text-sm font-medium items-center text-gray-400 dark:text-gray-600">
		<Bolt />
		{$i18n.t('Suggestions')}
	</div>
{/if}

<div class="{className}" style="--h: 0; --minh: 200%; --of: scroll;">
	{#each prompts as prompt, promptIdx}
		<div class="prompt" style=" --shadow: 6; --levitate-hvr:8; --br: 1rem; --p: 1em; --m:0.6em; --d: flex;"
			on:click={() => {
				dispatch('select', prompt.content);
			}}
		>
			<div class="flex flex-col text-left">
				{#if prompt.title && prompt.title[0] !== ''}
					<div
						style="--line-clamp:4;"
					>
						{prompt.title[0]}
					</div>
					<div style="--line-clamp:4;">{prompt.title[1]}</div>
				{:else}
					<div
						style="--line-clamp:4;"
					>
						{prompt.content}
					</div>

					<div class="tag">Prompt</div>
				{/if}
			</div>
		</div>
	{/each}
</div>
