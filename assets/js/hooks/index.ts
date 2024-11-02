import { moveNode } from "./node";
import {
  handleBlur,
  handleFocus,
  handleFocusNode,
  handleMoveNodes,
  handleSetContent,
} from "./events/handler";
import { keydown, toggleCollapse } from "./events/listener";

import Sortable from "../../vendor/sortable";
import Quill from "../../vendor/quill";

export const Hooks = {
  outline: {
    selector: ".node",
    mounted() {
      this.handleEvent("blur", handleBlur.bind(this));
      this.handleEvent("focus", handleFocus.bind(this));
      this.handleEvent("focus_node", handleFocusNode.bind(this));
      this.handleEvent("move_nodes", handleMoveNodes.bind(this));
      this.handleEvent("set_content", handleSetContent.bind(this));
      this.el.addEventListener("keydown", keydown.bind(this));
      this.el.addEventListener("toggle_collapse", toggleCollapse.bind(this));

      const collapsedStatus = localStorage.getItem(this.el.id) || "{}";
      const collapsed = JSON.parse(collapsedStatus);

      const nodes = this.el.querySelectorAll(this.selector);
      nodes.forEach((node: HTMLDivElement) => {
        const { uuid } = moveNode(node);
        node.toggleAttribute("data-collapsed", !!collapsed[uuid]);
      });

      // const nestedSortables = [].slice.call(
      //   document.querySelectorAll(".children")
      // );

      // // Loop through each nested sortable element
      // for (var i = 0; i < nestedSortables.length; i++) {
      //   new Sortable(nestedSortables[i], {
      //     group: this.el.id,
      //     handle: ".handle",
      //     animation: 150,
      //     fallbackOnBody: true,
      //     swapThreshold: 0.65,
      //   });
      // }

      // this.sortable = Sortable.create(this.el, {
      //   group: "nested",
      //   handle: ".handle",
      //   animation: 150,
      // });
    },
    updated() {
      // this.sortable.destroy();

      const nodes = this.el.querySelectorAll(this.selector);
      nodes.forEach((node: HTMLDivElement) => {
        moveNode(node);
      });
    },
  },
};
