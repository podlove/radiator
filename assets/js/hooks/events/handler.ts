import { NodeData, UserAction } from "../types";
import {
  getNodeById,
  moveNode,
  setData,
  setContent,
  focusNode,
  addEditingUserLabel,
  removeEditingUserLabel,
} from "../node";

export function handleBlur({ uuid, user_name }: UserAction) {
  // const node = getNodeById(uuid)!;
  removeEditingUserLabel(user_name);
}

export function handleFocus({ uuid, user_name }: UserAction) {
  const node = getNodeById(uuid)!;
  removeEditingUserLabel(user_name);
  addEditingUserLabel(node, user_name);
}

export function handleFocusNode({ uuid }: NodeData) {
  const node = getNodeById(uuid);
  node && focusNode(node);
}

export function handleMoveNodes({ nodes }: { nodes: NodeData[] }) {
  nodes.forEach(({ uuid, parent_id, prev_id }: NodeData) => {
    const node = getNodeById(uuid)!;
    setData(node, "parent", parent_id || "");
    setData(node, "prev", prev_id || "");

    moveNode(node);
  });
}

export function handleSetContent({ uuid, content }: any) {
  const node = getNodeById(uuid)!;
  setContent(node, content);
}
