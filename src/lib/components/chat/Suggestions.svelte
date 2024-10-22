<script lang="ts">
	import Bolt from '$lib/components/icons/Bolt.svelte';
	import { onMount, getContext, createEventDispatcher } from 'svelte';

	const i18n = getContext('i18n');
	const dispatch = createEventDispatcher();

	export let suggestionPrompts = [];
	export let className = '';

	let prompts = [];
	let searchQuery = '';
	let filteredPrompts = [];

	$: prompts = (suggestionPrompts ?? [])
		.reduce((acc, current) => [...acc, ...[current]], [])
		.sort(() => Math.random() - 0.5);

	$: filteredPrompts = searchQuery
		? prompts.filter((prompt) => prompt.content.toLowerCase().includes(searchQuery.toLowerCase()))
		: prompts.slice(0, 3);
</script>

<div style="--d:flex; --ai:center">
	<Bolt />
	<input
		type="text"
		placeholder={$i18n.t('Search')}{$i18n.t('Suggestions')} :
		bind:value={searchQuery}
		class="w-full p-2 border rounded mb-2 text-sm"
	/>
</div>

{#if filteredPrompts.length > 0}
	<div
		id="suggestions-header"
		class="mb-1 flex gap-1 text-sm font-medium items-center text-gray-400 dark:text-gray-600"
	></div>
{/if}

<div class={className} style="--h: 17rem">
	{#each filteredPrompts as prompt, promptIdx}
		<div
			class="prompt"
			style=" --shadow: 6; 
										--levitate-hvr:8; 
										--br: 1rem; 
										--p: 1em; 
										--m: 1em -0.2em 0 -0.8em;
										--d: flex;"
			on:click={() => {
				dispatch('select', prompt.content);
			}}
		>
			<div class="flex flex-col text-left">
				{#if prompt.title && prompt.title[0] !== ''}
					<h5>
						{prompt.title[0]}
					</h5>
					<div style="--size:0.8em">{prompt.title[1]}</div>
				{:else}
					<div>
						{prompt.content}
					</div>
				{/if}
			</div>
		</div>
	{/each}
</div>
