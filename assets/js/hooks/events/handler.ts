import { Node, UUID } from "../types";
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
      event_id: self.crypto.randomUUID(),
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

interface NodeEvent {
  node: Node;
  event_id: UUID;
}

export function handleInsert({ node, event_id }: NodeEvent) {
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

export function handleUpdate({ node, event_id }: NodeEvent) {
  const container: HTMLOListElement = this.el;

  node.dirty = false;
  updateItem(node, container);
}

export function handleDelete({ node, event_id }: NodeEvent) {
  deleteItem(node);
}
