import { Node } from "../types";
import {
  getItemByNode,
  createItem,
  updateItem,
  deleteItem,
  focusItem,
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

export function handleInsert(node: Node) {
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

export function handleUpdate(node: Node) {
  const container: HTMLOListElement = this.el;

  updateItem(node, container);
}

export function handleDelete(node: Node) {
  deleteItem(node);
}

export function handleClean(node: Node) {
  const container: HTMLOListElement = this.el;

  node.dirty = false;
  updateItem(node, container);
}
