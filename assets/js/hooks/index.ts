import { moveNode, setAttribute } from "./node";
import {
  getItemById,
  addEditingUserLabel,
  removeEditingUserLabel,
} from "./item";

export const Hooks = {
  outline: {
    selector: '.node:not([data-processed="true"]',
    mounted() {
      this.handleEvent("focus", ({ uuid, user_name }) => {
        const item = getItemById(uuid)!;
        addEditingUserLabel(item, user_name);
      });

      this.handleEvent("blur", ({ uuid, user_name }) => {
        const item = getItemById(uuid)!;
        removeEditingUserLabel(item, user_name);
      });

      this.handleEvent("move_node", ({ uuid, parent_id, prev_id }) => {
        const node = getItemById(uuid)!;
        setAttribute(node, "parent", parent_id);
        setAttribute(node, "prev", prev_id);

        moveNode(node);
      });

      this.el.addEventListener("keydown", (event) => {
        if (event.key == "Tab") {
          event.preventDefault();
        }
      });

      this.el.addEventListener("toggle_collapse", ({ detail: { uuid } }) => {
        const item = getItemById(uuid);
        item!.toggleAttribute("data-collapsed");

        const collapsedStatus = localStorage.getItem(this.el.id) || "{}";
        const collapsed = JSON.parse(collapsedStatus);

        collapsed[uuid] = !collapsed[uuid];
        localStorage.setItem(this.el.id, JSON.stringify(collapsed));
      });

      const collapsedStatus = localStorage.getItem(this.el.id) || "{}";
      const collapsed = JSON.parse(collapsedStatus);

      const nodes = this.el.querySelectorAll(this.selector);
      nodes.forEach((node: HTMLDivElement) => {
        const { uuid } = moveNode(node);
        node.toggleAttribute("data-collapsed", !!collapsed[uuid]);

        setAttribute(node, "processed", true);
      });
    },
    updated() {
      const nodes = this.el.querySelectorAll(this.selector);
      nodes.forEach((node: HTMLDivElement) => {
        moveNode(node);
        setAttribute(node, "processed", true);
      });
    },
  },
};
