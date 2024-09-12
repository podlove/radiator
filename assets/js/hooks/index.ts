import { moveNode, setAttribute } from "./node";
import { handleFocus, handleBlur, handleMove } from "./events/handler";
import { keydown, toggleCollapse } from "./events/listener";

export const Hooks = {
  outline: {
    selector: '.node:not([data-processed="true"]',
    mounted() {
      this.handleEvent("focus", handleFocus.bind(this));
      this.handleEvent("blur", handleBlur.bind(this));
      this.handleEvent("move_node", handleMove.bind(this));

      this.el.addEventListener("keydown", keydown.bind(this));
      this.el.addEventListener("toggle_collapse", toggleCollapse.bind(this));

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
