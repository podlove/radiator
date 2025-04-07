import { NodeData, Node, UUID } from "./types";

import {
  handleBlur,
  handleFocus,
  handleFocusNode,
  handleMoveNodes,
  handleSetContent,
} from "./events/handler";
import {
  input,
  click,
  keydown,
  toggleCollapse,
  selectTree,
} from "./events/listener";
import { getNodeData, getNodeDataByNode } from "./node";
import {
  moveNodesToCorrectPosition,
  getParentNode,
  getPrevNode,
  restoreCollapsedStatus,
} from "./tree";

import Sortable from "../../vendor/sortable";
// import Quill from "../../vendor/quill";

export const Hooks = {
  inbox: {
    selector: ".node",
    mounted() {
      this.handleEvent("select_all", () => {
        this.el
          .querySelectorAll("input.selected")
          .forEach((node: HTMLInputElement) => {
            node.checked = true;
          });
      });

      this.handleEvent("move_nodes_to_container", ({ container_id }) => {
        const selected = this.el.querySelectorAll("input.selected:checked");

        const uuid_list = Array.from(selected).map((node: any) => {
          const parent = node.closest(".node") as HTMLDivElement;
          const { uuid } = getNodeData(parent);
          return uuid;
        });
        this.pushEventTo(this.el, "move_nodes_to_container", {
          container_id,
          uuid_list,
        });
      });

      this.el.addEventListener("click", selectTree.bind(this));

      moveNodesToCorrectPosition.call(this);

      const nestedSortables = [...this.el.querySelectorAll(".children")];
      nestedSortables.forEach((element) => {
        new Sortable(element, {
          group: this.el.dataset.group,
          // animation: 150,
          // delay: 100,
          dragClass: "drag-item",
          ghostClass: "drag-ghost",
          handle: ".handle",

          // put: false,
          // sort: false,

          // fallbackOnBody: true,
          // swapThreshold: 0.65,
          onEnd: (event) => {
            const to = event.to.parentNode;
            const container_id = to.closest(".container").dataset.container;
            const { uuid } = getNodeData(event.item);
            const { parent_id, prev_id } = getNodeData(to);

            this.pushEventTo(this.el, "move_node_to_container", {
              container_id,
              uuid,
              parent_id,
              prev_id,
            });
          },
        });
      });
    },
    updated() {
      moveNodesToCorrectPosition.call(this);
    },
  },
  outline: {
    selector: ".node",
    mounted() {
      // const toolbarOptions = ["bold", "italic", "underline", "strike", "link"];
      // const options = {
      //   // debug: "info",
      //   modules: {
      //     toolbar: toolbarOptions,
      //   },
      //   placeholder: "Create an Node ...",
      //   theme: "snow",
      // };
      // this.quill = new Quill(".content", options);
      // this.quill.on("text-change", (delta, oldDelta, source) => {
      //   if (source == "api") {
      //     console.log("An API call triggered this change.");
      //   } else if (source == "user") {
      //     console.log(this);
      //     // This sends the event of
      //     // def handle_event("text-editor", %{"text_content" => content}, socket) do
      //     this.pushEventTo(this.el.phxHookId, "text-editor", {
      //       text_content: this.quill.getContents(),
      //     });
      //   }
      // });

      //this.handleEvent("blur", handleBlur.bind(this));
      //this.handleEvent("focus", handleFocus.bind(this));
      //this.handleEvent("focus_node", handleFocusNode.bind(this));
      this.handleEvent("move_nodes", handleMoveNodes.bind(this));
      this.handleEvent("set_content", handleSetContent.bind(this));

      this.el.addEventListener("click", click.bind(this));
      this.el.addEventListener("input", input.bind(this));
      this.el.addEventListener("keydown", keydown.bind(this));
      this.el.addEventListener("toggle_collapse", toggleCollapse.bind(this));

      moveNodesToCorrectPosition.call(this);
      restoreCollapsedStatus.call(this);

      const nestedSortables = [...this.el.querySelectorAll(".children")];
      nestedSortables.forEach((element) => {
        new Sortable(element, {
          group: this.el.dataset.group,
          animation: 150,
          // delay: 100,
          dragClass: "drag-item",
          ghostClass: "drag-ghost",
          handle: ".handle",
          fallbackOnBody: true,
          swapThreshold: 0.65,
          onEnd: ({ item }) => {
            const { uuid } = getNodeDataByNode(item);

            const parentNode = getParentNode(item);
            const prevNode = getPrevNode(item);

            const parent_id = parentNode && getNodeDataByNode(parentNode).uuid;
            const prev_id = prevNode && getNodeDataByNode(prevNode).uuid;

            this.pushEventTo(this.el, "move", { uuid, parent_id, prev_id });
          },
        });
      });
    },
    updated() {
      // delete this.quill;

      // this.sortable.destroy();

      moveNodesToCorrectPosition.call(this);
    },
  },
};
