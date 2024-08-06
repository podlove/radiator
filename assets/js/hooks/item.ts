import { Node } from "./types";
import { getNodeByItem } from "./node";

export function createItem({ uuid, content, parent_id, prev_id, dirty }: Node) {
  /*
  <div projectid="50f56aa7-bfda-355e-9687-3586f52e957c" class="project open">
    <div tabindex="-1" class="name">
      <a href="/#/3586f52e957c" data-handbook="bullet.handle" class="bullet" data-pre-drag-click="true">
        <svg width="100%" height="100%" viewBox="0 0 18 18" fill="currentColor" class="zoomBulletIcon">
          <circle cx="9" cy="9" r="3.5"></circle>
        </svg>
      </a>
      <div class="prefix"></div>
      <div class="content" contenteditable="true">
        <span class="innerContentContainer">Parent-Text</span>
      </div>
      <div class="nameButtons"></div>
      <a class="expand" data-handbook="expand.toggle">
        <div class="">
          <svg width="20" height="20" viewBox="0 0 20 20" class="">
            <path d="M13.75 9.56879C14.0833 9.76124 14.0833 10.2424 13.75 10.4348L8.5 13.4659C8.16667 13.6584 7.75 13.4178 7.75 13.0329L7.75 6.97072C7.75 6.58582 8.16667 6.34525 8.5 6.5377L13.75 9.56879Z" stroke="none" fill="currentColor"></path>
          </svg>
        </div>
      </a>
    </div>
    <div class="drop-line">
      <div class="line"></div>
    </div>
    <div class="children">
      <div projectid="f88abf4e-a7ac-f806-733e-053415351c8b" class="project task">
        <div tabindex="-1" class="name">
          <a href="/#/053415351c8b" data-handbook="bullet.handle" class="bullet">
            <svg width="100%" height="100%" viewBox="0 0 18 18" fill="currentColor" class="zoomBulletIcon">
              <circle cx="9" cy="9" r="3.5"></circle>
            </svg>
          </a>
          <div class="prefix"></div>
          <div class="content" contenteditable="true">
            <span class="innerContentContainer">Child-Test</span>
          </div>
          <div class="nameButtons"></div>
          <a class="expand" data-handbook="expand.toggle"></a>
        </div>
        <div class="drop-line">
          <div class="line"></div>
        </div>
      </div>
      <svg viewBox="0 0 20 20" class="addSiblingButton">
        <circle cx="10.5" cy="10.5" r="9" fill="var(--wf-button-background-secondary)"></circle>
        <line x1="6" y1="10.5" x2="15" y2="10.5" stroke="var(--wf-icon-secondary)" stroke-width="1"></line>
        <line x1="10.5" y1="6" x2="10.5" y2="15" stroke="var(--wf-icon-secondary)" stroke-width="1"></line>
      </svg>
    </div>
  </div>
  */

  const item = document.createElement("div");
  item.id = `outline-node-${uuid}`;
  item.className = "item group relative my-1 data-[dirty=true]:bg-red-100";
  item.setAttribute("data-parent", parent_id || "");
  item.setAttribute("data-prev", prev_id || "");

  item.innerHTML = `<button class="absolute top-0.5 left-0 group-[.collapsed]:-rotate-90 duration-200 z-10">
    <svg width="20" height="20" viewBox="0 0 20 20" class="rotate-90 text-gray-500 hover:text-black">
      <path d="M13.75 9.56879C14.0833 9.76124 14.0833 10.2424 13.75 10.4348L8.5 13.4659C8.16667 13.6584 7.75 13.4178 7.75 13.0329L7.75 6.97072C7.75 6.58582 8.16667 6.34525 8.5 6.5377L13.75 9.56879Z" stroke="none" fill="currentColor"></path>
    </svg>
  </button>
  <a href="#${uuid}" class="absolute top-0 left-4 my-0.5 rounded-full text-gray-500 hover:text-black">
    <svg viewBox="0 0 18 18" fill="currentColor" class="w-5 h-5"><circle cx="9" cy="9" r="3.5"></circle></svg>
  </a>
  <div class="ml-10 content" contentEditable>${content}</div>
  <div class="ml-4 children group-[.collapsed]:hidden"></div>`;

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
