import { Node } from "../types";
import {
  changeItemContent,
  cleanItem,
  createItem,
  deleteItem,
  moveItem,
  getItemById,
} from "../item";
import { getNodeByItem } from "../node";

export function handleInsert({
  node,
  next_id,
}: {
  node: Node;
  next_id: string | undefined;
}) {
  const container: HTMLDivElement = this.el.querySelector(".nodes");

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
