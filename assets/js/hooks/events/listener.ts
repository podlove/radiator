import { Node } from "../types";
import {
  createItem,
  updateItem,
  deleteItem,
  getItemByNode,
  focusItem,
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
  node.dirty = true;
  this.pushEvent("update_node", node);
}

export function keydown(event: KeyboardEvent) {
  const container: HTMLOListElement = this.el;

  const selection = window.getSelection();
  // const range = selection?.getRangeAt(0)

  const node = getNodeByEvent(event);

  const item = getItemByNode(node)!;
  const prevItem = item.previousSibling as HTMLLIElement | null;
  const nextItem = item.nextSibling as HTMLLIElement | null;

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
      if (selection?.anchorOffset != node.content.length) return;
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

      updateItem(node, container);
      this.pushEvent("update_node", node);

      const newNode: Node = {
        temp_id: self.crypto.randomUUID(),
        content: content?.substring(splitPos),
        parent_id: node.parent_id,
        prev_id: node.uuid,
        dirty: true,
      };

      this.pushEvent("create_node", newNode);
      // this.pushEvent("create_node", newNode, (node: Node, _ref: number) => {
      //   const newItem = createItem(node);
      //   item.after(newItem);
      //   focusItem(newItem, false);
      // });
      break;

    case "Backspace":
      if (selection?.anchorOffset != 0) return;
      event.preventDefault();

      if (!prevItem || !prevNode) return;

      prevNode.content += node.content;
      updateItem(prevNode, container);
      focusItem(prevItem);
      prevNode.dirty = true;
      this.pushEvent("update_node", prevNode);

      deleteItem(node);
      node.dirty = true;
      this.pushEvent("delete_node", node);
      break;

    case "Delete":
      if (selection?.anchorOffset != node.content.length) return;
      event.preventDefault();

      if (!nextItem || !nextNode) return;

      node.content += nextNode.content;
      updateItem(node, container);
      focusItem(item);
      node.dirty = true;
      this.pushEvent("update_node", node);

      deleteItem(nextNode);
      nextNode.dirty = true;
      this.pushEvent("delete_node", nextNode);
      break;

    // case "Tab":
    //   event.preventDefault();

    //   if (event.shiftKey) {
    //     if (node.parent_id) {
    //       // outdent
    //       node.prev_id = node.parent_id;
    //       node.parent_id = undefined;
    //       updateItem(node, container);

    //       focusItem(item);
    //       this.pushEvent("update_node", node);
    //     }
    //   } else {
    //     if (node.prev_id) {
    //       // indent
    //       node.parent_id = node.prev_id;
    //       node.prev_id = undefined; // TODO: prev_id should be the id of the last child of the parent node
    //       updateItem(node, container);

    //       focusItem(item);
    //       this.pushEvent("update_node", node);
    //     }
    //   }
    //   break;
  }
}
