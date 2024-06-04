import { Node } from "../types";
import {
  changeItemContent,
  cleanItem,
  createItem,
  deleteItem,
  focusItem,
  moveItem,
} from "../item";

export function handleList({ nodes }: { nodes: Node[] }) {
  const container: HTMLDivElement = this.el.querySelector(".children");

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
    moveItem(node, container, true);
  });

  // focus last item
  const lastItem = container.lastElementChild as HTMLDivElement;
  focusItem(lastItem);
}

export function handleInsert({ node }: { node: Node }) {
  const container: HTMLDivElement = this.el.querySelector(".children");

  const item = createItem(node);
  container.append(item);
  moveItem(node, container);
}

export function handleContentChange({ node }: { node: Node }) {
  changeItemContent(node);
}

export function handleDelete({ node }: { node: Node }) {
  deleteItem(node);
}

export function handleClean({ node }: { node: Node }) {
  cleanItem(node);
}
