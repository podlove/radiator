import { NodeData, UserAction } from "../types";
import {
  getNodeById,
  addEditingUserLabel,
  removeEditingUserLabel,
} from "../node";
import { moveNode, setAttribute } from "../node";

export function handleFocus({ uuid, user_name }: UserAction) {
  const node = getNodeById(uuid)!;
  addEditingUserLabel(node, user_name);
}

export function handleBlur({ uuid, user_name }: UserAction) {
  const node = getNodeById(uuid)!;
  removeEditingUserLabel(node, user_name);
}

export function handleMove({ uuid, parent_id, prev_id }: NodeData) {
  const node = getNodeById(uuid)!;
  setAttribute(node, "parent", parent_id);
  setAttribute(node, "prev", prev_id);

  moveNode(node);
}
