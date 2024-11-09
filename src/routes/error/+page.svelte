<script>
	import { goto } from '$app/navigation';
	import { WEBUI_NAME, config } from '$lib/stores';
	import { onMount, getContext } from 'svelte';

	const i18n = getContext('i18n');

	let loaded = false;

	onMount(async () => {
		if ($config) {
			await goto('/');
		}

		loaded = true;
	});
</script>

{#if loaded}
	<div style="
			--d:flex;
			--fd:column;
			--ai:center;
			--jc:center;
			--minh:100dvh;
			--maxw:30em;
			--m:auto;
			--ta:center"
		>
		<div>
			<h1 style="--size:2em">{$i18n.t('Unable to connect')}</h1>
			<div class="">
				{$i18n.t(
					"Unable to connect to API server. Please "
				)}
				<br class=" " />
				<a
					class=" font-semibold underline"
					href="https://github.com/startr/open-webui#how-to-install-"
					target="_blank">{$i18n.t('See readme.md for instructions')}</a>
				
			</div>

			<div style="--mt:1em; --ta:center">
				<button
					style="--p:0.5em 1em; --bg:var(--color-primary); --c:var(--color-primary-text); --br:0.5em"
					on:click={() => {
						location.href = '/';
					}}
				>
					{$i18n.t('Check Again')} 
				</button>

				or our

				<a
					
					href="mailto:admin@sage.education"
					target="_blank">{$i18n.t('support team.')}</a>
			</div>
		</div>
	</div>
{/if}
