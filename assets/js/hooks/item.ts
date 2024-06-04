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
  item.className = "my-1 bg-gray-100 data-[dirty=true]:bg-red-100";
  item.setAttribute("data-parent", parent_id || "");
  item.setAttribute("data-prev", prev_id || "");

  const link = document.createElement("a");
  link.className = "block float-left my-0.5 bg-gray-200 rounded-full";
  link.href = `#${uuid}`;
  link.innerHTML =
    '<svg viewBox="0 0 18 18" fill="currentColor" class="w-5 h-5"><circle cx="9" cy="9" r="3.5"></circle></svg>';
  item.appendChild(link);

  const contentWrap = document.createElement("div");
  contentWrap.className = "ml-5 bg-gray-300 content";
  contentWrap.contentEditable = "true";
  item.appendChild(contentWrap);

  const span = document.createElement("span");
  span.className = "bg-gray-400 innerContent";
  span.textContent = content || " ";
  contentWrap.appendChild(span);

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

  const span = item.querySelector(".innerContent") as HTMLSpanElement;
  if (span.textContent != newContent) span.textContent = newContent;

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

  item.setAttribute("data-parent", parent_id || "");
  item.setAttribute("data-prev", prev_id || "");

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
  const contentWrap = item.querySelector(".innerContent") as HTMLDivElement;
  contentWrap.focus();

  if (toEnd) {
    const range = document.createRange();
    range.setStart(contentWrap, 0);
    range.collapse(true);

    const selection = window.getSelection();
    selection?.removeAllRanges();
    selection?.addRange(range);
  }
}

export function setItemDirty(item: HTMLDivElement, dirty: boolean) {
  item.setAttribute("data-dirty", dirty ? "true" : "false");
}
