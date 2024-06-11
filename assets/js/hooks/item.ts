import { Node } from "./types";
import { getNodeByItem } from "./node";

export function createItem({ uuid, content, parent_id, prev_id, dirty }: Node) {
  // <div id="outline-node-uuid" class="item">
  //   <a class="bullet" href="/#/UUID">
  //     <svg viewBox="0 0 18 18" fill="currentColor" class="">
  //       <circle cx="9" cy="9" r="3.5"></circle>
  //     </svg></a>
  //   <div class="content" contenteditable="true">
  //     <span class="innerContent">Node Content</span>
  //   </div>
  //   <div class="children"></div>
  // </div>

  const item = document.createElement("div");
  item.id = `outline-node-${uuid}`;
  item.className = "my-1 data-[dirty=true]:bg-red-100";
  item.setAttribute("data-parent", parent_id || "");
  item.setAttribute("data-prev", prev_id || "");

  const link = document.createElement("a");
  link.className = "block float-left my-0.5 rounded-full";
  link.href = `#${uuid}`;
  link.innerHTML =
    '<svg viewBox="0 0 18 18" fill="currentColor" class="w-5 h-5"><circle cx="9" cy="9" r="3.5"></circle></svg>';
  item.appendChild(link);

  const input = document.createElement("div");
  input.className = "ml-5 content";
  input.contentEditable = "true";
  input.textContent = content || "";
  item.appendChild(input);

  const childContainer = document.createElement("div");
  childContainer.className = "ml-5 children";
  item.appendChild(childContainer);

  setItemDirty(item, dirty);

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
  force: boolean = false,
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
  parent_id: string | undefined,
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

function getItemById(uuid: string | undefined) {
  if (!uuid) return null;

  return document.getElementById(`outline-node-${uuid}`) as HTMLDivElement;
}

export function getItemByEvent(event: Event): HTMLDivElement {
  const target = <HTMLDivElement>event.target;
  const item = <HTMLDivElement>target.parentElement!;

  return item;
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
