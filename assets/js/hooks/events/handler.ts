import { Node, UserAction } from "../types";
import {
  getItemById,
  addEditingUserLabel,
  removeEditingUserLabel,
} from "../item";
import { moveNode, setAttribute } from "../node";

export function handleFocus({ uuid, user_name }: UserAction) {
  const item = getItemById(uuid)!;
  addEditingUserLabel(item, user_name);
}

export function handleBlur({ uuid, user_name }: UserAction) {
  const item = getItemById(uuid)!;
  removeEditingUserLabel(item, user_name);
}

export function handleMove({ uuid, parent_id, prev_id }: Node) {
  const node = getItemById(uuid)!;
  setAttribute(node, "parent", parent_id);
  setAttribute(node, "prev", prev_id);

  moveNode(node);
}
