<script lang="ts">
	import { onMount, getContext } from 'svelte';
	import { WEBUI_NAME, showSidebar, functions, user, mobile } from '$lib/stores';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';

	import MenuLines from '$lib/components/icons/MenuLines.svelte';

	const i18n = getContext('i18n');

	let loaded = false;

	onMount(async () => {
		if ($user?.role !== 'admin') {
			await goto('/');
		}
		loaded = true;
	});
</script>

<svelte:head>
	<title>
		{$i18n.t('Workshop')} | {$WEBUI_NAME}
	</title>
</svelte:head>

{#if loaded}
	<sage-content
		style="--m:0.4em auto; --minw:80%; --maxw-sm:calc(100% - 260px); --p:0 0.4em;
		--h: 100vh; --d: flex;
    --fd: column;"
		class="content {$showSidebar
			? 'md:max-w-[calc(100%-260px)]'
			: ''}"
	>
		<div class="   px-3.5 my-2 bg-transparent backdrop-blur-xl">
			<div class=" flex items-center gap-1">
				<div class="{$showSidebar ? 'md:hidden' : ''} mr-1 self-center flex flex-none items-center">
					<button
						id="sidebar-toggle-button"
						class="cursor-pointer p-1.5 flex rounded-xl hover:bg-gray-100 dark:hover:bg-gray-850 transition"
						on:click={() => {
							showSidebar.set(!$showSidebar);
						}}
						aria-label="Toggle Sidebar"
					>
						<div class=" m-auto self-center">
							<MenuLines />
						</div>
					</button>
				</div>
				<div style="--ff:'Cormorant', serif; --weight:700; --size:1.2em">{$i18n.t('Workshop')}</div>
			</div>
		</div>

				<div class="">
					<div
						class="flex scrollbar-none overflow-x-auto w-fit text-center text-sm font-medium rounded-full bg-transparent/10 backdrop-blur-2xl p-1 touch-auto pointer-events-auto"
					>
						<a
							class="min-w-fit rounded-full p-1.5 px-3 {$page.url.pathname.includes(
								'/workspace/models'
							)
								? 'bg-gray-50 dark:bg-gray-850'
								: ''} transition"
							href="/workspace/models">{$i18n.t('Models')}</a
						>

						<a
							class="min-w-fit rounded-full p-1.5 px-3 {$page.url.pathname.includes(
								'/workspace/knowledge'
							)
								? 'bg-gray-50 dark:bg-gray-850'
								: ''} transition"
							href="/workspace/knowledge"
						>
							{$i18n.t('Knowledge')}
						</a>

						<a
							class="min-w-fit rounded-full p-1.5 px-3 {$page.url.pathname.includes(
								'/workspace/prompts'
							)
								? 'bg-gray-50 dark:bg-gray-850'
								: ''} transition"
							href="/workspace/prompts">{$i18n.t('Prompts')}</a
						>

						<a
							class="min-w-fit rounded-full p-1.5 px-3 {$page.url.pathname.includes(
								'/workspace/tools'
							)
								? 'bg-gray-50 dark:bg-gray-850'
								: ''} transition"
							href="/workspace/tools"
						>
							{$i18n.t('Tools')}
						</a>

						<a
							class="min-w-fit rounded-full p-1.5 px-3 {$page.url.pathname.includes(
								'/workspace/functions'
							)
								? 'bg-gray-50 dark:bg-gray-850'
								: ''} transition"
							href="/workspace/functions"
						>
							{$i18n.t('Functions')}
						</a>
					</div>
				</div>

				<!-- <div class="flex items-center text-xl font-semibold">{$i18n.t('Workspace')}</div> -->
			


		<sage-content-slot
			style="--of: auto;">
			<slot />
		</sage-content-slot>
	</sage-content>
{/if}
