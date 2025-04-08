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
import { getNodeData } from "./node";
import {
  moveNodesToCorrectPosition,
  restoreCollapsedStatus,
  initSortableInbox,
  initSortableOutline,
} from "./tree";

// import Quill from "../../vendor/quill";

export const Hooks = {
  inbox: {
    mounted() {
      this.handleEvent("select_all", () => {
        this.el.querySelectorAll(".node").forEach((node: Node) => {
          node.classList.toggle("selected");
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
