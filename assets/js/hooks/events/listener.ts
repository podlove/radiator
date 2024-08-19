import { Node } from "../types";
import {
  changeItemContent,
  createItem,
  deleteItem,
  focusItem,
  getItemByNode,
  moveItem,
  setItemPrev,
} from "../item";
import { getNodeByEvent, getNodeByItem } from "../node";

export function keydown(event: KeyboardEvent) {
  const container: HTMLDivElement = this.el.querySelector(".children");

  const selection = window.getSelection();
  // const range = selection?.getRangeAt(0)

  const node = getNodeByEvent(event);

  const item = getItemByNode(node)!;
  const prevItem = item.previousSibling as HTMLDivElement | null;
  const nextItem = item.nextSibling as HTMLDivElement | null;

  const prevNode = prevItem && getNodeByItem(prevItem);
  const nextNode = nextItem && getNodeByItem(nextItem);

  switch (event.key) {
    case "ArrowUp":
      event.altKey && moveNodeUp(event, container, this);
      !event.altKey && moveCursorUp(event, this);

      break;

    case "ArrowDown":
      event.altKey && moveNodeDown(event, container, this);
      !event.altKey && moveCursorDown(event, this);

      break;

    case "Enter":
      event.preventDefault();

      const splitPos = selection?.anchorOffset || 0;

      const content = node.content;
      node.content = content?.substring(0, splitPos);
      node.dirty = true;

      changeItemContent(node);
      this.pushEventTo(this.el, "update_node_content", node);

      const newNode: Node = {
        uuid: self.crypto.randomUUID(),
        content: content?.substring(splitPos),
        parent_id: node.parent_id,
        prev_id: node.uuid,
        dirty: true,
      };
      this.pushEventTo(this.el, "create_node", newNode);

      const newItem = createItem(newNode);
      item.after(newItem);
      focusItem(newItem, false);

      const oldNextItem = newItem.nextSibling as HTMLDivElement | null;
      if (oldNextItem) {
        const nextNode = getNodeByItem(oldNextItem);
        nextNode.prev_id = newNode.uuid;
        nextNode.dirty = true;
        setItemPrev(oldNextItem, newNode.uuid);
      }
      break;

    case "Backspace":
      if (selection?.anchorOffset != 0) return;
      event.preventDefault();

      if (!prevItem || !prevNode) return;

      prevNode.content += node.content || "";
      prevNode.dirty = true;
      changeItemContent(prevNode);
      focusItem(prevItem);
      this.pushEventTo(this.el, "update_node_content", prevNode);

      deleteItem(node);
      this.pushEventTo(this.el, "delete_node", node);
      break;

    case "Delete":
      if (selection?.anchorOffset != node.content?.length) return;
      event.preventDefault();

      if (!nextItem || !nextNode) return;

      node.content += nextNode.content || "";
      node.dirty = true;
      changeItemContent(node);
      focusItem(item);
      this.pushEventTo(this.el, "update_node_content", node);

      deleteItem(nextNode);
      this.pushEventTo(this.el, "delete_node", nextNode);
      break;

    case "Tab":
      event.preventDefault();

      if (event.shiftKey) {
        // outdent
        if (node.parent_id) {
          node.prev_id = node.parent_id;
          node.parent_id = prevNode?.parent_id;
          moveItem(node, container);

          focusItem(item);
          this.pushEventTo(this.el, "move_node", node);
        }
      } else {
        // indent
        if (node.prev_id) {
          node.parent_id = node.prev_id;
          node.prev_id = undefined; // TODO: prev_id should be the id of the last child of the parent node
          moveItem(node, container);

          focusItem(item);
          this.pushEventTo(this.el, "move_node", node);
        }
      }
      break;
  }
}

function moveCursorUp(event: KeyboardEvent, outerThis: any) {
  const selection = window.getSelection();
  if (selection?.anchorOffset != 0) return;
  event.preventDefault();

  const node = getNodeByEvent(event);

  const item = getItemByNode(node)!;
  const prevItem = item.previousSibling as HTMLDivElement | null;

  const prevNode = prevItem && getNodeByItem(prevItem);
  if (!prevItem || !prevNode) return;
  // TODO: if no prevItem exists, try to select the parent item

  focusItem(prevItem);
  outerThis.pushEventTo(this.el, "set_focus", prevNode.uuid);
}

function moveCursorDown(event: KeyboardEvent, outerThis: any) {
  const selection = window.getSelection();
  const node = getNodeByEvent(event);

  const item = getItemByNode(node)!;
  const nextItem = item.nextSibling as HTMLDivElement | null;

  const nextNode = nextItem && getNodeByItem(nextItem);

  if (selection?.anchorOffset != node.content?.length) return;
  event.preventDefault();

  if (!nextItem || !nextNode) return;
  // TODO: if no nextItem exists, try to select the first child

  focusItem(nextItem);
  outerThis.pushEventTo(this.el, "set_focus", nextNode.uuid);
}

function moveNodeUp(
  event: KeyboardEvent,
  container: HTMLDivElement,
  outerThis: any
) {
  event.preventDefault();

  const node = getNodeByEvent(event);
  const item = getItemByNode(node)!;
  const prevItem = item.previousSibling as HTMLDivElement | null;
  const nextItem = item.nextSibling as HTMLDivElement | null;

  const prevNode = prevItem && getNodeByItem(prevItem);
  const nextNode = nextItem && getNodeByItem(nextItem);
  if (prevNode) {
    node.prev_id = prevNode.prev_id;
    prevNode.prev_id = node.uuid;
    if (nextNode) {
      nextNode.prev_id = prevNode.uuid;
      moveItem(nextNode, container);
      outerThis.pushEventTo(this.el, "move_node", nextNode);
    }
    moveItem(node, container);
    outerThis.pushEventTo(this.el, "move_node", node);
    moveItem(prevNode, container);
    outerThis.pushEventTo(this.el, "move_node", prevNode);

    focusItem(item);
  }
}

function moveNodeDown(
  event: KeyboardEvent,
  container: HTMLDivElement,
  outerThis: any
) {
  event.preventDefault();

  const node = getNodeByEvent(event);
  const item = getItemByNode(node)!;
  const prevItem = item.previousSibling as HTMLDivElement | null;
  const nextItem = item.nextSibling as HTMLDivElement | null;
  const nextNextItem = nextItem?.nextSibling as HTMLDivElement | null;

  const prevNode = prevItem && getNodeByItem(prevItem);
  const nextNode = nextItem && getNodeByItem(nextItem);
  const nextNextNode = nextNextItem && getNodeByItem(nextNextItem);

  if (nextNode) {
    node.prev_id = nextNode.uuid;
    if (prevNode) {
      nextNode.prev_id = prevNode.uuid;
      moveItem(nextNode, container);
      outerThis.pushEventTo(this.el, "move_node", nextNode);
    }
    if (nextNextNode) {
      nextNextNode.prev_id = node.uuid;
      moveItem(nextNextNode, container);
      outerThis.pushEventTo(this.el, "move_node", nextNextNode);
    }
    moveItem(node, container);
    outerThis.pushEventTo(this.el, "move_node", node);
    focusItem(item);
  }
}
