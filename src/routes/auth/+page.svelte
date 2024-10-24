<script>
	import { goto } from '$app/navigation';
	import { getSessionUser, userSignIn, userSignUp } from '$lib/apis/auths';
	import Spinner from '$lib/components/common/Spinner.svelte';
	import { WEBUI_API_BASE_URL, WEBUI_BASE_URL } from '$lib/constants';
	import { WEBUI_NAME, config, user, socket } from '$lib/stores';
	import { onMount, getContext } from 'svelte';
	import { toast } from 'svelte-sonner';
	import { generateInitialsImage, canvasPixelTest } from '$lib/utils';
	import { page } from '$app/stores';
	import { getBackendConfig } from '$lib/apis';

	$: currentUrl = $page.url.host; // Extracts the hostname without protocol or path


	const i18n = getContext('i18n');

	let loaded = false;
	let mode = 'signin';

	let name = '';
	let email = '';
	let password = '';
	let showPassword = false;

	const setSessionUser = async (sessionUser) => {
		if (sessionUser) {
			console.log(sessionUser);
			toast.success($i18n.t(`You're now logged in.`));
			if (sessionUser.token) {
				localStorage.token = sessionUser.token;
			}

			$socket.emit('user-join', { auth: { token: sessionUser.token } });
			await user.set(sessionUser);
			await config.set(await getBackendConfig());
			goto('/');
		}
	};

	const signInHandler = async () => {
		const sessionUser = await userSignIn(email, password).catch((error) => {
			toast.error(error);
			return null;
		});

		await setSessionUser(sessionUser);
	};

	const signUpHandler = async () => {
		const sessionUser = await userSignUp(name, email, password, generateInitialsImage(name)).catch(
			(error) => {
				toast.error(error);
				return null;
			}
		);

		await setSessionUser(sessionUser);
	};

	const submitHandler = async () => {
		if (mode === 'signin') {
			await signInHandler();
		} else {
			await signUpHandler();
		}
	};

	const checkOauthCallback = async () => {
		if (!$page.url.hash) {
			return;
		}
		const hash = $page.url.hash.substring(1);
		if (!hash) {
			return;
		}
		const params = new URLSearchParams(hash);
		const token = params.get('token');
		if (!token) {
			return;
		}
		const sessionUser = await getSessionUser(token).catch((error) => {
			toast.error(error);
			return null;
		});
		if (!sessionUser) {
			return;
		}
		localStorage.token = token;
		await setSessionUser(sessionUser);
	};

	onMount(async () => {
		if ($user !== undefined) {
			await goto('/');
		}
		await checkOauthCallback();
		loaded = true;
		if (($config?.features.auth_trusted_header ?? false) || $config?.features.auth === false) {
			await signInHandler();
		}
	});
</script>

<svelte:head>
	<title>
		{`${$WEBUI_NAME}`}
	</title>
	<link
		rel="stylesheet"
		href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css"
	/>
</svelte:head>

{#if loaded}
	<div class="fixed m-10 z-50">
		<div class="flex space-x-2"></div>
	</div>

	<div class="bg-white dark:bg-gray-950 min-h-screen w-full flex justify-center font-primary">
		<div class="w-full sm:max-w-md px-10 min-h-screen flex flex-col text-center">
			{#if ($config?.features.auth_trusted_header ?? false) || $config?.features.auth === false}
				<div class="my-auto pb-10 w-full">
					<div
						class="flex items-center justify-center gap-3 text-xl sm:text-2xl text-center font-semibold dark:text-gray-200"
					>
						<div>
							{$i18n.t('Signing in to {{$currentUrl}}', { WEBUI_NAME: $WEBUI_NAME })}
						</div>
						<div>
							<Spinner />
						</div>
					</div>
				</div>
			{:else}
				<div class="my-auto pb-10 w-full dark:text-gray-100">
					<form class="flex flex-col justify-center" on:submit|preventDefault={submitHandler}>
						<div class="self-center">
							<img
								crossorigin="anonymous"
								src="/static/favicon.png"
								style="--br: 10%; --h: 10em; --w: 10em;"
								alt="logo"
							/>
						</div>

						<div style="--size:1.6em; --p:0.2em">
							{#if mode === 'signin'}
							  {$i18n.t(`Sign in to {{CURRENT_URL}}`, { WEBUI_NAME: $WEBUI_NAME, CURRENT_URL: currentUrl })}
							{:else}
							  {$i18n.t(`Sign up to {{CURRENT_URL}}`, { WEBUI_NAME: $WEBUI_NAME, CURRENT_URL: currentUrl })}
							{/if}
						</div>
						<div style="--size:1em; --p:0.2em">
							Powered by <a style="--c: var(--links);" href="https://sage.education/ai">{$i18n.t('{{WEBUI_NAME}}', { WEBUI_NAME: $WEBUI_NAME })}</a>
						</div>

						{#if mode === 'signup'}
							<div class="mt-1 text-xs font-medium text-gray-500">
								ⓘ {$WEBUI_NAME}
								{$i18n.t(
									'does not make any external connections, and your data stays securely on your locally hosted server.'
								)}
							</div>
						{/if}

						{#if $config?.features.enable_login_form}
							<div class="flex flex-col mt-4">
								{#if mode === 'signup'}
									<div>
										<div class="text-sm font-medium text-left mb-1">{$i18n.t('Name')}</div>
										<input
											bind:value={name}
											type="text"
											class="px-5 py-3 rounded-2xl w-full text-sm outline-none border dark:border-none dark:bg-gray-900"
											autocomplete="name"
											placeholder={$i18n.t('Enter Your Full Name')}
											required
										/>
									</div>
									<hr class="my-3 dark:border-gray-900" />
								{/if}

								<div class="mb-2">
									<div class="text-sm font-medium text-left mb-1">{$i18n.t('Email')}</div>
									<input
										bind:value={email}
										type="email"
										class="px-5 py-3 rounded-2xl w-full text-sm outline-none border dark:border-none dark:bg-gray-900"
										autocomplete="email"
										placeholder={$i18n.t('Enter Your Email')}
										required
									/>
								</div>

								<div class="relative">
									<div class="text-sm font-medium text-left mb-1">{$i18n.t('Password')}</div>

									{#if showPassword}
										<input
											bind:value={password}
											style="--m:0; --c:slategray"
											type="text"
											placeholder={$i18n.t('Enter Your Password')}
											autocomplete="current-password"
											required
										/>
									{:else}
										<input
											bind:value={password}
											style="--m:0"
											type="password"
											placeholder={$i18n.t('Enter Your Password')}
											autocomplete="current-password"
											required
										/>
									{/if}

									<button
										type="button"
										style="--b:none; --shadow:none"
										class="eye absolute right-3 top-9 text-gray-500 dark:text-gray-400"
										on:click={() => (showPassword = !showPassword)}
									>
										<i class={showPassword ? 'fa fa-eye-slash' : 'fa fa-eye'} aria-hidden="true"
										></i>
									</button>
								</div>
							</div>
						{/if}

						<div class="mt-5">
							<button
								class="bg-gray-900 hover:bg-gray-800 w-full rounded-2xl text-white font-medium text-sm py-3 transition"
								type="submit"
							>
								{mode === 'signin' ? $i18n.t('Sign in') : $i18n.t('Create Account')}
							</button>

							{#if $config?.features.enable_signup}
								<div class="mt-4 text-sm text-center">
									{mode === 'signin'
										? $i18n.t("Don't have an account?")
										: $i18n.t('Already have an account?')}

									<button
										id="signup"
										style="--b: none; --shadow: none"
										class="font-medium underline"
										type="button"
										on:click={() => {
											mode = mode === 'signin' ? 'signup' : 'signin';
										}}
									>
										{mode === 'signin' ? $i18n.t('Sign up') : $i18n.t('Sign in')}
									</button>
								</div>
							{/if}
						</div>
					</form>
				</div>
			{/if}
		</div>
	</div>
{/if}

<style>
	.font-mona {
		font-family:
			'Mona Sans',
			-apple-system,
			'Inter',
			ui-sans-serif,
			system-ui,
			'Segoe UI',
			Roboto,
			Ubuntu,
			Cantarell,
			'Noto Sans',
			sans-serif,
			'Helvetica Neue',
			Arial,
			'Apple Color Emoji',
			'Segoe UI Emoji',
			'Segoe UI Symbol',
			'Noto Color Emoji';
	}

	*:focus {
    outline: none !important;
}
</style>
