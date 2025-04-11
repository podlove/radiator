import { Node } from "./types";

import {
  handleBlur,
  handleFocus,
  handleFocusNode,
  handleMoveNodes,
  handleSetContent,
} from "./events/handler";
import { input, click, keydown, toggleCollapse } from "./events/listener";

import {
  moveNodesToCorrectPosition,
  restoreCollapsedStatus,
  initSortableInbox,
  initSortableOutline,
} from "./tree";
import { getNodeDataByNode } from "./node";

// import Quill from "../../vendor/quill";

export const Hooks = {
  toolbar: {
    mounted() {
      this.el.addEventListener("select_all", ({ detail }) => {
        const container = document.getElementById(detail.id);
        container!
          .querySelectorAll<HTMLDivElement>(".node .node")
          .forEach((node: Node) => {
            node.classList.toggle("selected");
          });
      });

      this.el.addEventListener("move_selected", ({ detail }) => {
        const container_id = detail.container_target;
        const target = document.getElementById("outline-2-stream");
        [
          ...document
            .getElementById(detail.id)!
            .querySelectorAll<HTMLDivElement>(".selected"),
        ]
          .reverse()
          .forEach((node: Node) => {
            const { uuid } = getNodeDataByNode(node);

            this.pushEventTo(target, "move_node_to_container", {
              container_id,
              uuid,
              parent_id: null,
              prev_id: null,
            });
          });
      });
    },
  },
  inbox: {
    mounted() {
      moveNodesToCorrectPosition.call(this);

      initSortableInbox.call(this);
    },
    updated() {
      moveNodesToCorrectPosition.call(this);
    },
  },
  outline: {
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

      initSortableOutline.call(this);
    },
    updated() {
      // delete this.quill;

      // this.sortable.destroy();

      moveNodesToCorrectPosition.call(this);
    },
  },
};
