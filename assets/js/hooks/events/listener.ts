import { Node } from "../types";
import {
  changeItemContent,
  createItem,
  deleteItem,
  focusItem,
  getItemByNode,
  moveItem,
  setItemDirty,
  setItemParent,
  setItemPrev,
} from "../item";
import { getNodeByEvent, getNodeByItem } from "../node";

export function focusin(event: FocusEvent) {
  const { uuid } = getNodeByEvent(event);

  this.pushEvent("set_focus", uuid);
}

export function focusout(event: FocusEvent) {
  const { uuid } = getNodeByEvent(event);

  this.pushEvent("remove_focus", uuid);
}

export function input(event: Event) {
  const node = getNodeByEvent(event);
  const item = getItemByNode(node);
  item && setItemDirty(item, true);

  this.pushEvent("update_node_content", node);
}

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
      if (selection?.anchorOffset != 0) return;
      event.preventDefault();

      if (!prevItem || !prevNode) return;
      // TODO: if no prevItem exists, try to select the parent item

      focusItem(prevItem);
      this.pushEvent("set_focus", prevNode.uuid);
      break;

    case "ArrowDown":
      if (selection?.anchorOffset != node.content?.length) return;
      event.preventDefault();

      if (!nextItem || !nextNode) return;
      // TODO: if no nextItem exists, try to select the first child

      focusItem(nextItem);
      this.pushEvent("set_focus", nextNode.uuid);
      break;

    case "Enter":
      event.preventDefault();

      const splitPos = selection?.anchorOffset || 0;

      const content = node.content;
      node.content = content?.substring(0, splitPos);
      node.dirty = true;

      changeItemContent(node);
      this.pushEvent("update_node_content", node);

      const newNode: Node = {
        uuid: self.crypto.randomUUID(),
        content: content?.substring(splitPos),
        parent_id: node.parent_id,
        prev_id: node.uuid,
        dirty: true,
      };
      this.pushEvent("create_node", newNode);

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
      this.pushEvent("update_node_content", prevNode);

      deleteItem(node);
      this.pushEvent("delete_node", node);
      break;

    case "Delete":
      if (selection?.anchorOffset != node.content?.length) return;
      event.preventDefault();

      if (!nextItem || !nextNode) return;

      node.content += nextNode.content || "";
      node.dirty = true;
      changeItemContent(node);
      focusItem(item);
      this.pushEvent("update_node_content", node);

      deleteItem(nextNode);
      this.pushEvent("delete_node", nextNode);
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
          this.pushEvent("move_node", node);
        }
      } else {
        // indent
        if (node.prev_id) {
          node.parent_id = node.prev_id;
          node.prev_id = undefined; // TODO: prev_id should be the id of the last child of the parent node
          moveItem(node, container);

          focusItem(item);
          this.pushEvent("move_node", node);
        }
      }
      break;
  }
}
