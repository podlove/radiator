import { Node } from "../types";
import { createItem, updateItem, deleteItem, focusItem } from "../item";

export function handleList({ nodes }: { nodes: Node[] }) {
  const container: HTMLOListElement = this.el;

  if (nodes.length == 0) {
    const node: Node = {
      temp_id: self.crypto.randomUUID(),
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

  const item = createItem(node);
  container.append(item);
}

export function handleUpdate(node: Node) {
  const container: HTMLOListElement = this.el;

  updateItem(node, container);
}

export function handleDelete(node: Node) {
  deleteItem(node);
}
