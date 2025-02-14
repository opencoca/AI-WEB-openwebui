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
	<div style="--pl:20px; --pr:20px; --pt:16px; /* Unrecognized: dark:text-gray-300 */ --c:oklch(47.318% 0.036 262);" >
		<div style="--d:flex; --jc:space-between; --ai:flex-start;" >
			<div style="--c:xl; --weight:600;" >
				{$i18n.t('What’s New in')}
				{$WEBUI_NAME}
				<Confetti x={[-1, -0.25]} y={[0, 0.5]} />
			</div>
			<button style="--as:center;"
				
				on:click={() => {
					localStorage.version = $config.version;
					show = false;
				}}
			>
				<svg style="/* Unrecognized: w-5 */ /* Unrecognized: h-5 */"
					xmlns="http://www.w3.org/2000/svg"
					viewBox="0 0 20 20"
					fill="currentColor"
					
				>
					<path
						d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z"
					/>
				</svg>
			</button>
		</div>
		<div style="--d:flex; --ai:center; /* Unrecognized: mt-1 */" >
			<div style="--c:sm; /* Unrecognized: dark:text-gray-200 */" >{$i18n.t('Release Notes')}</div>
			<div style="--d:flex; --as:center; --w:1px; /* Unrecognized: h-6 */ /* Unrecognized: mx-2.5 */ --bgc:oklch(91.9% 0.016 262); /* Unrecognized: dark:bg-gray-700 */"  />
			<div style="--c:sm; /* Unrecognized: dark:text-gray-200 */" >
				v{WEBUI_VERSION}
			</div>
		</div>
	</div>

	<div style="/* Unrecognized: w-full */ /* Unrecognized: p-4 */ --pl:20px; --pr:20px; --c:oklch(47.318% 0.036 262); /* Unrecognized: dark:text-gray-100 */" >
		<div style="/* Unrecognized: overflow-y-scroll */ /* Unrecognized: max-h-96 */ /* Unrecognized: scrollbar-hidden */" >
			<div style="/* Unrecognized: mb-3 */" >
				{#if changelog}
					{#each Object.keys(changelog) as version}
						<div style="/* Unrecognized: mb-3 */ /* Unrecognized: pr-2 */" >
							<div style="--weight:600; --c:xl; /* Unrecognized: mb-1 */ /* Unrecognized: dark:text-white */" >
								v{version} - {changelog[version].date}
							</div>

							<hr style="/* Unrecognized: dark:border-gray-800 */ /* Unrecognized: my-2 */"  />

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
