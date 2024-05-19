import { Node } from "../types";
import {
  getItemByNode,
  createItem,
  updateItem,
  deleteItem,
  focusItem,
  getItemById,
  setItemDirty,
} from "../item";

export function handleList({ nodes }: { nodes: Node[] }) {
  const container: HTMLOListElement = this.el;

  if (nodes.length == 0) {
    const node: Node = {
      uuid: self.crypto.randomUUID(),
      content: "",
      dirty: true,
    };
    nodes = [node];
  }

  // add all items
  nodes.forEach((node) => {
    const item = createItem(node);
    container.append(item);
  });

  // sort & indent all items
  nodes.forEach((node) => {
    updateItem(node, container);
  });

  // focus last item
  const lastItem = container.lastElementChild as HTMLLIElement;
  focusItem(lastItem);
}

export function handleInsert({ node }: { node: Node }) {
  const container: HTMLOListElement = this.el;

  const item = getItemByNode(node);
  if (item) {
    node.dirty = false;
    updateItem(node, container);
  } else {
    const newItem = createItem(node);
    container.append(newItem);
  }
}

export function handleContentChange({ node }: { node: Node }) {
  const item = getItemById(node.uuid);
  if (!item) {
    console.error("item not found");
    return;
  }

  const input = item.firstChild!;
  input.textContent = node.content;

  setItemDirty(item, false);
}

export function handleDelete({ node }: { node: Node }) {
  deleteItem(node);
}

export function handleClean({ node }: { node: Node }) {
  const container: HTMLOListElement = this.el;

  node.dirty = false;
  updateItem(node, container);
}
