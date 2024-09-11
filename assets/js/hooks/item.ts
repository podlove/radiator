import { Node } from "./types";
import { getNodeByItem } from "./node";

export function createItem({
  uuid,
  content,
  parent_id,
  prev_id,
  collapsed,
  dirty,
}: Node) {
  const item = document.createElement("div");
  item.id = `outline-node-${uuid}`;
  item.className = "item group relative my-1 data-[dirty=true]:bg-red-100";

  item.innerHTML = `<button class="absolute top-0.5 left-0 group-[.collapsed]:-rotate-90 duration-200 z-10">
    <svg width="20" height="20" viewBox="0 0 20 20" class="rotate-90 text-gray-500 hover:text-black">
      <path d="M13.75 9.56879C14.0833 9.76124 14.0833 10.2424 13.75 10.4348L8.5 13.4659C8.16667 13.6584 7.75 13.4178 7.75 13.0329L7.75 6.97072C7.75 6.58582 8.16667 6.34525 8.5 6.5377L13.75 9.56879Z" stroke="none" fill="currentColor"></path>
    </svg>
  </button>
  <a href="#${uuid}" class="absolute top-0 left-5 my-0.5 rounded-full text-gray-500 hover:text-black">
    <svg viewBox="0 0 18 18" fill="currentColor" class="w-5 h-5"><circle cx="9" cy="9" r="3.5"></circle></svg>
  </a>
  <div class="ml-10 content" contentEditable></div>
  <div class="ml-4 children group-[.collapsed]:hidden"></div>`;

  setContent(item, content);

  setAttribute(item, "parent", parent_id);
  setAttribute(item, "prev", prev_id);

  setItemDirty(item, dirty);
  setItemCollapsed(item, collapsed);

  return item;
}

export function changeItemContent({ uuid, content, dirty }: Node) {
  const item = getItemById(uuid);
  if (!item) return;

  const newContent = content || "";

  const input = item.querySelector(".content") as HTMLDivElement;
  if (input.textContent != newContent) input.textContent = newContent;

  setItemDirty(item, dirty);

  return item;
}

export function moveItem(
  { uuid, parent_id, prev_id, dirty }: Node,
  container: HTMLDivElement,
  force: boolean = false
) {
  const item = getItemById(uuid);
  if (!item) return;

  const currentNode = getNodeByItem(item);
  if (
    !force &&
    currentNode.parent_id == parent_id &&
    currentNode.prev_id == prev_id
  )
    return;

  setItemParent(item, parent_id);
  setItemPrev(item, prev_id);

  const prevItem = getItemById(prev_id);
  const parentItem = getItemById(parent_id);

  if (prevItem) {
    prevItem.after(item);
  } else if (parentItem) {
    parentItem.querySelector(".children")?.append(item);
  } else {
    container.prepend(item);
  }

  setItemDirty(item, dirty);

  return item;
}

export function setItemParent(
  item: HTMLDivElement,
  parent_id: string | undefined
) {
  item.setAttribute("data-parent", parent_id || "");
}

export function setItemPrev(item: HTMLDivElement, prev_id: string | undefined) {
  item.setAttribute("data-prev", prev_id || "");
}

export function deleteItem({ uuid }: Node) {
  const item = getItemById(uuid);
  if (!item) return;

  item.parentNode!.removeChild(item);
}

export function cleanItem({ uuid }: Node) {
  const item = getItemById(uuid);
  item && setItemDirty(item, false);

  return item;
}

export function getItemByNode({ uuid }: Node) {
  return getItemById(uuid);
}

export function getItemById(uuid: string | undefined) {
  if (!uuid) return null;

  return document.getElementById(`nodes-form-${uuid}`) as HTMLDivElement;
}

export function getItemByEvent(event: Event) {
  const target = event.target as HTMLDivElement;
  return target.closest(".item") as HTMLDivElement;
}

export function focusItem(item: HTMLDivElement, toEnd: boolean = true) {
  const input = item.querySelector(".content") as HTMLDivElement;
  input.focus();

  if (toEnd) {
    const range = document.createRange();
    range.setStart(input, 0);
    range.collapse(true);

    const selection = window.getSelection();
    selection?.removeAllRanges();
    selection?.addRange(range);
  }
}

export function setItemDirty(item: HTMLDivElement, dirty: boolean) {
  item.setAttribute("data-dirty", dirty ? "true" : "false");
}

////  ////  ////  ////

export function upsertItem(node: Node, container: HTMLDivElement) {
  const { uuid } = node;

  let item = getItemById(uuid);
  if (!item) {
    item = createItem(node);
  }

  return updateItem(item, node, container);
}

function updateItem(
  item: HTMLDivElement,
  node: Node,
  container: HTMLDivElement
) {
  const { content, parent_id, prev_id, collapsed, dirty } = node;

  const oldNode = getNodeByItem(item);

  oldNode.content != content && setContent(item, content);

  oldNode.parent_id != parent_id && setAttribute(item, "parent", parent_id);
  oldNode.prev_id != prev_id && setAttribute(item, "prev", prev_id);
  oldNode.collapsed != collapsed && setItemCollapsed(item, collapsed);
  oldNode.dirty != dirty && setAttribute(item, "dirty", dirty);

  if (oldNode.parent_id != parent_id || oldNode.prev_id != prev_id) {
    newMoveItem(item, node, container);
  }

  return item;
}

function newMoveItem(
  item: HTMLDivElement,
  node: Node,
  container: HTMLDivElement
) {
  const { parent_id, prev_id } = node;

  const prevItem = getItemById(prev_id);
  const parentItem = getItemById(parent_id);

  if (prevItem) {
    prevItem.after(item);
  } else if (parentItem) {
    parentItem.querySelector(".children")!.append(item);
  } else {
    container.prepend(item);
  }
}

function setContent(item: HTMLDivElement, content: string = "") {
  const input = item.querySelector(".content") as HTMLDivElement;
  input.textContent = content;
}

function setItemCollapsed(item: HTMLDivElement, collapsed: boolean = false) {
  item.classList.toggle("collapsed", collapsed);
  item.setAttribute("data-collapsed", String(collapsed));
}

export function setAttribute(
  item: HTMLDivElement,
  key: string,
  value: string | number | boolean | undefined
) {
  const attrValue = value === undefined ? "" : String(value);
  item.setAttribute(`data-${key}`, attrValue);
}

/*
  Showing which users are editing a node.
  The color is based on the ascii of user's name first char and the length of user's name.
  The tailwindcss color names are build dynamically.
*/

const colors = [
  "indigo",
  "violet",
  "purple",
  "fuchsia",
  "pink",
  "sky",
  "orange",
  "lime",
  "amber",
  "emerald",
  "teal",
  "cyan",
];
const intesities = ["500", "600", "700"];

function pickColor(user_name: string) {
  const colorIndex = user_name.charCodeAt(0) % 12;
  const intesity = user_name.length % 3;
  return `bg-${colors[colorIndex]}-${intesities[intesity]}`;
}

export function addEditingUserLabel(item: HTMLDivElement, user_name: string) {
  item!.querySelector(".editing")!.innerHTML +=
    `<span id="${user_name}" class="mr-1 px-1 rounded ${pickColor(user_name)}">${user_name}</span>`;
}

export function removeEditingUserLabel(
  item: HTMLDivElement,
  user_name: string,
) {
  const span = item!.querySelector(`#${user_name}`)!;
  span.remove();
}
