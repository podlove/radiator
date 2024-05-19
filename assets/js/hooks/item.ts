import { Node } from "./types";

export function createItem({ uuid, content, parent_id, prev_id, dirty }: Node) {
  const input = document.createElement("div");
  input.textContent = content;
  input.contentEditable = "true"; // firefox does not support "plaintext-only"

  const ol = document.createElement("ol");
  ol.className = "list-disc";

  const item = document.createElement("li");
  item.id = "outline-node-" + uuid;
  item.className = dirty ? "my-1 ml-4 bg-red-100" : "my-1 ml-4";

  item.setAttribute("data-parent", parent_id || "");
  item.setAttribute("data-prev", prev_id || "");
  item.setAttribute("data-dirty", dirty ? "true" : "false");

  item.appendChild(input);
  item.appendChild(ol);

  return item;
}

export function updateItem(
  { uuid, content, parent_id, prev_id, dirty }: Node,
  container: HTMLOListElement
) {
  const item = getItemById(uuid);
  console.log({ item, uuid, content, parent_id, prev_id, dirty });
  if (!item) return;

  const input = item.firstChild!;
  input.textContent = content;

  item.className = dirty ? "my-1 ml-4 bg-red-100" : "my-1 ml-4";

  item.setAttribute("data-parent", parent_id || "");
  item.setAttribute("data-prev", prev_id || "");
  item.setAttribute("data-dirty", dirty ? "true" : "false");

  const prevItem = getItemById(prev_id);
  const parentItem = getItemById(parent_id);

  if (prevItem) {
    prevItem.after(item);
  } else if (parentItem) {
    parentItem.querySelector("ol")?.append(item);
  } else {
    container.append(item);
  }
}

export function deleteItem({ uuid }: Node) {
  const item = getItemById(uuid);
  if (!item) return;

  item.parentNode!.removeChild(item);
}

export function getItemByNode({ uuid }: Node) {
  return getItemById(uuid);
}

function getItemById(uuid: string | undefined) {
  if (!uuid) return null;

  return document.getElementById("outline-node-" + uuid) as HTMLLIElement;
}

export function getItemByEvent(event: Event): HTMLLIElement {
  const target = <HTMLDivElement>event.target;
  const item = <HTMLLIElement>target.parentElement!;

  return item;
}

export function focusItem(item: HTMLLIElement, toEnd: boolean = true) {
  const input = item.firstChild as HTMLDivElement;
  input.focus();

  if (toEnd) {
    const range = document.createRange();
    range.setStart(input, 1);
    range.collapse(true);

    const selection = window.getSelection();
    selection?.removeAllRanges();
    selection?.addRange(range);
  }
}

// export function indentNode(node: Node) {
//   // const node = event.target.parentNode
//   // const parentNode = event.target.parentNode.previousSibling
// }

// export function outdentNode(node: Node) {
// }

export function setItemDirty(item: HTMLLIElement, dirty: boolean) {
  item.className = dirty ? "my-1 ml-4 bg-red-100" : "my-1 ml-4";
  item.setAttribute("data-dirty", dirty ? "true" : "false");
}
