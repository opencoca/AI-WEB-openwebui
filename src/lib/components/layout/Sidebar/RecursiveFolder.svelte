<script>
	import { getContext, createEventDispatcher, onMount, onDestroy, tick } from 'svelte';

	const i18n = getContext('i18n');
	const dispatch = createEventDispatcher();

	import DOMPurify from 'dompurify';
	import fileSaver from 'file-saver';
	const { saveAs } = fileSaver;

	import ChevronDown from '../../icons/ChevronDown.svelte';
	import ChevronRight from '../../icons/ChevronRight.svelte';
	import Collapsible from '../../common/Collapsible.svelte';
	import DragGhost from '$lib/components/common/DragGhost.svelte';

	import FolderOpen from '$lib/components/icons/FolderOpen.svelte';
	import EllipsisHorizontal from '$lib/components/icons/EllipsisHorizontal.svelte';
	import {
		deleteFolderById,
		updateFolderIsExpandedById,
		updateFolderNameById,
		updateFolderParentIdById
	} from '$lib/apis/folders';
	import { toast } from 'svelte-sonner';
	import {
		getChatById,
		getChatsByFolderId,
		importChat,
		updateChatFolderIdById
	} from '$lib/apis/chats';
	import ChatItem from './ChatItem.svelte';
	import FolderMenu from './Folders/FolderMenu.svelte';
	import DeleteConfirmDialog from '$lib/components/common/ConfirmDialog.svelte';

	export let open = false;

	export let folders;
	export let folderId;

	export let className = '';

	export let parentDragged = false;

	let folderElement;

	let edit = false;

	let draggedOver = false;
	let dragged = false;

	let name = '';

	const onDragOver = (e) => {
		e.preventDefault();
		e.stopPropagation();
		if (dragged || parentDragged) {
			return;
		}
		draggedOver = true;
	};

	const onDrop = async (e) => {
		e.preventDefault();
		e.stopPropagation();
		if (dragged || parentDragged) {
			return;
		}

		if (folderElement.contains(e.target)) {
			console.log('Dropped on the Button');

			if (e.dataTransfer.items && e.dataTransfer.items.length > 0) {
				// Iterate over all items in the DataTransferItemList use functional programming
				for (const item of Array.from(e.dataTransfer.items)) {
					// If dropped items aren't files, reject them
					if (item.kind === 'file') {
						const file = item.getAsFile();
						if (file && file.type === 'application/json') {
							console.log('Dropped file is a JSON file!');

							// Read the JSON file with FileReader
							const reader = new FileReader();
							reader.onload = async function (event) {
								try {
									const fileContent = JSON.parse(event.target.result);
									open = true;
									dispatch('import', {
										folderId: folderId,
										items: fileContent
									});
								} catch (error) {
									console.error('Error parsing JSON file:', error);
								}
							};

							// Start reading the file
							reader.readAsText(file);
						} else {
							console.error('Only JSON file types are supported.');
						}

						console.log(file);
					} else {
						// Handle the drag-and-drop data for folders or chats (same as before)
						const dataTransfer = e.dataTransfer.getData('text/plain');
						const data = JSON.parse(dataTransfer);
						console.log(data);

						const { type, id, item } = data;

						if (type === 'folder') {
							open = true;
							if (id === folderId) {
								return;
							}
							// Move the folder
							const res = await updateFolderParentIdById(localStorage.token, id, folderId).catch(
								(error) => {
									toast.error(`${error}`);
									return null;
								}
							);

							if (res) {
								dispatch('update');
							}
						} else if (type === 'chat') {
							open = true;

							let chat = await getChatById(localStorage.token, id).catch((error) => {
								return null;
							});
							if (!chat && item) {
								chat = await importChat(localStorage.token, item.chat, item?.meta ?? {});
							}

							// Move the chat
							const res = await updateChatFolderIdById(localStorage.token, chat.id, folderId).catch(
								(error) => {
									toast.error(`${error}`);
									return null;
								}
							);

							if (res) {
								dispatch('update');
							}
						}
					}
				}
			}

			draggedOver = false;
		}
	};

	const onDragLeave = (e) => {
		e.preventDefault();
		if (dragged || parentDragged) {
			return;
		}

		draggedOver = false;
	};

	const dragImage = new Image();
	dragImage.src =
		'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

	let x;
	let y;

	const onDragStart = (event) => {
		event.stopPropagation();
		event.dataTransfer.setDragImage(dragImage, 0, 0);

		// Set the data to be transferred
		event.dataTransfer.setData(
			'text/plain',
			JSON.stringify({
				type: 'folder',
				id: folderId
			})
		);

		dragged = true;
		folderElement.style.opacity = '0.5'; // Optional: Visual cue to show it's being dragged
	};

	const onDrag = (event) => {
		event.stopPropagation();

		x = event.clientX;
		y = event.clientY;
	};

	const onDragEnd = (event) => {
		event.stopPropagation();

		folderElement.style.opacity = '1'; // Reset visual cue after drag
		dragged = false;
	};

	onMount(async () => {
		open = folders[folderId].is_expanded;
		if (folderElement) {
			folderElement.addEventListener('dragover', onDragOver);
			folderElement.addEventListener('drop', onDrop);
			folderElement.addEventListener('dragleave', onDragLeave);

			// Event listener for when dragging starts
			folderElement.addEventListener('dragstart', onDragStart);
			// Event listener for when dragging occurs (optional)
			folderElement.addEventListener('drag', onDrag);
			// Event listener for when dragging ends
			folderElement.addEventListener('dragend', onDragEnd);
		}

		if (folders[folderId]?.new) {
			delete folders[folderId].new;

			await tick();
			editHandler();
		}
	});

	onDestroy(() => {
		if (folderElement) {
			folderElement.addEventListener('dragover', onDragOver);
			folderElement.removeEventListener('drop', onDrop);
			folderElement.removeEventListener('dragleave', onDragLeave);

			folderElement.removeEventListener('dragstart', onDragStart);
			folderElement.removeEventListener('drag', onDrag);
			folderElement.removeEventListener('dragend', onDragEnd);
		}
	});

	let showDeleteConfirm = false;

	const deleteHandler = async () => {
		const res = await deleteFolderById(localStorage.token, folderId).catch((error) => {
			toast.error(`${error}`);
			return null;
		});

		if (res) {
			toast.success($i18n.t('Folder deleted successfully'));
			dispatch('update');
		}
	};

	const nameUpdateHandler = async () => {
		if (name === '') {
			toast.error($i18n.t('Folder name cannot be empty'));
			return;
		}

		if (name === folders[folderId].name) {
			edit = false;
			return;
		}

		const currentName = folders[folderId].name;

		name = name.trim();
		folders[folderId].name = name;

		const res = await updateFolderNameById(localStorage.token, folderId, name).catch((error) => {
			toast.error(`${error}`);

			folders[folderId].name = currentName;
			return null;
		});

		if (res) {
			folders[folderId].name = name;
			toast.success($i18n.t('Folder name updated successfully'));
			dispatch('update');
		}
	};

	const isExpandedUpdateHandler = async () => {
		const res = await updateFolderIsExpandedById(localStorage.token, folderId, open).catch(
			(error) => {
				toast.error(`${error}`);
				return null;
			}
		);
	};

	let isExpandedUpdateTimeout;

	const isExpandedUpdateDebounceHandler = (open) => {
		clearTimeout(isExpandedUpdateTimeout);
		isExpandedUpdateTimeout = setTimeout(() => {
			isExpandedUpdateHandler();
		}, 500);
	};

	$: isExpandedUpdateDebounceHandler(open);

	const editHandler = async () => {
		console.log('Edit');
		await tick();
		name = folders[folderId].name;

		edit = true;
		await tick();

		const input = document.getElementById(`folder-${folderId}-input`);

		if (input) {
			input.focus();
		}
	};

	const exportHandler = async () => {
		const chats = await getChatsByFolderId(localStorage.token, folderId).catch((error) => {
			toast.error(`${error}`);
			return null;
		});
		if (!chats) {
			return;
		}

		const blob = new Blob([JSON.stringify(chats)], {
			type: 'application/json'
		});

		saveAs(blob, `folder-${folders[folderId].name}-export-${Date.now()}.json`);
	};
</script>

<DeleteConfirmDialog
	bind:show={showDeleteConfirm}
	title={$i18n.t('Delete folder?')}
	on:confirm={() => {
		deleteHandler();
	}}
>
	<div
		style="--size:0.875rem; --lh:1.25rem; --c:#374151; --dark-c:#d1d5db; --fx:1;"
		class="line-clamp-3"
	>
		{@html DOMPurify.sanitize(
			$i18n.t('This will delete <strong>{{NAME}}</strong> and <strong>all its contents</strong>.', {
				NAME: folders[folderId].name
			})
		)}
	</div>
</DeleteConfirmDialog>

{#if dragged && x && y}
	<DragGhost {x} {y}>
		<div
			style="--bgc:black; --pl:8px; --pr:8px; --pt:4px; --pb:4px; --radius:0.5rem; --maxw:160px;"
			class="backdrop-blur-2xl w-fit"
		>
			<div style="--d:flex; --ai:center; --gg:4px;">
				<FolderOpen className="size-3.5" strokeWidth="2" />
				<div style="--size:0.75rem; --lh:1rem; --c:#ffffff;" class="line-clamp-1">
					{folders[folderId].name}
				</div>
			</div>
		</div>
	</DragGhost>
{/if}

<div style="--pos:relative;" bind:this={folderElement} draggable="true" class={className}>
	{#if draggedOver}
		<div
			style="--pos:absolute; --top:0; --left:0; --w:100%; --h:100%; --bgc:gray-100/50; --dark-bgc:gray-700/20; --bgc:opacity-50; --dark-bgc:opacity-10; --z:50;"
			class="rounded-xs pointer-events-none touch-none"
		></div>
	{/if}

	<Collapsible
		bind:open
		className="w-full"
		buttonClassName="w-full"
		hide={(folders[folderId]?.childrenIds ?? []).length === 0 &&
			(folders[folderId].items?.chats ?? []).length === 0}
		on:change={(e) => {
			dispatch('open', e.detail);
		}}
	>
		<!-- svelte-ignore a11y-no-static-element-interactions -->
		<div style="--w:100%;" class="group">
			<button
				style="--pos:relative; --w:100%; --pt:6px; --pb:6px; --pl:8px; --pr:8px; --radius:0.375rem; --d:flex; --ai:center; --gg:6px; --size:0.75rem; --lh:1rem; --c:#6b7280; --dark-c:#6b7280; --weight:500; --tn:all 0.15s ease-in-out;"
				id="folder-{folderId}-button"
				class="hover:bg-gray-100 dark:hover:bg-gray-900"
				on:dblclick={() => {
					editHandler();
				}}
			>
				<div>
					{#if open}
						<ChevronDown className=" size-3" strokeWidth="2.5" />
					{:else}
						<ChevronRight className=" size-3" strokeWidth="2.5" />
					{/if}
				</div>

				<div style="--fx:1; --jc:start; --c:start;" class="translate-y-[0.5px] line-clamp-1">
					{#if edit}
						<input
							id="folder-{folderId}-input"
							type="text"
							bind:value={name}
							on:focus={(e) => {
								e.target.select();
							}}
							on:blur={() => {
								nameUpdateHandler();
								edit = false;
							}}
							on:click={(e) => {
								// Prevent accidental collapse toggling when clicking inside input
								e.stopPropagation();
							}}
							on:mousedown={(e) => {
								// Prevent accidental collapse toggling when clicking inside input
								e.stopPropagation();
							}}
							on:keydown={(e) => {
								if (e.key === 'Enter') {
									nameUpdateHandler();
									edit = false;
								}
							}}
							class="w-full h-full bg-transparent text-gray-500 dark:text-gray-500 outline-hidden"
						/>
					{:else}
						{folders[folderId].name}
					{/if}
				</div>

				<button
					style="--pos:absolute; --z:10; --right:8px; --as:center; --d:flex; --ai:center; --dark-c:#d1d5db;"
					class="invisible group-hover:visible"
					on:pointerup={(e) => {
						e.stopPropagation();
					}}
				>
					<FolderMenu
						on:rename={() => {
							// Requires a timeout to prevent the click event from closing the dropdown
							setTimeout(() => {
								editHandler();
							}, 200);
						}}
						on:delete={() => {
							showDeleteConfirm = true;
						}}
						on:export={() => {
							exportHandler();
						}}
					>
						<button
							style="--p:2px; --radius:0.5rem;"
							class="dark:hover:bg-gray-850 touch-auto"
							on:click={(e) => {}}
						>
						</button></FolderMenu
					>
				</button>
			</button>
		</div>

		<div style="--w:100%;" slot="content">
			{#if (folders[folderId]?.childrenIds ?? []).length > 0 || (folders[folderId].items?.chats ?? []).length > 0}
				<div
					style="--ml:12px; --pl:4px; --mt:[1px]; --d:flex; --fd:column; --ofy:auto; --bc:s; --bc:#f3f4f6; --dark-bdc:#111827;"
					class="scrollbar-hidden"
				>
					{#if folders[folderId]?.childrenIds}
						{@const children = folders[folderId]?.childrenIds
							.map((id) => folders[id])
							.sort((a, b) =>
								a.name.localeCompare(b.name, undefined, {
									numeric: true,
									sensitivity: 'base'
								})
							)}

						{#each children as childFolder (`${folderId}-${childFolder.id}`)}
							<svelte:self
								{folders}
								folderId={childFolder.id}
								parentDragged={dragged}
								on:import={(e) => {
									dispatch('import', e.detail);
								}}
								on:update={(e) => {
									dispatch('update', e.detail);
								}}
								on:change={(e) => {
									dispatch('change', e.detail);
								}}
							/>
						{/each}
					{/if}

					{#if folders[folderId].items?.chats}
						{#each folders[folderId].items.chats as chat (chat.id)}
							<ChatItem
								id={chat.id}
								title={chat.title}
								on:change={(e) => {
									dispatch('change', e.detail);
								}}
							/>
						{/each}
					{/if}
				</div>
			{/if}
		</div>
	</Collapsible>
</div>
