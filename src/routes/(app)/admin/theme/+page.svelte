<script lang="ts">
    import { onMount } from 'svelte';
    import { WEBUI_API_BASE_URL } from '$lib/constants';

    let cssContent = '';
    let logoUrl = '';
    let isUploading = false;

    function handleCssInput(event: Event) {
        const target = event.target as HTMLTextAreaElement;
        cssContent = target.value;
    }

    async function loadThemeSettings() {
        try {
            const response = await fetch(`${WEBUI_API_BASE_URL}/theme/theme`);
            if (response.ok) {
                const data = await response.json();
                cssContent = data.css || '';
            }
        } catch (error) {
            console.error('Failed to load theme settings:', error);
        }
    }

    async function loadLogo() {
        try {
            const response = await fetch(`${WEBUI_API_BASE_URL}/theme/theme/logo`);
            if (response.ok) {
                const blob = await response.blob();
                logoUrl = URL.createObjectURL(blob);
            }
        } catch (error) {
            // Logo not found is expected if no logo is set
        }
    }

    async function saveThemeSettings() {
        try {
            const response = await fetch(`${WEBUI_API_BASE_URL}/theme/theme`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ css: cssContent })
            });

            if (response.ok) {
                alert('Theme settings saved successfully');
            } else {
                throw new Error('Failed to save theme settings');
            }
        } catch (error) {
            console.error('Failed to save theme settings:', error);
            alert('Failed to save theme settings');
        }
    }

    async function handleLogoUpload(event: Event) {
        const fileInput = event.target as HTMLInputElement;
        if (!fileInput.files?.length) return;

        const file = fileInput.files[0];
        if (!file.type.startsWith('image/')) {
            alert('Please upload an image file');
            return;
        }

        isUploading = true;
        try {
            const formData = new FormData();
            formData.append('file', file);

            const response = await fetch(`${WEBUI_API_BASE_URL}/theme/theme/logo`, {
                method: 'POST',
                body: formData
            });

            if (response.ok) {
                alert('Logo uploaded successfully');
                await loadLogo();
            } else {
                throw new Error('Failed to upload logo');
            }
        } catch (error) {
            console.error('Failed to upload logo:', error);
            alert('Failed to upload logo');
        } finally {
            isUploading = false;
        }
    }

    async function deleteLogo() {
        try {
            const response = await fetch(`${WEBUI_API_BASE_URL}/theme/theme/logo`, {
                method: 'DELETE'
            });

            if (response.ok) {
                alert('Logo deleted successfully');
                logoUrl = '';
            } else {
                throw new Error('Failed to delete logo');
            }
        } catch (error) {
            console.error('Failed to delete logo:', error);
            alert('Failed to delete logo');
        }
    }

    onMount(async () => {
        await Promise.all([loadThemeSettings(), loadLogo()]);
    });
</script>

<div class="container mx-auto py-6">
    <h1 class="text-2xl font-bold mb-6">Theme Management</h1>

    <div class="grid gap-6">
        <!-- Logo Management -->
        <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
            <h2 class="text-xl font-semibold mb-2">Logo</h2>
            <p class="text-gray-600 dark:text-gray-400 mb-4">Upload or remove the site logo</p>
            
            <div class="space-y-4">
                {#if logoUrl}
                    <div class="flex items-center space-x-4">
                        <img src={logoUrl} alt="Current logo" class="h-16 w-auto" />
                        <button 
                            class="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600"
                            on:click={deleteLogo}
                        >
                            Remove Logo
                        </button>
                    </div>
                {/if}
                <div class="space-y-2">
                    <label for="logo" class="block text-sm font-medium">Upload New Logo</label>
                    <input
                        id="logo"
                        type="file"
                        accept="image/*"
                        on:change={handleLogoUpload}
                        disabled={isUploading}
                        class="block w-full text-sm text-gray-500
                            file:mr-4 file:py-2 file:px-4
                            file:rounded-full file:border-0
                            file:text-sm file:font-semibold
                            file:bg-blue-50 file:text-blue-700
                            hover:file:bg-blue-100"
                    />
                </div>
            </div>
        </div>

        <!-- CSS Editor -->
        <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
            <h2 class="text-xl font-semibold mb-2">Custom CSS</h2>
            <p class="text-gray-600 dark:text-gray-400 mb-4">Add custom CSS to style the application</p>
            
            <div class="space-y-4">
                <textarea
                    value={cssContent}
                    on:input={(e) => cssContent = e.target.value}
                    rows={20}
                    class="w-full p-2 border rounded font-mono"
                    placeholder="Add your custom CSS here..."
                />
                <button 
                    class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
                    on:click={saveThemeSettings}
                >
                    Save CSS
                </button>
            </div>
        </div>
    </div>
</div> 