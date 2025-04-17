<script lang="ts">
	import { onMount, getContext } from 'svelte';
	import { Confetti } from 'svelte-confetti';

	import { WEBUI_NAME, config, settings } from '$lib/stores';

	import { WEBUI_VERSION } from '$lib/constants';
	import { getChangelog } from '$lib/apis';

	import Modal from './common/Modal.svelte';
	import { updateUserSettings } from '$lib/apis/users';

	const i18n = getContext('i18n');

	export let show = false;

	let changelog = null;

	onMount(async () => {
		const res = await getChangelog();
		changelog = res;
	});
</script>

<Modal bind:show size="lg">
	<Confetti x={[-1, -0.25]} y={[0, 0.5]} />
	<div>
		<div style="--d:flex; --jc:space-between; --ai:flex-start;" >

			<button
				
				on:click={() => {
					localStorage.version = $config.version;
					show = false;
				}}
			>
				{(() => {
					const affirmations = ["Great!", "Awesome!", "Super!", "Cool!", "Wow!"];
					return affirmations[Math.floor(Math.random() * affirmations.length)];
				})()}
			</button>
		</div>
	</div>

	<div style="--ofy:scroll; --maxh:96vh; --pl:20px; --pr:20px; --c:oklch(47.318% 0.036 262); /* Unrecognized: dark:text-gray-100 */" >
		<div>
			<div style="--mb: 0.6em" >
				<div style="--c:xl; --weight:600;" >
					{$i18n.t('What’s New in')}
					{$WEBUI_NAME}
					
				</div>
				{#if changelog}
					{#each Object.keys(changelog) as version}
						<div style="--mb: 0.6em /* Unrecognized: pr-2 */" >
							<div style="--weight:600; --c:xl; /* Unrecognized: mb-1 */ /* Unrecognized: dark:text-white */" >
								v{version} - {changelog[version].date}
							</div>

							<hr class="border-gray-100 dark:border-gray-850 my-2" />

							{#each Object.keys(changelog[version]).filter((section) => section !== 'date') as section}
								<div class="">
									<div style="--weight:600; /* Unrecognized: uppercase */ --c:xs; /* Unrecognized: w-fit */ --pl:12px; --pr:12px; /* Unrecognized: rounded-full */ --mt:1rem; --mb:1rem {section === 'added'
											? 'text-white bg-blue-600'
											: section === 'fixed'
												? 'text-white bg-green-600'
												: section === 'changed'
													? 'text-white bg-yellow-600'
													: section === 'removed'
														? 'text-white bg-red-600'
														: ''}"
										
									>
										{section}
									</div>

									<div style="--mt:1rem; --mb:1rem /* Unrecognized: px-1.5 */" >
										{#each Object.keys(changelog[version][section]) as item}
											<div style="--c:sm; --mb: 0.6rem" >
												<div style="--weight:600; /* Unrecognized: uppercase */" >
													{changelog[version][section][item].title}
												</div>
												<div style="--mb: 0.6rem /* Unrecognized: mt-1 */" >{changelog[version][section][item].content}</div>
											</div>
										{/each}
									</div>
								</div>
							{/each}
						</div>
					{/each}
				{/if}
			</div>
		</div>
		<div style="--d:flex; --jc:end; --pt:12px; --c:sm; --weight:medium;" >
			<button
				on:click={async () => {
					localStorage.version = $config.version;
					await settings.set({ ...$settings, ...{ version: $config.version } });
					await updateUserSettings(localStorage.token, { ui: $settings });
					show = false;
				}}
				class="px-3.5 py-1.5 text-sm font-medium bg-black hover:bg-gray-900 text-white dark:bg-white dark:text-black dark:hover:bg-gray-100 transition rounded-full"
			>
				<span style="/* Unrecognized: relative */" >{$i18n.t("Okay, Let's Go!")}</span>
			</button>
		</div>
	</div>
</Modal>
