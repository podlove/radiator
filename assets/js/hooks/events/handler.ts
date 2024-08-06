import { Node } from "../types";
import {
  changeItemContent,
  cleanItem,
  createItem,
  deleteItem,
  focusItem,
  moveItem,
  getItemById,
} from "../item";
import { getNodeByItem } from "../node";

export function handleList({ nodes }: { nodes: Node[] }) {
  const container: HTMLDivElement = this.el.querySelector(".children");

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

export function handleInsert({
  node,
  next_id,
}: {
  node: Node;
  next_id: string | undefined;
}) {
  const container: HTMLDivElement = this.el.querySelector(".children");

  const item = createItem(node);
  container.append(item);
  moveItem(node, container);
  const nextItem = getItemById(next_id) as HTMLDivElement;
  const nextNode = getNodeByItem(nextItem);
  nextNode.prev_id = node.uuid;
  nextNode.dirty = false;
  moveItem(nextNode, container);
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
