<script lang="ts">
	import { getAdminDetails } from '$lib/apis/auths';
	import { onMount, tick, getContext } from 'svelte';

	const i18n = getContext('i18n');

	let adminDetails = null;

	onMount(async () => {
		adminDetails = await getAdminDetails(localStorage.token).catch((err) => {
			console.error(err);
			return null;
		});
	});
</script>

<div class="fixed w-full h-full flex z-[999]">
	<div
		class="absolute w-full h-full backdrop-blur-lg bg-white/10 dark:bg-gray-900/50 flex justify-center"
	>
		<div
			style="
			--d:flex;
			--fd: column;
			--jc: center;"
		>
			<div
				style="
				--c: var(--black);
				--br:1em;
				--shadow: 8;
			    --ta: center;
				--bg: var(--background-alt);
				--maxw: 30rem;
				--p: 2em;"			>
				<div style="
				 	    --c: slategrey;
						--p: 0.2em;
						--lh: 1.2em;
						--size: 1.2em;">
					{$i18n.t('Activation Is Pending')}<br />
					{$i18n.t('Feel free to contact us if you have any questions.')}
				</div>

				<div style="--size: 0.8em">
					{$i18n.t('Your Sage.Education account is currently pending activation.')}<br />
					{$i18n.t(
						'Please check your email for the activation link. If you have not received the email, please check your spam folder or contact us.'
					)}
				</div>

				{#if adminDetails}
					<div class="mt-4 text-sm font-medium text-center">
						<div>{adminDetails.name} ({adminDetails.email})</div>
					</div>
				{/if}

				<div style="--m:1em">
					<button style="
						--p: 0 0.6em;
						--br: 1em;"
						on:click={async () => {
							location.href = '/';
						}}
					>
						{$i18n.t('Check Again')}
					</button>

					<button style="
					--p: 0 0.6em;
					--br: 1em;"
						on:click={async () => {
							localStorage.removeItem('token');
							location.href = '/auth';
						}}>{$i18n.t('Sign Out')}</button
					>
				</div>
			</div>
		</div>
	</div>
</div>
